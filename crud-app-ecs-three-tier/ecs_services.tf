# The two ECS services. Bridge networking with a dynamic host port: each ALB
# target group registers instance:port, so several tasks of a service can share
# one container instance (awsvpc would need an ENI per task, and a t3.micro only
# has two).
#
# Images come from ECR by digest (data.tf). The database password is injected by
# ECS from the RDS-managed Secrets Manager secret; it never appears in Terraform
# state, the task definition or the image.

module "svc_app" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 7.6"

  name        = "${local.name}-app"
  cluster_arn = module.ecs.cluster_arn

  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = var.app_task_cpu
  memory                   = var.app_task_memory

  capacity_provider_strategy = {
    app = {
      capacity_provider = local.service_capacity_providers["app"]
      weight            = 1
    }
  }

  desired_count = var.app_desired_count

  # Rolling deploy: never drop below the desired count, allow one extra task
  # per task while new ones warm up; roll back automatically if they never
  # become healthy.
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }
  wait_for_steady_state             = true
  health_check_grace_period_seconds = 90

  # Spread across AZs first, then across instances.
  ordered_placement_strategy = [
    { type = "spread", field = "attribute:ecs.availability-zone" },
    { type = "spread", field = "instanceId" },
  ]

  load_balancer = {
    service = {
      target_group_arn = module.alb_internal.target_groups["app"].arn
      container_name   = "app"
      container_port   = 80
    }
  }

  container_definitions = {
    app = {
      image     = local.images["app"]
      essential = true

      portMappings = [{
        name          = "http"
        containerPort = 80
        hostPort      = 0 # dynamic
        protocol      = "tcp"
      }]

      # Apache and PHP write to the container filesystem (pid file, logs).
      readonlyRootFilesystem = false
      stopTimeout            = 30

      environment = [
        # Not a credential; RDS does not run schema.sql for us, so the
        # entrypoint applies it.
        { name = "DB_INIT_SCHEMA", value = "true" },
      ]

      # Injected by ECS when the task starts, using the execution role:
      #  - connection details from Parameter Store (the ARN is the whole value)
      #  - the password from the RDS-managed Secrets Manager secret
      #    (`:password::` selects the "password" key of its JSON)
      secrets = [
        { name = "DB_HOST", valueFrom = module.db_params["host"].ssm_parameter_arn },
        { name = "DB_PORT", valueFrom = module.db_params["port"].ssm_parameter_arn },
        { name = "DB_NAME", valueFrom = module.db_params["name"].ssm_parameter_arn },
        { name = "DB_USER", valueFrom = module.db_params["username"].ssm_parameter_arn },
        { name = "DB_PASS", valueFrom = "${module.rds.db_instance_master_user_secret_arn}:password::" },
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "php -r 'exit(@fsockopen(\"127.0.0.1\", 80) ? 0 : 1);'"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60 # schema import on first start
      }

      cloudwatch_log_group_name              = "/ecs/${local.name}/app"
      cloudwatch_log_group_retention_in_days = var.log_retention_days
    }
  }

  # The execution role pulls the image and reads the DB secret; the containers
  # themselves call no AWS APIs, so they get no task role.
  task_exec_ssm_param_arns = [for p in module.db_params : p.ssm_parameter_arn]
  task_exec_secret_arns    = [module.rds.db_instance_master_user_secret_arn]
  create_tasks_iam_role    = false

  # The ECS service-linked role is enough for a bridge-mode service.
  create_iam_role       = false
  create_security_group = false

  enable_autoscaling       = true
  autoscaling_min_capacity = var.app_min_count
  autoscaling_max_capacity = var.app_max_count
  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value = var.cpu_target_percent
      }
    }
  }

  # The capacity provider association is ordered by reference (locals.tf). The
  # internal ALB needs its listener before a service can register targets, and a
  # target group reference does not wait for that. This only matters on create;
  # RDS is already ordered first through the parameter / secret references above.
  depends_on = [module.alb_internal]
}

module "svc_web" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 7.6"

  name        = "${local.name}-web"
  cluster_arn = module.ecs.cluster_arn

  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = var.web_task_cpu
  memory                   = var.web_task_memory

  capacity_provider_strategy = {
    web = {
      capacity_provider = local.service_capacity_providers["web"]
      weight            = 1
    }
  }

  desired_count = var.web_desired_count

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }
  wait_for_steady_state             = true
  health_check_grace_period_seconds = 30

  ordered_placement_strategy = [
    { type = "spread", field = "attribute:ecs.availability-zone" },
    { type = "spread", field = "instanceId" },
  ]

  load_balancer = {
    service = {
      target_group_arn = module.alb_public.target_groups["web"].arn
      container_name   = "web"
      container_port   = 80
    }
  }

  container_definitions = {
    web = {
      image     = local.images["web"]
      essential = true

      portMappings = [{
        name          = "http"
        containerPort = 80
        hostPort      = 0 # dynamic
        protocol      = "tcp"
      }]

      # nginx writes its cache, pid file and rendered config at start-up.
      readonlyRootFilesystem = false
      stopTimeout            = 30

      environment = [
        # The image's entrypoint renders this into the nginx proxy_pass.
        { name = "UPSTREAM_HOST", value = module.alb_internal.dns_name },
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "wget -q -O /dev/null http://127.0.0.1/healthz || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      cloudwatch_log_group_name              = "/ecs/${local.name}/web"
      cloudwatch_log_group_retention_in_days = var.log_retention_days
    }
  }

  create_tasks_iam_role = false
  create_iam_role       = false
  create_security_group = false

  enable_autoscaling       = true
  autoscaling_min_capacity = var.web_min_count
  autoscaling_max_capacity = var.web_max_count
  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value = var.cpu_target_percent
      }
    }
  }

  # The public ALB's listeners must exist before the service can register
  # targets. nginx re-resolves the internal ALB at request time, so it does not
  # need to wait for the app service.
  depends_on = [module.alb_public]
}
