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

output "db_endpoint" {
  description = "RDS endpoint (private; reachable from the app tier only)"
  value       = module.rds.db_instance_endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager secret holding the RDS master password"
  value       = module.rds.db_instance_master_user_secret_arn
}

output "artifacts_bucket" {
  value = module.artifacts_bucket.s3_bucket_id
}

output "web_asg_name" {
  value = module.asg_web.autoscaling_group_name
}

output "app_asg_name" {
  value = module.asg_app.autoscaling_group_name
}

output "nat_public_ip" {
  description = "Egress IP of the shared NAT gateway"
  value       = module.vpc.nat_public_ips
}
