#!/usr/bin/env bash
# Builds the web and app images and pushes them to their ECR repositories.
#
#   scripts/push-images.sh          # both tiers
#   scripts/push-images.sh app      # just one (web | app)
#
# Each image gets two tags: a content hash of its build context (so you can tell
# exactly what is in a repository) and `latest`. Terraform resolves `latest` to a
# digest, so after a push, `terraform apply` rolls the service.
#
# Needs: docker, the AWS CLI with credentials, terraform (repositories must
# already exist: terraform apply -target=module.ecr).
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ $# -gt 0 ]]; then tiers=("$@"); else tiers=(web app); fi

urls_json="$(terraform output -json ecr_repository_urls)"

repo_url() {
  python3 -c 'import json,sys; print(json.loads(sys.argv[1])[sys.argv[2]])' "$urls_json" "$1"
}

# Content hash of a build context: file names + contents, order-independent of
# the filesystem. Changes whenever anything that goes into the image changes.
context_hash() {
  (cd "docker/$1" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | cut -c1-12)
}

logged_in=""
for tier in "${tiers[@]}"; do
  [[ -d "docker/$tier" ]] || { echo "unknown tier '$tier' (expected: web, app)" >&2; exit 1; }

  url="$(repo_url "$tier")"
  registry="${url%%/*}"                       # <account>.dkr.ecr.<region>.amazonaws.com
  region="$(cut -d. -f4 <<<"$registry")"

  if [[ "$logged_in" != *"$registry"* ]]; then
    aws ecr get-login-password --region "$region" |
      docker login --username AWS --password-stdin "$registry" >/dev/null
    logged_in+=" $registry"
  fi

  tag="$(context_hash "$tier")"
  echo "==> $tier: building $url:$tag"

  # linux/amd64 because the container instances are x86_64 (matters when building
  # on Apple silicon). --provenance=false keeps each tag a plain single image.
  docker build --platform linux/amd64 --provenance=false \
    -t "$url:$tag" -t "$url:latest" "docker/$tier"

  docker push "$url:$tag"
  docker push "$url:latest"
done

echo
echo "Pushed: ${tiers[*]}. Now run: terraform apply"
