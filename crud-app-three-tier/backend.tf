# Remote state in S3 with native locking (use_lockfile) - no DynamoDB table.
# The bucket is created by ./bootstrap and passed in at init time:
#   terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {
    key          = "crud-app-three-tier/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
