locals {
  enabled                = module.this.enabled
  kms_key_create_enabled = local.enabled && var.kms_key_create_enabled
  availability_zones     = slice(data.aws_availability_zones.this.names, 0, 2)
  kms_key_arn            = local.kms_key_create_enabled ? module.kms_key[0].key_arn : var.kms_key_arn
  feeds_json_b64_enabled = local.enabled && var.republisher_feeds_json_b64 != null
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

data "aws_caller_identity" "this" {}
data "aws_availability_zones" "this" {
  state = "available"
}

module "vpc" {
  source                           = "cloudposse/vpc/aws"
  version                          = "2.0.0"
  count                            = local.enabled ? 1 : 0
  ipv4_primary_cidr_block          = "10.30.0.0/16"
  assign_generated_ipv6_cidr_block = false
  context                          = module.this.context
  attributes                       = ["vpc"]
}

module "dynamic_subnet" {
  source                         = "cloudposse/dynamic-subnets/aws"
  version                        = "2.1.0"
  count                          = local.enabled ? 1 : 0
  availability_zones             = [local.availability_zones[0]]
  vpc_id                         = module.vpc[0].vpc_id
  igw_id                         = [module.vpc[0].igw_id]
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
  source                  = "cloudposse/kms-key/aws"
  version                 = "0.12.1"
  count                   = local.kms_key_create_enabled ? 1 : 0
  description             = "general purpose KMS key for this deployment"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  alias                   = "alias/${module.this.id}"
  policy                  = data.aws_iam_policy_document.kms.json
  context                 = module.this.context
  attributes              = ["kms"]
}

module "lambda_edge" {
  source  = "cloudposse/cloudfront-s3-cdn/aws//modules/lambda@edge"
  version = "0.86.0"
  count   = local.enabled ? 1 : 0

  functions = {
    cors = {
      source = [{
        content  = <<-EOT
        exports.handler = (event, context, callback) => {
            const response = event.Records[0].cf.response;
            const request = event.Records[0].cf.request;
            response.headers["access-control-allow-origin"] = [{ key: "access-control-allow-origin", value: "*" }];

            if (!response.headers['vary']) {
                // source: https://serverfault.com/questions/856904/chrome-s3-cloudfront-no-access-control-allow-origin-header-on-initial-xhr-req
                response.headers['vary'] = [
                    { key: 'Vary', value: 'Access-Control-Request-Headers' },
                    { key: 'Vary', value: 'Access-Control-Request-Method' },
                    { key: 'Vary', value: 'Origin' },
                ];
            }

            callback(null, response);
        };
        EOT
        filename = "index.js"
      }]
      runtime      = "nodejs18.x"
      handler      = "index.handler"
      event_type   = "origin-response"
      include_body = false
    }
  }

  providers = {
    aws = aws.us-east-1
  }

  attributes = ["lambda", "cors"]
  context    = module.this.context
}

module "cdn" {
  source                              = "cloudposse/cloudfront-s3-cdn/aws"
  version                             = "0.86.0"
  count                               = local.enabled ? 1 : 0
  context                             = module.this.context
  cloudfront_access_logging_enabled   = true
  cloudfront_access_log_create_bucket = true
  deployment_principal_arns = {
    (module.instance_role_profile[0].iam_role_arn) = ["feeds/"]
  }
  lambda_function_association = module.lambda_edge[0].lambda_function_association
}

resource "aws_s3_object" "feeds_json_b64" {
  count          = local.feeds_json_b64_enabled ? 1 : 0
  bucket         = module.cdn[0].s3_bucket
  key            = "feeds/feeds.json"
  content_base64 = var.republisher_feeds_json_b64
  content_type   = "application/json"
  etag           = md5(var.republisher_feeds_json_b64)
  acl            = "private"
}
