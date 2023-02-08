locals {
  availability_zones = slice(data.aws_availability_zones.this.names, 0, 2)
}

data "aws_caller_identity" "this" {}
data "aws_availability_zones" "this" {
  state = "available"
}

module "vpc" {
  source                           = "cloudposse/vpc/aws"
  version                          = "2.0.0"
  ipv4_primary_cidr_block          = "10.30.0.0/16"
  assign_generated_ipv6_cidr_block = false
  context                          = module.this.context
  attributes                       = ["vpc"]
}

module "dynamic_subnet" {
  source                         = "cloudposse/dynamic-subnets/aws"
  version                        = "2.1.0"
  count                          = module.this.enabled ? 1 : 0
  availability_zones             = [local.availability_zones[0]]
  vpc_id                         = module.vpc.vpc_id
  igw_id                         = [module.vpc.igw_id]
  ipv4_cidr_block                = ["10.30.0.0/17"]
  ipv6_enabled                   = false
  metadata_http_endpoint_enabled = true
  metadata_http_tokens_required  = true
  context                        = module.this.context
  attributes                     = ["vpc"]
}

data "aws_iam_policy_document" "kms" {
  # this first statement is the default iam key policy
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }

    actions = [
      "kms:*",
    ]

    resources = [
      "*"
    ]
  }
}

module "kms_key" {
  source  = "cloudposse/kms-key/aws"
  version = "0.12.1"

  description             = "general purpose KMS key for this deployment"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  alias                   = "alias/${module.this.id}"
  policy                  = data.aws_iam_policy_document.kms.json
  context                 = module.this.context
  attributes              = ["kms"]
}
