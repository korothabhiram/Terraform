variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name and tag all resources"
  type        = string
  default     = "crud-app"
}

variable "instance_type" {
  description = "EC2 instance type for the app server"
  type        = string
  default     = "t3.micro"
}

variable "allowed_http_cidr" {
  description = "CIDR blocks allowed to reach the app on port 80"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_source_dir" {
  description = "Path to the CRUD app source files, relative to this module (a local copy of Docker/crud-app-demo's app files)"
  type        = string
  default     = "crud-app"
}

variable "app_files" {
  description = "App files uploaded to S3 and deployed to the server (Dockerfile/compose files are intentionally excluded - the app is deployed directly on the host, not via Docker)"
  type        = list(string)
  default = [
    "index.php",
    "create.php",
    "edit.php",
    "delete.php",
    "db.php",
    "schema.sql",
  ]
}

variable "db_engine_version" {
  description = "MySQL engine version for RDS"
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GiB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Application database name"
  type        = string
  default     = "php_crud_demo"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "crud_user"
}
