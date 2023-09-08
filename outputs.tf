output "instance_id" {
  value = aws_instance.default[0].id
}

output "cdn" {
  value       = local.create_bucket ? module.cdn[0] : null
  description = "All the outputs from the upstream cloudposse/cloudfront-s3-cdn/aws module"
}

output "cf_domain_name" {
  value       = local.create_bucket ? try(module.cdn[0].cf_domain_name, "") : null
  description = "Domain name corresponding to the distribution"
}

output "s3_bucket_name" {
  value       = local.create_bucket ? module.cdn[0].s3_bucket : var.bucket_name
  description = "Name of origin S3 bucket"
}

output "iam_role_arn" {
  value       = local.enabled ? module.instance_role_profile[0].iam_role_arn : null
  description = "The ARN for the role attached to the instance profile"
}

output "iam_role_name" {
  value       = local.enabled ? module.instance_role_profile[0].iam_role_name : null
  description = "The name of the role attached to the instance profile"
}

output "instance_profile_name" {
  value       = local.enabled ? module.instance_role_profile[0].instance_profile_name : null
  description = "The name for the IAM instance profile with the attached policies (bucket access and SSM)"
}
