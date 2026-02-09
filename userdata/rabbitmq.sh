#!/bin/bash
set -euxo pipefail

# Amazon Linux 2023 - RabbitMQ
# Uses repo file bundled in this repo; here we download it directly from upstream.
# If you fork this repo, update the URL to YOUR fork.

dnf -y update
dnf -y install curl ca-certificates gnupg

# Import signing keys (RabbitMQ + Erlang)
rpm --import https://packagecloud.io/rabbitmq/erlang/gpgkey
rpm --import https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey

# Repo file (Erlang + RabbitMQ) - adjust URL if needed
curl -fsSL -o /etc/yum.repos.d/rabbitmq.repo https://raw.githubusercontent.com/hkhcoder/vprofile-project/awsliftandshift/rabbitmq.repo

dnf -y update
dnf -y install socat logrotate erlang rabbitmq-server

systemctl enable --now rabbitmq-server

# Create user and set permissions (credentials used by sample app)
rabbitmqctl add_user test test || true
rabbitmqctl set_user_tags test administrator
rabbitmqctl set_permissions -p / test ".*" ".*" ".*"

systemctl restart rabbitmq-server
echo "RabbitMQ provisioning complete."
