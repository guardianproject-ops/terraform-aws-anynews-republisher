output "instance_id" {
  value = aws_instance.default[0].id
}

output "cdn" {
  value       = local.enabled ? module.cdn[0] : null
  description = "All the outputs from the upstream cloudposse/cloudfront-s3-cdn/aws module"
}

output "cf_domain_name" {
  value       = try(module.cdn[0].cf_domain_name, "")
  description = "Domain name corresponding to the distribution"
}

output "s3_bucket_name" {
  value       = local.enabled ? module.cdn[0].s3_bucket : null
  description = "Name of origin S3 bucket"
}