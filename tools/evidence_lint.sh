#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: tools/evidence_lint.sh <sprint-doc-path>" >&2
  exit 2
fi

doc=$1
if [[ ! -f "$doc" ]]; then
  echo "evidence_lint: file not found: $doc" >&2
  exit 2
fi

status=0
while IFS=: read -r line _; do
  block=$(sed -n "$((line+1)),$((line+10))p" "$doc")
  if ! grep -q '\.scratch/verification/SPRINT-001/' <<<"$block"; then
    echo "evidence_lint: checked item at line $line missing .scratch evidence reference" >&2
    status=1
  fi
  if ! grep -q 'exit code' <<<"$(tr '[:upper:]' '[:lower:]' <<<"$block")"; then
    echo "evidence_lint: checked item at line $line missing exit code annotation" >&2
    status=1
  fi
  if ! grep -q '`' <<<"$block"; then
    echo "evidence_lint: checked item at line $line missing command in backticks" >&2
    status=1
  fi

done < <(rg -n '^- \[X\]' "$doc")

exit "$status"
