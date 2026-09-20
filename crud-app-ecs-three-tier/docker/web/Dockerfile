# Web tier: nginx reverse proxy in front of the app tier's internal ALB, plus
# static assets. Replaces the nginx_frontend Ansible role of crud-app-three-tier.
FROM nginx:1.28-alpine

# The official image renders /etc/nginx/templates/*.template with envsubst at
# start-up, so the upstream is configured with an environment variable
# (UPSTREAM_HOST) instead of being baked into the image.
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY static/ /usr/share/nginx/static/

# Makes the image entrypoint export NGINX_LOCAL_RESOLVERS (the DNS servers in
# /etc/resolv.conf), used by the `resolver` directive in the template.
ENV NGINX_ENTRYPOINT_LOCAL_RESOLVERS=1

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1/healthz || exit 1
