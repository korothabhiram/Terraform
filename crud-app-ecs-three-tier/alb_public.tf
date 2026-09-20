# Internet-facing ALB. With enable_https: :443 terminates TLS with the ACM cert
# and :80 redirects to it. Without: plain :80 forward to the web tier.
locals {
  public_listeners = {
    for k, v in {
      http = {
        port     = 80
        protocol = "HTTP"
        redirect = var.enable_https ? {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        } : null
        forward = var.enable_https ? null : {
          target_group_key = "web"
        }
      }
      https = {
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
        certificate_arn = one(module.acm[*].acm_certificate_arn)
        forward = {
          target_group_key = "web"
        }
      }
    } : k => v if k == "http" || var.enable_https
  }
}

module "alb_public" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.5"

  name    = "${local.name}-public"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  load_balancer_type = "application"
  internal           = false

  create_security_group = false
  security_groups       = [module.public_alb_sg.id]

  # Demo stack: must be destroyable.
  enable_deletion_protection = false

  listeners = local.public_listeners

  target_groups = {
    web = {
      name_prefix          = "web-"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 30

      # The ECS service registers its own tasks (instance:dynamic-port).
      create_attachment = false

      # nginx answers /healthz itself, so web tasks do not flap when the
      # backend is unhealthy.
      health_check = {
        path                = "/healthz"
        matcher             = "200"
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
    }
  }

  # The HTTPS listener needs a *validated* certificate before it can exist.
  depends_on = [module.acm]
}
