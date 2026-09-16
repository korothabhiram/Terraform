locals {
  # Parameter Store path prefix where DB connection details are published so
  # Ansible can pull them at server-configuration time.
  ssm_prefix = "/${var.project_name}/db"
}
