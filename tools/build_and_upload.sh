#!/usr/bin/env bash
set -euo pipefail

# Helper script to build vProfile and upload WAR to S3.
# Usage:
#   ./tools/build_and_upload.sh /path/to/vprofile-project YOUR_BUCKET_NAME
#
# Requirements:
# - Java 17
# - Maven 3.9+
# - AWS CLI configured (aws configure)

SRC_DIR="${1:-}"
BUCKET="${2:-}"

if [[ -z "${SRC_DIR}" || -z "${BUCKET}" ]]; then
  echo "Usage: $0 /path/to/vprofile-project YOUR_BUCKET_NAME"
  exit 1
fi

if [[ ! -f "${SRC_DIR}/pom.xml" ]]; then
  echo "ERROR: pom.xml not found in ${SRC_DIR}"
  exit 1
fi

pushd "${SRC_DIR}" >/dev/null

mvn -q clean install
WAR_PATH="$(ls -1 target/*.war | head -n 1)"

echo "Built artifact: ${WAR_PATH}"
aws s3 cp "${WAR_PATH}" "s3://${BUCKET}/"

echo "Uploaded to: s3://${BUCKET}/$(basename "${WAR_PATH}")"
popd >/dev/null
