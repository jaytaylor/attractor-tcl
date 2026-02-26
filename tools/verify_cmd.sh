#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: tools/verify_cmd.sh <logpath> <command...>" >&2
  exit 2
fi

logpath=$1
shift

mkdir -p "$(dirname "$logpath")"
set +e
"$@" 2>&1 | tee "$logpath"
status=${PIPESTATUS[0]}
set -e
printf "exit_code=%d\n" "$status" >> "$logpath"
exit "$status"
