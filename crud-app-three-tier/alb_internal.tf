# Internal ALB between nginx and the app fleet: stable DNS name, health checks,
# and it follows instances as the app ASG scales. Not reachable from the internet.
module "alb_internal" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.5"

  name    = "${local.name}-internal"
  vpc_id  = module.vpc.vpc_id
  subnets = local.app_subnet_ids

  load_balancer_type = "application"
  internal           = true

  create_security_group = false
  security_groups       = [module.internal_alb_sg.id]

  enable_deletion_protection = false

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "app"
      }
    }
  }

  target_groups = {
    app = {
      name_prefix          = "app-"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 30
      create_attachment    = false

      # Deep check: index.php only returns 200 if Apache, PHP and the DB
      # connection all work.
      health_check = {
        path                = "/index.php"
        matcher             = "200"
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
    }
  }
}
