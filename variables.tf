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

variable "s3_bucket_name" {
  default     = null
  type        = string
  description = <<EOT
    (optional) If you want to provide a bucket where the republisher should store the republished feeds,
    then you can pass a bucket name here. The republisher will receive a Read-Write policy to the bucket.
    The module will create a bucket if not passed.
  EOT
}

variable "kms_key_arn" {
  default     = null
  type        = string
  description = <<EOT
    (optional) The KMS Key ARN for this deployment. If not provided, a kms key will be created.
  EOT
}