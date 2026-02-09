#!/bin/bash
set -euxo pipefail

# Amazon Linux 2023 - Memcached
dnf -y update
dnf -y install memcached

# Listen on all interfaces (required for remote app servers)
# Default config differs across distros; this line usually exists in /etc/sysconfig/memcached
if [ -f /etc/sysconfig/memcached ]; then
  sed -i 's/^OPTIONS=.*/OPTIONS="-l 0.0.0.0"/' /etc/sysconfig/memcached || true
fi

systemctl enable --now memcached

# Confirm it listens on 11211
ss -lntp | grep 11211 || true
echo "Memcached provisioning complete."
