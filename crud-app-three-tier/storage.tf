# Stages the app files and Ansible roles so instances can pull them at boot
# (instead of baking an AMI).
module "artifacts_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.16"

  bucket = "${local.name}-artifacts-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  # Everything in it is managed by Terraform, so a demo teardown may empty it.
  force_destroy = true

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
}

module "artifact_files" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/object"
  version = "~> 5.16"

  for_each = local.artifact_files

  bucket      = module.artifacts_bucket.s3_bucket_id
  key         = each.key
  file_source = each.value
  source_hash = filemd5(each.value)
}
