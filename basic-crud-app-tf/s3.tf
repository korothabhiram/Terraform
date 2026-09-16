# Bucket used to stage the app source files and the Ansible playbook so the
# EC2 instance can pull them down from userdata (instead of baking an AMI).
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app" {
  bucket = "${var.project_name}-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket                  = aws_s3_bucket.app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "app_files" {
  for_each = toset(var.app_files)

  bucket = aws_s3_bucket.app.id
  key    = "app/${each.value}"
  source = "${path.module}/${var.app_source_dir}/${each.value}"
  etag   = filemd5("${path.module}/${var.app_source_dir}/${each.value}")
}

resource "aws_s3_object" "ansible_playbook" {
  bucket = aws_s3_bucket.app.id
  key    = "ansible/setup.yml"
  source = "${path.module}/ansible/setup.yml"
  etag   = filemd5("${path.module}/ansible/setup.yml")
}
