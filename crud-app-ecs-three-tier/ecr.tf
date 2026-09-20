# One private repository per tier. `terraform apply -target=module.ecr` creates
# them first; scripts/push-images.sh then builds and pushes the images, and the
# full apply deploys them (see README).
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 3.2"

  for_each = toset(["web", "app"])

  repository_name = "${local.name}/${each.key}"

  # The scripts push a content-hash tag and move `latest`, so tags are mutable.
  # Tasks run the digest, so the moving tag never changes what is running.
  repository_image_tag_mutability = "MUTABLE"
  repository_image_scan_on_push   = true

  # Demo stack: must be destroyable even with images in it.
  repository_force_delete = true

  repository_lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the 10 most recent images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
