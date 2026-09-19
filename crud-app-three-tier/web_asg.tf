# Web/proxy tier: nginx reverse-proxies to the internal ALB and serves static
# assets. Configured at boot by the `nginx_frontend` Ansible role.
module "asg_web" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 9.3"

  name            = "${local.name}-web"
  use_name_prefix = true

  min_size                  = var.web_min_size
  max_size                  = var.web_max_size
  desired_capacity          = var.web_desired_capacity
  vpc_zone_identifier       = local.web_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = var.health_check_grace_period
  wait_for_capacity_timeout = "15m"

  # Let target-tracking own the live capacity; do not fight it on every apply.
  ignore_desired_capacity_changes = true

  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.web_instance_type
  security_groups = [
    module.web_sg.id,
  ]

  user_data = base64encode(templatefile("${path.module}/templates/web-userdata.sh.tpl", {
    bucket_name   = module.artifacts_bucket.s3_bucket_id
    aws_region    = var.aws_region
    upstream_host = module.alb_internal.dns_name
    content_hash  = local.web_content_hash
  }))

  update_default_version = true

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-web"
  iam_role_description        = "Web tier instances"
  iam_role_policies = {
    ssm       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    artifacts = module.web_policy.arn
  }

  traffic_source_attachments = {
    public_alb = {
      traffic_source_identifier = module.alb_public.target_groups["web"].arn
      traffic_source_type       = "elbv2"
    }
  }

  # Roll the fleet (keeping >= 50% healthy) when the AMI, user_data or role changes.
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }

  scaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = var.cpu_target_percent
      }
    }
  }

  # References to subnet IDs do NOT wait for the NAT gateway/route: instances
  # need outbound internet for dnf/pip at first boot. nginx also needs the
  # internal ALB name to exist and the roles to be in S3.
  depends_on = [
    module.vpc,
    module.alb_internal,
    module.artifact_files,
  ]
}
