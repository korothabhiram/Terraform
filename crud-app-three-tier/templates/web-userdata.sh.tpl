#!/bin/bash
# content-hash: ${content_hash}
# (changes when any Ansible file changes -> new launch template -> instance refresh)
set -euxo pipefail

BUCKET="${bucket_name}"
REGION="${aws_region}"

mkdir -p /srv/ansible

# AWS CLI v2 ships preinstalled on Amazon Linux 2023.
aws s3 sync "s3://$BUCKET/ansible/" /srv/ansible/ --region "$REGION"

dnf install -y python3-pip
pip3 install --no-cache-dir ansible-core

ansible-playbook /srv/ansible/web.yml \
  --extra-vars "upstream_host=${upstream_host}"
