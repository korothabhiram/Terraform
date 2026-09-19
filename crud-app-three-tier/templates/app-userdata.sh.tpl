#!/bin/bash
# content-hash: ${content_hash}
# (changes when the app or any Ansible file changes -> new launch template -> instance refresh)
set -euxo pipefail

BUCKET="${bucket_name}"
REGION="${aws_region}"

mkdir -p /srv/app /srv/ansible

aws s3 sync "s3://$BUCKET/app/" /srv/app/ --region "$REGION"
aws s3 sync "s3://$BUCKET/ansible/" /srv/ansible/ --region "$REGION"

dnf install -y python3-pip
pip3 install --no-cache-dir ansible-core

# RDS is already available (terraform depends_on) and the role also waits for
# port 3306, so no fixed sleep is needed.
ansible-playbook /srv/ansible/app.yml \
  --extra-vars "aws_region=$REGION ssm_prefix=${ssm_prefix} db_secret_arn=${db_secret_arn}"
