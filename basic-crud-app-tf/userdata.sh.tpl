#!/bin/bash
set -euxo pipefail

BUCKET="${bucket_name}"
REGION="${aws_region}"
SSM_PREFIX="${ssm_prefix}"

mkdir -p /srv/app /srv/ansible
cd /srv

# AWS CLI v2 ships preinstalled on Amazon Linux 2023.
aws s3 cp "s3://$BUCKET/app/" /srv/app/ --recursive --region "$REGION"
aws s3 cp "s3://$BUCKET/ansible/" /srv/ansible/ --recursive --region "$REGION"

dnf install -y python3-pip
pip3 install --no-cache-dir ansible-core

# Give RDS a little extra breathing room before configuring the app, on top
# of the terraform-level dependency that already waits for RDS to be
# available before this instance is even launched.
sleep 60

ansible-playbook /srv/ansible/setup.yml \
  --extra-vars "aws_region=$REGION ssm_prefix=$SSM_PREFIX"
