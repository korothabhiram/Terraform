# Backend tier: Apache + PHP (the CRUD app). Configured at boot by the
# `php_backend` Ansible role, which imports the schema into RDS.
module "asg_app" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 9.3"

  name            = "${local.name}-app"
  use_name_prefix = true

  min_size                  = var.app_min_size
  max_size                  = var.app_max_size
  desired_capacity          = var.app_desired_capacity
  vpc_zone_identifier       = local.app_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = var.health_check_grace_period
  wait_for_capacity_timeout = "15m"

  ignore_desired_capacity_changes = true

  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.app_instance_type
  security_groups = [
    module.app_sg.id,
  ]

  user_data = base64encode(templatefile("${path.module}/templates/app-userdata.sh.tpl", {
    bucket_name   = module.artifacts_bucket.s3_bucket_id
    aws_region    = var.aws_region
    ssm_prefix    = local.ssm_prefix
    db_secret_arn = module.rds.db_instance_master_user_secret_arn
    content_hash  = local.app_content_hash
  }))

  update_default_version = true

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-app"
  iam_role_description        = "App tier instances"
  iam_role_policies = {
    ssm      = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    app_read = module.app_policy.arn
  }

  traffic_source_attachments = {
    internal_alb = {
      traffic_source_identifier = module.alb_internal.target_groups["app"].arn
      traffic_source_type       = "elbv2"
    }
  }

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

  # Instances run Ansible at first boot, so before any launch we need:
  #  - the NAT gateway + routes (subnet-ID references don't wait for them),
  #  - the database available (rds only returns once it is),
  #  - the connection details written to Parameter Store,
  #  - the app files and roles uploaded to S3.
  depends_on = [
    module.vpc,
    module.rds,
    module.db_params,
    module.artifact_files,
  ]
}
