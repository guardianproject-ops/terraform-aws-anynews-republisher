variable "ec2_disk_allocation_gb" {
  default     = null
  type        = number
  description = <<EOT
    The amount of storage to allocate for EC2 instance root disk. If left
    unset, 20 GB will be allocated.
  EOT
}

variable "ebs_volume_disk_allocation_gb" {
  default     = null
  type        = number
  description = <<EOT
    The amount of storage to allocate for the EBS volume mounted at /var/lib/republisher. If left unset, the amount allocated will depend on the stage
    of the deployment. If the stage variable is set to "prod", 100 GB will be allocated, otherwise only 40 GB will be
    allocated.
  EOT
}

variable "ec2_instance_type" {
  default     = null
  type        = string
  description = <<EOT
    The instance class for the EC2 instance. If left unset, the instance class will depend on the stage
    of the deployment. If the stage variable is set to "prod", t3.large will be use, otherwise only t3.medium.
  EOT
}

variable "create_bucket" {
  default     = true
  type        = bool
  description = <<EOT
Whether or not to create the bucket and cloudfront distribution to deploy the
republished feeds to. If false you must specify bucket_name. This module will generate a policy for the instance that gives it read write access.
EOT
}

variable "bucket_prefix" {
  default     = ""
  type        = string
  description = <<EOT
  Only takes effect when create_bucket is false. Will scope the instance to a prefix in the external bucket. Should end in a slash, but not start with a slash.
EOT
}

variable "bucket_name" {
  default     = ""
  type        = string
  description = <<EOT
  Only takes effect when create_bucket is false. Will use a previously created bucket.
EOT
}

variable "bucket_region" {
  default     = ""
  type        = string
  description = <<EOT
  Only takes effect when create_bucket is false. The region the external bucket is in.
EOT
}

variable "kms_key_arn" {
  default     = null
  type        = string
  description = <<EOT
    (optional) When `kms_key_arn_create_enabled` is `false`, this is the KMS Key ARN for this deployment.
  EOT
}

variable "kms_key_create_enabled" {
  default     = true
  type        = bool
  description = <<EOT
    (optional) When true a KMS key will be created for the deployment. If you set to false, then you must set `kms_key_arn` as well.
  EOT
}

variable "republisher_feeds_enabled" {
  default     = true
  type        = bool
  description = <<EOT
    (optional) When true the republisher_feeds_json_b64 variable will be active.
  EOT
}
variable "republisher_feeds_json_b64" {
  default     = null
  type        = string
  description = <<EOT
  (optional) When a Base64 JSON string is provided, it will be placed in the feeds bucket under the `feeds/feeds.json` key.
  EOT
}