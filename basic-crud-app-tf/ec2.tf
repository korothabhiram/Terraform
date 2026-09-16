resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/userdata.sh.tpl", {
    bucket_name = aws_s3_bucket.app.bucket
    aws_region  = var.aws_region
    ssm_prefix  = local.ssm_prefix
  })

  # RDS must exist (and the DB details must already be in Parameter Store)
  # before this instance boots and Ansible tries to read them - otherwise
  # the app could fail on first load.
  depends_on = [
    aws_db_instance.this,
    aws_ssm_parameter.db_host,
    aws_ssm_parameter.db_port,
    aws_ssm_parameter.db_name,
    aws_ssm_parameter.db_username,
    aws_ssm_parameter.db_password,
    aws_s3_object.app_files,
    aws_s3_object.ansible_playbook,
  ]

  tags = {
    Name = "${var.project_name}-app"
  }
}
