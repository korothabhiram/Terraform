# Each tier only accepts traffic from the tier directly above it:
#   internet -> public-alb -> web -> internal-alb -> app -> db
# Security-group modules use create_before_destroy internally, so replacing one
# does not strand the instances that reference it.

locals {
  egress_all = {
    all = {
      description = "All outbound (package repos, S3, SSM, AWS APIs)"
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
  description = "Web/proxy tier: HTTP from the public ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    from_public_alb = {
      description                  = "HTTP from the public ALB"
      from_port                    = 80
      to_port                      = 80
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
      description                  = "HTTP from web tier (nginx)"
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
  description = "App tier: HTTP from the internal ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    from_internal_alb = {
      description                  = "HTTP from the internal ALB"
      from_port                    = 80
      to_port                      = 80
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
      description                  = "MySQL from app tier"
      from_port                    = 3306
      to_port                      = 3306
      referenced_security_group_id = module.app_sg.id
    }
  }
  # No egress rules: the database never initiates connections.
}
