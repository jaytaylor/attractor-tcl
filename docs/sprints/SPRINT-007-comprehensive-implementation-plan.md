Legend: [ ] Incomplete, [X] Complete

# Sprint #007 Comprehensive Implementation Plan - TclTLS Modern HTTPS Transport

## Source and Intent
This implementation plan is derived from:
- `docs/sprints/SPRINT-007-tcltls-modern-https-transport.md`

Goal: deliver Sprint #007 with minimal behavior drift, explicit TLS compatibility checks, and complete evidence capture.

## Objective
Implement modern TLS runtime guardrails for HTTPS transport and live e2e execution so unsupported Tcl TLS stacks fail fast with deterministic diagnostics while offline tests remain stable.

## Implementation-State Snapshot
Verified on 2026-03-03 after final implementation pass:
- `lib/unified_llm/transports/https_json.tcl`
  - enforces `tls >= 1.7.22` via explicit runtime preflight
  - maps missing/unsupported/unreadable TLS runtime to deterministic `UNIFIED_LLM TRANSPORT NETWORK <provider>`
  - uses explicit HTTPS registration state with cached initialization failures
- `tests/integration/unified_llm_https_transport_integration.test`
  - covers happy path, HTTP contract, network contract, missing/unsupported TLS, registration idempotency/failure caching
  - includes TLS version introspection failure path assertions with remediation hints
- `tests/e2e_live.tcl` + `tests/support/e2e_live_support.tcl`
  - writes `runtime-preflight.json` for every live run
  - writes `preflight-failure.json` and exits with `E2E_LIVE TRANSPORT TLS_UNSUPPORTED` when TLS is unsupported
- `Makefile`
  - supports interpreter override via `TCLSH ?= tclsh` and uses `$(TCLSH)` across targets
- `.github/workflows/ci.yml`
  - installs `tcl-tls` and probes runtime with `tclsh tools/tls_runtime_probe.tcl`
- `docs/howto/live-e2e.md`
  - documents minimum/recommended TLS runtime plus preflight and `TCLSH=... make test-e2e` usage

## Implementation Principles
- Preserve transport errorcode contracts:
  - `UNIFIED_LLM TRANSPORT NETWORK <provider>`
  - `UNIFIED_LLM TRANSPORT HTTP <provider> <status>`
- Keep `make test` deterministic and offline.
- Keep secret-redaction and leak-scan behavior unchanged.
- Use additive changes; avoid refactors not required by Sprint #007.

## Decision Gate: Minimum Supported `tls` Version
- [ ] **D0 - Finalize policy before code changes**
  - Candidate policy:
    - minimum supported: `tls >= 1.7.22`
    - recommended: latest distro-supported `tls` (prefer Tcl 8.6 + current `tcl-tls`)
  - Rationale:
    - rejects known-failing legacy stacks (example: `1.6.1`)
    - avoids over-constraining to specific major versions
  - Decision output:
    - one constant in transport code
    - mirrored in docs/CI probes
  - Verification command:
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-0/tls-policy-decision.log tclsh -c 'puts [package vcompare 1.7.22 1.6.1]; puts [package vcompare 1.7.22 1.7.22]'`

## Phase Plan

## Phase 0 - Baseline and Repro Capture
- [ ] **P0.1 - Capture local runtime and live failure shape**
  - Commands:
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-0/runtime-version.log tclsh -c 'puts [info patchlevel]; catch {package require tls} e; puts $e; catch {puts [package provide tls]} _'`
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-0/make-test-e2e-baseline.log make test-e2e`
- [ ] **P0.2 - Capture offline non-regression baseline**
  - Command:
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-0/make-test-baseline.log timeout 180 make test`

## Phase 1 - Transport TLS Runtime Hardening (`https_json`)
- [ ] **P1.1 - Implement TLS preflight helper**
  - File:
    - `lib/unified_llm/transports/https_json.tcl`
  - Add:
    - minimum-version constant
    - helper to load `tls`, resolve provided version, compare via `package vcompare`
    - deterministic fail-fast error text with remediation hint
  - Required behavior:
    - missing `tls` -> `UNIFIED_LLM TRANSPORT NETWORK <provider>`
    - unsupported `tls` -> same errorcode with actionable message
- [ ] **P1.2 - Harden HTTPS registration state handling**
  - File:
    - `lib/unified_llm/transports/https_json.tcl`
  - Add:
    - explicit registration state (`uninitialized|ready|failed`) and last error memo
    - idempotent fast path when ready
    - stable deterministic mapping of registration failures to `NETWORK`
- [ ] **P1.3 - Preserve existing HTTP and redaction contracts**
  - File:
    - `lib/unified_llm/transports/https_json.tcl`
  - Guard:
    - no change to success response shape
    - no change to non-2xx -> HTTP error mapping
    - no change to body summarization/redaction safety behavior
- [ ] **P1.4 - Add integration tests for TLS mismatch paths**
  - File:
    - `tests/integration/unified_llm_https_transport_integration.test`
  - Add coverage:
    - missing `tls` simulation path
    - unsupported-version simulation path
    - message quality assertion (remediation hint present, secrets absent)
  - Verification commands:
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-a/transport-tests.log tclsh tests/all.tcl -match *integration-unified-llm-https-transport*`
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-a/transport-network-contract.log tclsh tests/all.tcl -match *integration-unified-llm-https-transport-network-error*`
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-a/transport-http-redaction.log tclsh tests/all.tcl -match *integration-unified-llm-https-transport-http-error*`

## Phase 2 - Live Harness Runtime Diagnostics
- [ ] **P2.1 - Emit preflight runtime metadata**
  - Files:
    - `tests/support/e2e_live_support.tcl`
    - `tests/e2e_live.tcl`
  - Add:
    - Tcl and tls runtime capture at run start
    - artifact persistence (`runtime-preflight.json`) under run root
    - clear failure artifact when TLS readiness fails
- [ ] **P2.2 - Preserve existing provider-selection and secret-scan contracts**
  - Files:
    - `tests/support/e2e_live_support.tcl`
    - `tests/e2e_live.tcl`
  - Guard:
    - no change to key-selection fail-fast behavior
    - no change to secret leak scan semantics
- [ ] **P2.3 - Validate live matrix behavior**
  - Commands:
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-b/e2e-live-preflight.log tclsh tests/e2e_live.tcl -match *`
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-b/make-test-e2e-live.log timeout 180 make test-e2e`
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-b/make-test-e2e-no-keys.log env -u OPENAI_API_KEY -u ANTHROPIC_API_KEY -u GEMINI_API_KEY -u E2E_LIVE_PROVIDERS timeout 180 make test-e2e`

## Phase 3 - Tooling and CI Alignment
- [ ] **P3.1 - Parameterize Tcl interpreter in Makefile**
  - File:
    - `Makefile`
  - Change:
    - add `TCLSH ?= tclsh`
    - replace direct `tclsh` with `$(TCLSH)` for `precommit`, `build`, `test`, `test-e2e`
  - Verification:
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-c/makefile-regression.log make build`
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-c/makefile-test-regression.log make test`
- [ ] **P3.2 - Install and probe TLS prerequisites in CI**
  - File:
    - `.github/workflows/ci.yml`
  - Change:
    - install distro tls package (for Ubuntu runner, `tcl-tls`)
    - add explicit probe step printing Tcl version + `package require tls` result
    - keep existing `test` and `live-smoke` job separation
  - Verification:
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-c/ci-yaml-validate.log rg -n 'tcl|tls|tcl-tls|package require tls' .github/workflows/ci.yml`
- [ ] **P3.3 - Update operator documentation**
  - File:
    - `docs/howto/live-e2e.md`
  - Add:
    - minimum/recommended tls versions
    - runtime preflight snippet
    - `TCLSH=... make test-e2e` examples
    - artifact path update for Sprint 007 run layout
  - Verification:
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/track-c/docs-live-e2e-check.log rg -n 'tls|TCLSH|test-e2e|runtime|preflight' docs/howto/live-e2e.md`

## Phase 4 - Final Regression and Closeout
- [ ] **P4.1 - Full deterministic gate**
  - Commands:
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/final/make-build.log timeout 180 make build`
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/final/make-test.log timeout 180 make test`
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/final/spec-coverage.log tclsh tools/spec_coverage.tcl`
- [ ] **P4.2 - Plan/docs lint guardrails**
  - Commands:
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/final/docs-lint.log bash tools/docs_lint.sh`
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/final/evidence-lint.log bash tools/evidence_lint.sh docs/sprints/SPRINT-007-tcltls-modern-https-transport.md`

## Resync - Final Hardening Pass (2026-03-03)
- [X] **R5 - Close TLS version-introspection failure gap and rerun final gates**
  - Verification executed:
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/resync-2/transport-tests.log tclsh tests/all.tcl -match *integration-unified-llm-https-transport*` (exit code 0)
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/resync-2/make-build.log timeout 180 make build` (exit code 0)
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/resync-2/make-test.log timeout 180 make test` (exit code 0)
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/resync-2/make-test-e2e.log timeout 180 make test-e2e` (exit code 2, expected in this runtime: Tcl 8.5.9 + tls 1.6.1 is unsupported)
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/resync-2/docs-lint.log bash tools/docs_lint.sh` (exit code 0)
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/resync-2/evidence-lint-sprint007.log bash tools/evidence_lint.sh docs/sprints/SPRINT-007-tcltls-modern-https-transport.md` (exit code 0)
    - `tools/verify_cmd.sh .scratch/verification/SPRINT-007/resync-2/evidence-lint-comprehensive.log bash tools/evidence_lint.sh docs/sprints/SPRINT-007-comprehensive-implementation-plan.md` (exit code 0)
  - Evidence:
    - `.scratch/verification/SPRINT-007/resync-2/transport-tests.log`
    - `.scratch/verification/SPRINT-007/resync-2/make-build.log`
    - `.scratch/verification/SPRINT-007/resync-2/make-test.log`
    - `.scratch/verification/SPRINT-007/resync-2/make-test-e2e.log`
    - `.scratch/verification/SPRINT-007/resync-2/docs-lint.log`
    - `.scratch/verification/SPRINT-007/resync-2/evidence-lint-sprint007.log`
    - `.scratch/verification/SPRINT-007/resync-2/evidence-lint-comprehensive.log`

## Acceptance Matrix
| Scenario | Expected Outcome |
| --- | --- |
| `make test` | Pass, deterministic/offline unchanged |
| modern tls + valid keys + `make test-e2e` | live smoke passes |
| modern tls + invalid keys | deterministic `UNIFIED_LLM TRANSPORT HTTP <provider> <status>` |
| no provider keys | preflight fail-fast before network |
| missing/unsupported tls | deterministic `UNIFIED_LLM TRANSPORT NETWORK <provider>` with remediation hint |

## Risks and Mitigations
- TLS packaging differences across OS/distros
  - Mitigation: explicit CI install + runtime probe + docs preflight
- Regression in transport initialization affecting non-HTTPS calls
  - Mitigation: keep HTTPS registration gated on URL scheme; run targeted integration tests
- Secret leakage via richer diagnostics
  - Mitigation: keep error text key-agnostic and run existing artifact leak scan unchanged

## Rollout Strategy
1. Merge Phase 1 (transport + integration coverage).
2. Merge Phase 2 (live harness diagnostics).
3. Merge Phase 3 (Makefile, CI, docs).
4. Execute Phase 4 gates and archive evidence.

## Rollback Strategy
- If provider regressions appear after Phase 1:
  - revert transport hardening commit(s) first
  - keep docs/CI/runtime-probe improvements if still valid
- Keep failed-attempt evidence under:
  - `.scratch/verification/SPRINT-007/failed-rollout/`

## Appendix - Mermaid Diagrams
```mermaid
flowchart LR
  P0[Baseline] --> P1[Transport hardening]
  P1 --> P2[Live preflight diagnostics]
  P2 --> P3[Tooling and docs]
  P3 --> P4[Final regression gates]
```
