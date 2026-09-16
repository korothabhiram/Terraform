# App server: only 80 is open to the world. No SSH ingress - SSM Session
# Manager (via the instance profile in iam.tf) is used for shell access.
#
# name_prefix + create_before_destroy: a plain `name` collides with itself
# on any change that forces replacement (e.g. editing `description`, which
# is immutable in the AWS API), because the old SG can't be deleted first -
# it's still attached to the running instance and referenced by the RDS
# SG's ingress rule. name_prefix lets the replacement SG get created (and
# dependents repointed to it) before the old one is torn down.
resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-ec2-sg-"
  description = "Allow HTTP to the app; no SSH ingress (use SSM)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from allowed CIDRs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr
  }

  egress {
    description = "All outbound (S3, SSM, package repos)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# RDS: only reachable from the app's security group on the MySQL port.
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-sg-"
  description = "Allow MySQL only from the app EC2 security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "MySQL from app servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
