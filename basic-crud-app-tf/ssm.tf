# DB connection details, published for Ansible to pull down on the instance
# at configuration time (see ansible/setup.yml). The password is a
# SecureString, encrypted with the default aws/ssm KMS key.
resource "aws_ssm_parameter" "db_host" {
  name  = "${local.ssm_prefix}/host"
  type  = "String"
  value = aws_db_instance.this.address

  tags = {
    Name = "${var.project_name}-db-host"
  }
}

resource "aws_ssm_parameter" "db_port" {
  name  = "${local.ssm_prefix}/port"
  type  = "String"
  value = tostring(aws_db_instance.this.port)
}

resource "aws_ssm_parameter" "db_name" {
  name  = "${local.ssm_prefix}/name"
  type  = "String"
  value = aws_db_instance.this.db_name
}

resource "aws_ssm_parameter" "db_username" {
  name  = "${local.ssm_prefix}/username"
  type  = "String"
  value = aws_db_instance.this.username
}

resource "aws_ssm_parameter" "db_password" {
  name  = "${local.ssm_prefix}/password"
  type  = "SecureString"
  value = random_password.db_master.result
}
