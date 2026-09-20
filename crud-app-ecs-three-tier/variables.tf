variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name and tag all resources (also the ECS cluster name)"
  type        = string
  default     = "crud-ecs"
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
  default     = "ecs.abhidemosite.link"

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

# ---------------------------------------------------------------- images ----

variable "image_tag" {
  description = "ECR tag to deploy for both tiers. Resolved to a digest at plan time; scripts/push-images.sh pushes it (alongside a content-hash tag)"
  type        = string
  default     = "latest"
}

# ------------------------------------------------- container instances ----
# ECS on EC2: each tier has its own Auto Scaling group of container instances,
# registered to the cluster as a capacity provider. ECS managed scaling grows and
# shrinks these fleets to fit the tasks; the min/max below bound it.

variable "web_instance_type" {
  description = "Instance type of the web-tier container instances"
  type        = string
  default     = "t3.micro"
}

variable "web_node_min_size" {
  description = "Minimum web container instances (2 = one per AZ)"
  type        = number
  default     = 2
}

variable "web_node_max_size" {
  type    = number
  default = 4
}

variable "app_instance_type" {
  description = "Instance type of the app-tier container instances"
  type        = string
  default     = "t3.micro"
}

variable "app_node_min_size" {
  description = "Minimum app container instances (2 = one per AZ)"
  type        = number
  default     = 2
}

variable "app_node_max_size" {
  type    = number
  default = 4
}

# ----------------------------------------------------------------- tasks ----

variable "web_task_cpu" {
  description = "CPU units reserved per web (nginx) task (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "web_task_memory" {
  description = "Memory (MiB, hard limit) per web task"
  type        = number
  default     = 256
}

variable "web_desired_count" {
  type    = number
  default = 2
}

variable "web_min_count" {
  type    = number
  default = 2
}

variable "web_max_count" {
  type    = number
  default = 4
}

variable "app_task_cpu" {
  description = "CPU units reserved per app (Apache/PHP) task"
  type        = number
  default     = 256
}

variable "app_task_memory" {
  description = "Memory (MiB, hard limit) per app task. Keep it small enough that two fit on one container instance during a rolling deploy"
  type        = number
  default     = 384
}

variable "app_desired_count" {
  type    = number
  default = 2
}

variable "app_min_count" {
  type    = number
  default = 2
}

variable "app_max_count" {
  type    = number
  default = 4
}

variable "cpu_target_percent" {
  description = "Target average service CPU for both services' target-tracking scaling"
  type        = number
  default     = 60
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the task logs"
  type        = number
  default     = 7
}

variable "enable_container_insights" {
  description = "ECS Container Insights on the cluster (extra CloudWatch cost)"
  type        = bool
  default     = false
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
