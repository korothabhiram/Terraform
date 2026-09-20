# One-time stack that creates the S3 bucket holding the main stack's remote
# state. It uses LOCAL state (a bucket can't store its own creation), so keep
# bootstrap/terraform.tfstate around - it is gitignored.
terraform {
  required_version = ">= 1.11.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "aws_region" {
  description = "Region for the state bucket"
  type        = string
  default     = "us-east-1"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = "tfstate-ecs-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

module "state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.16"

  bucket = local.bucket_name

  # Never let a destroy wipe state history.
  force_destroy = false

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  attach_deny_insecure_transport_policy = true

  # Keep a month of old state versions, then expire them.
  lifecycle_rule = [
    {
      id      = "expire-old-state-versions"
      enabled = true
      filter  = {}
      noncurrent_version_expiration = {
        days = 30
      }
    }
  ]

  tags = {
    Project = "crud-app-ecs-three-tier"
    Purpose = "terraform-remote-state"
  }
}

output "state_bucket" {
  description = "Bucket name to use in the main stack's backend config"
  value       = module.state_bucket.s3_bucket_id
}
