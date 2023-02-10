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