# Live E2E Smoke Suite (`make test-e2e`)

## Purpose
`make test-e2e` runs opt-in live smoke tests for:
- `unified_llm`
- `coding_agent_loop`
- `attractor`

These tests call real provider HTTPS APIs and require API keys.

## Prerequisites
- Tcl 8.5+
- Tcl packages:
  - `http`
  - `tls` (required for `https://` transport)
  - `json`
- Minimum TLS runtime: `tls >= 1.7.22`
- Recommended runtime: Tcl 8.6+ with current distro `tcl-tls`
- Provider API key(s):
  - `OPENAI_API_KEY`
  - `ANTHROPIC_API_KEY`
  - `GEMINI_API_KEY`

## Runtime Preflight
Quick probe:
```bash
tclsh <<'TCL'
puts "tcl=[info patchlevel]"
if {[catch {package require tls} tlsErr]} {
  puts stderr "tls=missing"
  puts stderr "tls_error=$tlsErr"
  exit 1
}
puts "tls=[package provide tls]"
TCL
```

If your default `tclsh` is too old, override it:
```bash
TCLSH=/path/to/modern/tclsh make test-e2e
```

## Environment Variables
- Provider selection:
  - `E2E_LIVE_PROVIDERS` (optional, comma-separated allowlist)
  - Example: `openai,anthropic`
- Model overrides:
  - `OPENAI_MODEL` (default `gpt-4o-mini`)
  - `ANTHROPIC_MODEL` (default `claude-sonnet-4-5`)
  - `GEMINI_MODEL` (default `gemini-2.5-flash`)
- Base URL overrides:
  - `OPENAI_BASE_URL` (default `https://api.openai.com`)
  - `ANTHROPIC_BASE_URL` (default `https://api.anthropic.com`)
  - `GEMINI_BASE_URL` (default `https://generativelanguage.googleapis.com`)
- Artifact root override:
  - `E2E_LIVE_ARTIFACT_ROOT` (default `.scratch/verification/SPRINT-007/live/<run_id>`)

## Provider Selection Rules
- Default behavior: run all providers with configured keys.
- If `E2E_LIVE_PROVIDERS` is set:
  - every requested provider must have its key configured
  - missing key for a requested provider is a fail-fast error
- If no providers are selected, the harness exits non-zero before any network calls.

## Example Runs
- One provider:
```bash
OPENAI_API_KEY=... make test-e2e
```

- Multiple providers:
```bash
OPENAI_API_KEY=... ANTHROPIC_API_KEY=... make test-e2e
```

- Explicit provider requested but missing key (expected fail-fast):
```bash
E2E_LIVE_PROVIDERS=openai make test-e2e
```

## Artifacts
Default root:
- `.scratch/verification/SPRINT-007/live/<run_id>/`

Key files:
- `run.json`
- `runtime-preflight.json`
- `preflight-failure.json` (only when runtime preflight fails)
- `secret-leaks.json`
- `unified_llm/<provider>/...`
- `coding_agent_loop/<provider>/...`
- `attractor/<provider>/...`

## Redaction Checklist
- `response.request.headers` in saved artifacts must not contain raw:
  - `Authorization`
  - `x-api-key`
  - `x-goog-api-key`
- Failure logs must not include real API key values.
- Artifact leak scan runs automatically after every live run.

## Manual Secret Scan Procedure
Use this if you need a separate audit without printing the key value:
```bash
rg --files .scratch/verification/SPRINT-007/live/<run_id>
```
Then inspect `secret-leaks.json`:
```bash
cat .scratch/verification/SPRINT-007/live/<run_id>/secret-leaks.json
```
If leaks are found, only file paths are reported.

## Costs and Side Effects
- Runs real provider API calls and incurs provider usage costs.
- Writes local artifacts under `.scratch/verification/SPRINT-007/live/`.
