# ECS on EC2. Two fleets of container instances (web and app), each in its own
# private subnets and security group, each an Auto Scaling group registered to the
# cluster as a capacity provider. ECS managed scaling adds and removes instances
# to fit the tasks placed on that provider.

module "ecs_nodes" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 9.3"

  for_each = local.tiers

  name            = "${local.name}-${each.key}-nodes"
  use_name_prefix = true

  min_size            = each.value.min_size
  max_size            = each.value.max_size
  desired_capacity    = each.value.min_size
  vpc_zone_identifier = each.value.subnet_ids

  # ECS owns the fleet size from here on (managed scaling changes desired).
  ignore_desired_capacity_changes = true

  # ECS managed termination protection: scale-in only picks instances that are
  # not running tasks. force_delete lets `terraform destroy` still remove the
  # group (protected instances would otherwise block it).
  protect_from_scale_in = true
  force_delete          = true
  autoscaling_group_tags = {
    AmazonECSManaged = "true"
  }

  health_check_type = "EC2"

  image_id        = data.aws_ssm_parameter.ecs_ami.value
  instance_type   = each.value.instance_type
  security_groups = [each.value.security_group_id]

  user_data = base64encode(templatefile("${path.module}/templates/ecs-userdata.sh.tpl", {
    cluster_name = local.cluster_name
    tier         = each.key
  }))

  update_default_version = true

  # IMDSv2 only, and hop limit 1 so containers (an extra network hop away)
  # cannot reach the instance's credentials.
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings = [{
    device_name = "/dev/xvda"
    ebs = {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }]

  create_iam_instance_profile = true
  iam_role_name               = "${local.name}-${each.key}-nodes"
  iam_role_description        = "ECS container instances (${each.key} tier)"
  iam_role_policies = {
    ecs = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # Instances need the NAT route before they can reach the ECS control plane and
  # ECR (subnet-ID references alone do not wait for it).
  depends_on = [module.vpc]
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 7.6"

  cluster_name = local.cluster_name

  cluster_setting = [{
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }]

  capacity_providers = {
    for k in keys(local.tiers) : local.capacity_provider_names[k] => {
      auto_scaling_group_provider = {
        auto_scaling_group_arn = module.ecs_nodes[k].autoscaling_group_arn
        managed_draining       = "ENABLED"
        # Never terminate an instance that is running tasks.
        managed_termination_protection = "ENABLED"
        managed_scaling = {
          status                    = "ENABLED"
          target_capacity           = 100
          minimum_scaling_step_size = 1
          maximum_scaling_step_size = 2
          instance_warmup_period    = 120
        }
      }
    }
  }

  # Task execution roles are created per service (ecs_services.tf).
  create_task_exec_iam_role = false
  create_security_group     = false
}
