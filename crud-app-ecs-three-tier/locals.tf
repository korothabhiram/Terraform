locals {
  name         = var.project_name
  cluster_name = var.project_name
  azs          = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # One /24 per AZ per tier.
  public_subnets   = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 1 + i)]
  web_subnets      = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 11 + i)]
  app_subnets      = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 21 + i)]
  database_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 31 + i)]

  # The vpc module has one private_subnets list; web comes first, app second.
  private_subnets = concat(local.web_subnets, local.app_subnets)
  web_subnet_ids  = slice(module.vpc.private_subnets, 0, var.az_count)
  app_subnet_ids  = slice(module.vpc.private_subnets, var.az_count, 2 * var.az_count)

  # Parameter Store prefix where DB host/port/name/user are published.
  ssm_prefix = "/${var.project_name}/db"

  # Docker's dynamic host-port range. Tasks use bridge networking with a dynamic
  # host port, and the ALB reaches them on whatever port ECS registered.
  dynamic_port_from = 32768
  dynamic_port_to   = 65535

  # The two container-instance fleets (one ECS capacity provider each).
  tiers = {
    web = {
      subnet_ids        = local.web_subnet_ids
      security_group_id = module.web_sg.id
      instance_type     = var.web_instance_type
      min_size          = var.web_node_min_size
      max_size          = var.web_node_max_size
    }
    app = {
      subnet_ids        = local.app_subnet_ids
      security_group_id = module.app_sg.id
      instance_type     = var.app_instance_type
      min_size          = var.app_node_min_size
      max_size          = var.app_node_max_size
    }
  }

  # Capacity provider names are unique per account and region, so prefix them.
  capacity_provider_names = { for k in keys(local.tiers) : k => "${local.name}-${k}" }

  # Capacity provider names read back from the cluster's capacity-provider
  # association. Using these in the services orders them after the association by
  # reference. (A module-level depends_on on module.ecs would also work, but it
  # defers everything inside the service modules whenever the cluster module has a
  # pending change, which re-registers the task definitions for no reason.)
  service_capacity_providers = {
    for k, name in local.capacity_provider_names :
    k => one([for n in module.ecs.cluster_capacity_providers[local.cluster_name].capacity_providers : n if n == name])
  }

  # Image reference by digest, e.g. 123.dkr.ecr.us-east-1.amazonaws.com/crud/app@sha256:...
  images = { for k, repo in module.ecr : k => "${repo.repository_url}@${data.aws_ecr_image.this[k].image_digest}" }
}
