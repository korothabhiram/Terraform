# Least-privilege instance policies. The autoscaling modules create the roles and
# instance profiles and attach these (plus SSM Session Manager access).
module "web_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 6.8"

  name        = "${local.name}-web"
  description = "Web tier: read the Ansible roles from the artifacts bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadAnsibleRoles"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["${module.artifacts_bucket.s3_bucket_arn}/ansible/*"]
      },
      {
        Sid      = "ListArtifactsBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [module.artifacts_bucket.s3_bucket_arn]
      },
    ]
  })
}

module "app_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 6.8"

  name        = "${local.name}-app"
  description = "App tier: read app files + roles, DB parameters and the one DB secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadAppAndRoles"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["${module.artifacts_bucket.s3_bucket_arn}/app/*", "${module.artifacts_bucket.s3_bucket_arn}/ansible/*"]
      },
      {
        Sid      = "ListArtifactsBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [module.artifacts_bucket.s3_bucket_arn]
      },
      {
        Sid      = "ReadDbParameters"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = ["arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/*"]
      },
      {
        Sid      = "ReadDbPasswordSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [module.rds.db_instance_master_user_secret_arn]
      },
    ]
  })
}
