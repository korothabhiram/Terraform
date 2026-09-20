#!/bin/bash
# Joins this instance to the ECS cluster. Everything else (Docker, the ECS
# agent) is already on the ECS-optimized AMI.
cat <<'CONFIG' >> /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_INSTANCE_ATTRIBUTES={"tier":"${tier}"}
CONFIG
