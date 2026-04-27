#!/bin/bash
# find_template.sh <PROXMOX_IP> <TEMPLATE_NAME_PART>

set -e

HOST=$1
SEARCH_TERM=$2

# Fetch the list, filter, sort by version, and take the latest
LATEST=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@"$HOST" \
    "ls /var/lib/vz/template/cache/ | grep '$SEARCH_TERM' | sort -V | tail -n 1" 2>/dev/null)

if [ -z "$LATEST" ]; then
  # Fallback/Error JSON if no file is found
  echo '{"path": "NOT_FOUND"}'
else
  echo "{\"path\": \"local:vztmpl/$LATEST\"}"
fi
