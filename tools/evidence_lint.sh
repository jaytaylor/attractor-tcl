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

sprint_id=$(basename "$doc" | sed -nE 's/.*(SPRINT-[0-9]+).*/\1/p')
sprint_lower=""
if [[ -n "$sprint_id" ]]; then
  sprint_lower=$(tr '[:upper:]' '[:lower:]' <<<"$sprint_id")
fi

has_expected_evidence_ref() {
  local block=$1
  if [[ -n "$sprint_id" ]] && grep -q "\.scratch/verification/$sprint_id/" <<<"$block"; then
    return 0
  fi
  if [[ -n "$sprint_lower" ]] && grep -q "\.scratch/diagram-renders/$sprint_lower/" <<<"$block"; then
    return 0
  fi
  if grep -q '\.scratch/verification/' <<<"$block"; then
    return 0
  fi
  return 1
}

status=0
while IFS=: read -r line _; do
  block=$(sed -n "$((line+1)),$((line+10))p" "$doc")
  if ! has_expected_evidence_ref "$block"; then
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
