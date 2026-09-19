# Post-apply smoke test. A failing check only warns (it never blocks or fails an
# apply), and it is skipped until the URL is known.
check "app_responds" {
  data "http" "app" {
    url = var.enable_https ? "https://${var.app_domain_name}/index.php" : "http://${module.alb_public.dns_name}/index.php"

    retry {
      attempts     = 2
      min_delay_ms = 3000
    }
  }

  assert {
    condition     = data.http.app.status_code == 200
    error_message = "The app did not return HTTP 200 at ${data.http.app.url} (instances may still be running Ansible - re-run `terraform plan` in a few minutes)."
  }
}
