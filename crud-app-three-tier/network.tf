module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name = local.name
  cidr = var.vpc_cidr
  azs  = local.azs

  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  private_subnet_names = concat(
    [for i in range(var.az_count) : "${local.name}-web-${local.azs[i]}"],
    [for i in range(var.az_count) : "${local.name}-app-${local.azs[i]}"],
  )

  # Database subnets get no route to the internet at all.
  create_database_subnet_group = true
  database_subnet_group_name   = "${local.name}-db"

  # One shared NAT gateway (cheap; one per AZ is the HA option).
  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}
