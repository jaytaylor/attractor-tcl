#!/usr/bin/env bash
set -euo pipefail

status=0
for f in docs/sprints/*.md; do
  [[ -f "$f" ]] || continue
  if rg -n 'T[O]DO' "$f" >/dev/null; then
    echo "docs_lint: TODO marker found in $f" >&2
    status=1
  fi
  if ! rg -n '^Legend: \[ \] Incomplete, \[X\] Complete$' "$f" >/dev/null; then
    echo "docs_lint: missing required legend format in $f" >&2
    status=1
  fi
  if ! rg -n '^## Objective$' "$f" >/dev/null; then
    echo "docs_lint: missing Objective heading in $f" >&2
    status=1
  fi
  if ! rg -n '^## Appendix - .*Mermaid' "$f" >/dev/null; then
    echo "docs_lint: missing Appendix Mermaid heading in $f" >&2
    status=1
  fi

done

exit "$status"
