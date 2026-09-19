# The domain itself is registered outside Terraform and only READ here (see
# data.tf). This stack manages just two things inside its hosted zone: the ACM
# validation record and the `app` alias record. Nothing here can remove the
# domain, the zone, or the apex/www records used by the GitHub Pages blog.

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.3"

  count = var.enable_https ? 1 : 0

  domain_name       = var.app_domain_name
  zone_id           = data.aws_route53_zone.this[0].zone_id
  validation_method = "DNS"

  # The cert output only resolves once validation has completed.
  wait_for_validation = true
}

module "dns_records" {
  source  = "terraform-aws-modules/route53/aws"
  version = "~> 6.5"

  count = var.enable_https ? 1 : 0

  # create_zone = false makes the module look the existing zone up by name.
  create_zone = false
  name        = var.route53_zone_name

  records = {
    app = {
      full_name = var.app_domain_name
      type      = "A"
      alias = {
        name                   = module.alb_public.dns_name
        zone_id                = module.alb_public.zone_id
        evaluate_target_health = true
      }
    }
  }

  depends_on = [module.alb_public]
}
