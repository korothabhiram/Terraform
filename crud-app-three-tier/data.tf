data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Latest Amazon Linux 2023 (ships with the SSM agent and AWS CLI v2). A new AMI
# changes the launch template, which triggers an ASG instance refresh.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# The registered domain's hosted zone already exists (created by Route 53
# registration). It is only READ here, so `terraform destroy` can never remove
# the domain, the zone, or the GitHub Pages records that live in it.
data "aws_route53_zone" "this" {
  count = var.enable_https ? 1 : 0

  name         = var.route53_zone_name
  private_zone = false
}
