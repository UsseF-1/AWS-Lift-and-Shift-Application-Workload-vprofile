#!/bin/bash
set -euxo pipefail

# Ubuntu 24.04 - Tomcat 10
apt-get update -y
apt-get install -y tomcat10 awscli

systemctl enable --now tomcat10
echo "Tomcat provisioning complete."
