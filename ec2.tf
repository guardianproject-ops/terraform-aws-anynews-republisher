locals {
  ec2_instance_type             = coalesce(var.ec2_instance_type, (module.this.stage == "prod") ? "t3.large" : "t3.medium")
  ec2_disk_allocation_gb        = tostring(coalesce(var.ebs_volume_disk_allocation_gb, 20))
  ebs_volume_disk_allocation_gb = tostring(coalesce(var.ec2_disk_allocation_gb, (module.this.stage == "prod") ? 100 : 40))
}

resource "tls_private_key" "default" {
  count = module.this.enabled ? 1 : 0

  algorithm = "RSA"
}

resource "aws_key_pair" "default" {
  count = module.this.enabled ? 1 : 0

  key_name   = module.this.id
  public_key = tls_private_key.default[0].public_key_openssh
}

data "aws_ami" "default" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-11-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "instance_role_profile" {
  source  = "sr2c/ec2-conf-log/aws"
  version = "0.0.4"

  count = module.this.enabled ? 1 : 0

  disable_logs_bucket = true

  context = module.this.context
}

data "aws_iam_policy_document" "external_bucket_policy" {
  statement {
    sid = "AllowListBucket"
    actions = [
      "s3:List*",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}"
    ]
  }
  statement {
    sid = "RWInPrefix"
    actions = [
      "s3:List*",
      "s3:Put*",
      "s3:Get*",
      "s3:Delete*"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}/${var.bucket_prefix}*"
    ]
  }
}

resource "aws_iam_policy" "external_bucket_policy" {
  count       = local.create_bucket ? 0 : 1
  name        = "${module.this.id}-external-bucket"
  description = "Policy that allows the holder to access the bucket ${var.bucket_name}"
  policy      = data.aws_iam_policy_document.external_bucket_policy.json
}

resource "aws_iam_role_policy_attachment" "external_bucket" {
  count      = local.create_bucket ? 0 : 1
  role       = module.instance_role_profile[0].iam_role_name
  policy_arn = aws_iam_policy.external_bucket_policy[0].arn
}

data "cloudinit_config" "this" {
  gzip = true

  part {
    content_type = "text/x-shellscript"
    content      = <<EOT
#!/bin/sh
echo "dash dash/sh boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
DEBIAN_FRONTEND=noninteractive apt install -y wget curl
cd /opt
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb
EOT
  }
}

resource "aws_instance" "default" {
  count = module.this.enabled ? 1 : 0

  ami                     = data.aws_ami.default.id
  instance_type           = local.ec2_instance_type
  subnet_id               = module.dynamic_subnet[0].private_subnet_ids[0]
  key_name                = aws_key_pair.default[0].key_name
  monitoring              = true
  availability_zone       = local.availability_zones[0]
  iam_instance_profile    = module.instance_role_profile[0].instance_profile_name
  disable_api_termination = (module.this.stage == "prod")
  vpc_security_group_ids  = [module.ec2_security_group[0].id]
  user_data_base64        = data.cloudinit_config.this.rendered

  root_block_device {
    volume_type = "gp2"
    volume_size = local.ec2_disk_allocation_gb
    encrypted   = true
    kms_key_id  = local.kms_key_arn
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
    # add an extra hop to allow the container to access the metadata instance
    http_put_response_hop_limit = 2
  }

  # this prevents changes to the ami from recreating the whole instance
  lifecycle {
    ignore_changes = [ami]
  }

  tags = module.this.tags
}

module "ec2_security_group" {
  source  = "cloudposse/security-group/aws"
  version = "2.0.0"

  count = module.this.enabled ? 1 : 0

  vpc_id = module.vpc[0].vpc_id
  rules = [
    {
      # node_exporter
      type        = "ingress",
      from_port   = "9100",
      to_port     = "9100",
      protocol    = "tcp",
      cidr_blocks = module.dynamic_subnet[0].private_subnet_cidrs
    }
  ]

  context = module.this.context
}

resource "aws_ebs_volume" "data" {
  count = module.this.enabled ? 1 : 0

  availability_zone = local.availability_zones[0]
  size              = local.ebs_volume_disk_allocation_gb
  encrypted         = true
  kms_key_id        = local.kms_key_arn
  tags              = module.this.tags
}

resource "aws_volume_attachment" "default" {
  count = module.this.enabled ? 1 : 0

  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.data[0].id
  instance_id = aws_instance.default[0].id
}
