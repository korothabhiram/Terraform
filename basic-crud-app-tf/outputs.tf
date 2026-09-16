output "app_public_ip" {
  description = "Public IP of the app EC2 instance"
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "URL for the app"
  value       = "http://${aws_instance.app.public_ip}/index.php"
}

output "db_endpoint" {
  description = "RDS endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_parameter_store_prefix" {
  description = "Parameter Store path where DB host/port/name/username/password are published for Ansible"
  value       = local.ssm_prefix
}

output "s3_bucket" {
  description = "Bucket holding the app files and Ansible playbook"
  value       = aws_s3_bucket.app.bucket
}
