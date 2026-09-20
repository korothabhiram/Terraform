output "app_url" {
  description = "URL of the app"
  value       = var.enable_https ? "https://${var.app_domain_name}" : "http://${module.alb_public.dns_name}"
}

output "public_alb_dns_name" {
  description = "DNS name of the public ALB (works even without a custom domain)"
  value       = module.alb_public.dns_name
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal ALB nginx proxies to"
  value       = module.alb_internal.dns_name
}

output "ecr_repository_urls" {
  description = "ECR repository URL per tier (used by scripts/push-images.sh)"
  value       = { for k, repo in module.ecr : k => repo.repository_url }
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_names" {
  value = {
    web = module.svc_web.name
    app = module.svc_app.name
  }
}

output "db_endpoint" {
  description = "RDS endpoint (private; reachable from the app tier only)"
  value       = module.rds.db_instance_endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager secret holding the RDS master password"
  value       = module.rds.db_instance_master_user_secret_arn
}

output "nat_public_ip" {
  description = "Egress IP of the shared NAT gateway"
  value       = module.vpc.nat_public_ips
}
