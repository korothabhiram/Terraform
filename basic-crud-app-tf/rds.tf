resource "random_password" "db_master" {
  length           = 20
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-db"
  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_master.result
  port     = 3306

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false

  # Demo/simple-setup tradeoffs - revisit before using this for anything real.
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.project_name}-db"
  }
}
