data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Latest Amazon Linux 2023 ECS-optimized AMI (Docker + ECS agent preinstalled,
# plus the SSM agent). A new AMI changes the launch template, so it is picked up
# by instances launched from then on.
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# The registered domain's hosted zone already exists (created by Route 53
# registration). It is only READ here, so `terraform destroy` can never remove
# the domain, the zone, or the GitHub Pages records that live in it.
data "aws_route53_zone" "this" {
  count = var.enable_https ? 1 : 0

  name         = var.route53_zone_name
  private_zone = false
}

# The image each tier runs, resolved to a digest. Because tasks reference the
# digest, pushing a new image and re-running `terraform apply` creates a new task
# definition revision and rolls the service - even though the tag is reused.
#
# This also fails the plan (by design) until scripts/push-images.sh has pushed
# the images, which is what enforces the two-step first deploy (see README).
data "aws_ecr_image" "this" {
  for_each = module.ecr

  repository_name = each.value.repository_name
  image_tag       = var.image_tag
}
