locals {
  name = var.project_name
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # One /24 per AZ per tier.
  public_subnets   = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 1 + i)]
  web_subnets      = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 11 + i)]
  app_subnets      = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 21 + i)]
  database_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 31 + i)]

  # The vpc module has one private_subnets list; web comes first, app second.
  private_subnets = concat(local.web_subnets, local.app_subnets)
  web_subnet_ids  = slice(module.vpc.private_subnets, 0, var.az_count)
  app_subnet_ids  = slice(module.vpc.private_subnets, var.az_count, 2 * var.az_count)

  # Parameter Store prefix where DB host/port/name/user are published for Ansible.
  ssm_prefix = "/${var.project_name}/db"

  # Everything the instances pull from S3: key in bucket => local source file.
  artifact_files = merge(
    { for f in fileset("${path.module}/crud-app", "**") : "app/${f}" => "${path.module}/crud-app/${f}" },
    { for f in fileset("${path.module}/ansible", "**") : "ansible/${f}" => "${path.module}/ansible/${f}" },
  )

  # Baked into user_data so any app/playbook change alters the launch template
  # and rolls the fleet via instance refresh.
  web_content_hash = sha256(join("", [
    for k, p in local.artifact_files : filesha256(p)
    if k == "ansible/web.yml" || startswith(k, "ansible/roles/nginx_frontend/")
  ]))
  app_content_hash = sha256(join("", [for k, p in local.artifact_files : filesha256(p)]))
}
