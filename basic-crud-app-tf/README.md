# basic-crud-app-tf

Terraform + Ansible setup that deploys the PHP CRUD app (a local copy of the
app files from [`Docker/crud-app-demo`](../../Docker/crud-app-demo), kept in
[`crud-app/`](./crud-app)) onto AWS - **without** Docker. Apache/PHP is
installed directly on the EC2 host by Ansible; the Dockerfile/docker-compose
in the `Docker` repo are only used for local dev, not by this deployment.

## How it works

1. **Terraform** creates an RDS MySQL instance, an S3 bucket, and uploads the
   app's PHP files + `schema.sql` plus the Ansible playbook (`ansible/setup.yml`)
   to that bucket. RDS is created (and reaches `available`) before the EC2
   instance is launched - the instance's `depends_on` requires it, along with
   the Parameter Store entries.
2. DB connection details (host, port, db name, username, password) are
   written to SSM Parameter Store under `/<project_name>/db/*` (password as
   `SecureString`).
3. The EC2 instance (Amazon Linux 2023, public subnet, no SSH - SSM Session
   Manager only) boots with a userdata script that:
   - downloads the app files and playbook from S3 into `/srv`
   - installs Ansible
   - waits briefly, then runs `ansible-playbook /srv/ansible/setup.yml`
4. The playbook installs Apache/PHP, pulls the DB credentials from Parameter
   Store, copies the app into `/var/www/html`, sets ownership/permissions,
   imports `schema.sql` into RDS, and serves the app on **port 80 only**
   (plain HTTP, kept simple - no TLS).

## Security groups

- App EC2: inbound 80 only, from `var.allowed_http_cidr` (defaults to
  `0.0.0.0/0` since this is a public demo webapp). No inbound SSH.
- RDS: inbound 3306 only from the app's security group.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Outputs include `app_url`, `db_endpoint`, and `db_parameter_store_prefix`.

## Notes / simplifications (this is a demo, not production-hardened)

- `skip_final_snapshot = true` on the RDS instance for easy teardown.
- Plain HTTP, no TLS - fine for a demo; put an ALB + ACM cert in front for
  anything real.
- Schema import happens once per instance (guarded by a marker file), so
  re-running the playbook won't duplicate the seed row.
- Uses the default VPC/subnets to keep the resource count small; RDS is not
  publicly accessible even though it shares subnets with the public-facing
  EC2 instance.
