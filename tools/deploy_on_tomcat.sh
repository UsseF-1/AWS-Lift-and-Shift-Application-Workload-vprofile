#!/usr/bin/env bash
set -euo pipefail

# Deploy a WAR from S3 onto Ubuntu Tomcat 10 instance.
# Run this ON the app EC2 instance.
#
# Usage:
#   sudo ./tools/deploy_on_tomcat.sh YOUR_BUCKET_NAME vprofile-v2.war

BUCKET="${1:-}"
WAR_NAME="${2:-}"

if [[ -z "${BUCKET}" || -z "${WAR_NAME}" ]]; then
  echo "Usage: sudo $0 YOUR_BUCKET_NAME WAR_NAME"
  exit 1
fi

aws s3 cp "s3://${BUCKET}/${WAR_NAME}" "/tmp/${WAR_NAME}"

systemctl stop tomcat10
rm -rf /var/lib/tomcat10/webapps/ROOT
cp "/tmp/${WAR_NAME}" /var/lib/tomcat10/webapps/ROOT.war
systemctl start tomcat10

echo "Deployed ${WAR_NAME} to Tomcat as ROOT.war"
