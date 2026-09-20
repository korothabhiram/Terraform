# Each tier only accepts traffic from the tier directly above it:
#   internet -> public-alb -> web -> internal-alb -> app -> db
#
# "web" and "app" are the security groups of the ECS *container instances* of that
# tier. Tasks use bridge networking, so an ALB reaches a task on the dynamic host
# port ECS assigned to it (Docker's ephemeral range) on the instance.
# Security-group modules use create_before_destroy internally, so replacing one
# does not strand the instances that reference it.

locals {
  egress_all = {
    all = {
      description = "All outbound (ECR, CloudWatch, Secrets Manager, ECS control plane)"
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "-1"
    }
  }
}

module "public_alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name        = "${local.name}-public-alb"
  description = "Public ALB: HTTP/HTTPS from the internet"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = merge(
    { for i, cidr in var.allowed_ingress_cidrs : "http-${i}" => {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      cidr_ipv4   = cidr
    } },
    { for i, cidr in var.allowed_ingress_cidrs : "https-${i}" => {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      cidr_ipv4   = cidr
    } },
  )
  egress_rules = local.egress_all
}

module "web_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name        = "${local.name}-web"
  description = "Web-tier ECS container instances: task ports from the public ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    from_public_alb = {
      description                  = "Dynamic task ports from the public ALB"
      from_port                    = local.dynamic_port_from
      to_port                      = local.dynamic_port_to
      referenced_security_group_id = module.public_alb_sg.id
    }
  }
  egress_rules = local.egress_all
}

module "internal_alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name        = "${local.name}-internal-alb"
  description = "Internal ALB: HTTP from the web tier only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    from_web = {
      description                  = "HTTP from the web tier (nginx)"
      from_port                    = 80
      to_port                      = 80
      referenced_security_group_id = module.web_sg.id
    }
  }
  egress_rules = local.egress_all
}

module "app_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name        = "${local.name}-app"
  description = "App-tier ECS container instances: task ports from the internal ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    from_internal_alb = {
      description                  = "Dynamic task ports from the internal ALB"
      from_port                    = local.dynamic_port_from
      to_port                      = local.dynamic_port_to
      referenced_security_group_id = module.internal_alb_sg.id
    }
  }
  egress_rules = local.egress_all
}

module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 6.0"

  name        = "${local.name}-db"
  description = "Database tier: MySQL from the app tier only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    from_app = {
      description                  = "MySQL from the app tier"
      from_port                    = 3306
      to_port                      = 3306
      referenced_security_group_id = module.app_sg.id
    }
  }
  # No egress rules: the database never initiates connections.
}
