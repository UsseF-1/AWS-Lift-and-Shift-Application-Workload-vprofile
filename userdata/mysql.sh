#!/bin/bash
set -euxo pipefail

# Amazon Linux 2023 - MariaDB (MySQL-compatible)
# Provisions:
# - mariadb105-server
# - creates database 'accounts'
# - creates user 'admin' with password 'admin123' (change in real use!)
# - deploys schema from vProfile upstream repo

dnf -y update
dnf -y install mariadb105-server git

systemctl enable --now mariadb

# Basic hardening-ish setup (non-interactive alternative to mysql_secure_installation)
mysql -u root <<'SQL'
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
SQL

# Create DB + user
mysql -u root <<'SQL'
CREATE DATABASE IF NOT EXISTS accounts;
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%';
FLUSH PRIVILEGES;
SQL

# Pull schema from upstream vProfile repository
# Update this URL if your upstream differs
cd /tmp
rm -rf vprofile-project || true
git clone https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project

# The schema path may vary by branch; adjust if needed.
if [ -f "src/main/resources/db_backup.sql" ]; then
  mysql -u root accounts < src/main/resources/db_backup.sql
elif [ -f "src/main/resources/db_schema.sql" ]; then
  mysql -u root accounts < src/main/resources/db_schema.sql
else
  echo "Schema file not found in expected paths. Update mysql.sh with correct schema location."
  exit 1
fi

echo "DB provisioning complete."
