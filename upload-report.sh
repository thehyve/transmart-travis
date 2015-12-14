#!/bin/bash -e

DIR="$(cd "$( dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPORTS_SERVER=clover@dev2.thehyve.net
DEFAULT_REPORTS_DIR=/home/clover/public_html

function upload_report {
  local readonly reports_dir=$1
  local server=$2 server_dir=$3 target_dir=

  # expects KEY_PASSWORD
  : ${KEY_PASSWORD:?"KEY_PASSWORD not set"}

  : ${server:=$DEFAULT_REPORTS_SERVER}
  : ${server_dir:=$DEFAULT_REPORTS_DIR}

  if [[ ! -d $reports_dir ]]; then
    echo "Directory $reports_dir not found; skipping" >&2
    exit 0
  fi

  openssl rsa -in "$DIR"/reports_id_rsa.enc -out "$DIR"/reports_id_rsa -passin "pass:$KEY_PASSWORD"
  chmod 600 "$DIR"/reports_id_rsa
  target_dir="${TRAVIS_REPO_SLUG##*/}/${TRAVIS_REPO_SLUG%%/*}-$TRAVIS_JOB_NUMBER-$TRAVIS_BRANCH"
  tar -czf - --verbose --format=gnu "$reports_dir" \
      --xform='s,'"${reports_dir%/}"','"$target_dir"',' | \
      ssh "$server" -o StrictHostKeyChecking=no -i "$DIR"/reports_id_rsa \
      "tar -C '$server_dir' -xzf -"
}
