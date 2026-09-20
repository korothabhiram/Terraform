module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.2"

  identifier = "${local.name}-db"

  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  port     = 3306

  # RDS generates the master password and keeps it in Secrets Manager, so it
  # never appears in Terraform state, variables or logs.
  manage_master_user_password = true

  create_db_subnet_group = false
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.db_sg.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  create_db_parameter_group = false
  create_db_option_group    = false

  backup_retention_period = 1
  apply_immediately       = true

  # Demo-friendly defaults, flip via variables for anything real.
  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = var.db_skip_final_snapshot
}

# Connection details (not the password), same layout as crud-app-three-tier. ECS
# reads them when a task starts and injects them as the DB_* environment
# variables (see ecs_services.tf).
module "db_params" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "~> 2.1"

  for_each = {
    host     = module.rds.db_instance_address
    port     = tostring(module.rds.db_instance_port)
    name     = module.rds.db_instance_name
    username = module.rds.db_instance_username
  }

  name  = "${local.ssm_prefix}/${each.key}"
  value = each.value
  type  = "String"
}
