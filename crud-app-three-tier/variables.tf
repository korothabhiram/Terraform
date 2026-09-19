variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name and tag all resources"
  type        = string
  default     = "crud-3tier"
}

# ---------------------------------------------------------------- domain ----

variable "enable_https" {
  description = "Issue an ACM cert for app_domain_name, serve HTTPS on the public ALB (HTTP redirects) and create the DNS record. false = HTTP-only on the ALB's own DNS name"
  type        = bool
  default     = true
}

variable "route53_zone_name" {
  description = "Existing Route 53 hosted zone (the registered domain). Looked up only - never created or destroyed by this stack"
  type        = string
  default     = "abhidemosite.link"
}

variable "app_domain_name" {
  description = "Demo URL for the app; must sit inside route53_zone_name"
  type        = string
  default     = "app.abhidemosite.link"

  validation {
    condition     = endswith(var.app_domain_name, var.route53_zone_name)
    error_message = "app_domain_name must be the zone name or a subdomain of route53_zone_name."
  }
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the public ALB on 80/443"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# --------------------------------------------------------------- network ----

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones (each tier gets one subnet per AZ)"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "Both ALBs and the RDS subnet group need at least 2 AZs."
  }
}

# --------------------------------------------------------------- compute ----

variable "web_instance_type" {
  description = "Instance type for the web/proxy (nginx) ASG"
  type        = string
  default     = "t3.micro"
}

variable "web_min_size" {
  type    = number
  default = 2
}

variable "web_desired_capacity" {
  type    = number
  default = 2
}

variable "web_max_size" {
  type    = number
  default = 4
}

variable "app_instance_type" {
  description = "Instance type for the backend (Apache/PHP) ASG"
  type        = string
  default     = "t3.micro"
}

variable "app_min_size" {
  type    = number
  default = 2
}

variable "app_desired_capacity" {
  type    = number
  default = 2
}

variable "app_max_size" {
  type    = number
  default = 4
}

variable "cpu_target_percent" {
  description = "Target average CPU for both ASGs' target-tracking scaling"
  type        = number
  default     = 60
}

variable "health_check_grace_period" {
  description = "Seconds the ASGs ignore ELB health while Ansible configures a fresh instance"
  type        = number
  default     = 300
}

# -------------------------------------------------------------- database ----

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GiB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Application database name (schema.sql creates/uses php_crud_demo)"
  type        = string
  default     = "php_crud_demo"
}

variable "db_username" {
  description = "Master username; the password is generated and held by RDS in Secrets Manager"
  type        = string
  default     = "crud_user"
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_deletion_protection" {
  description = "Off by default because this stack is a temporary demo"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "On by default because this stack is a temporary demo"
  type        = bool
  default     = true
}
