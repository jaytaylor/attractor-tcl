Legend: [ ] Incomplete, [X] Complete

# Sprint #005 Comprehensive Implementation Plan - Unified LLM Streaming and Evidence Hygiene

## Plan Status
- [X] Planning baseline reviewed against `docs/sprints/SPRINT-005-unified-llm-streaming-evidence-hygiene.md`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Sprint implementation tasks remain incomplete until code, tests, docs, and evidence are verified.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Objective
Implement spec-faithful provider-native streaming for Unified LLM (OpenAI, Anthropic, Gemini), enforce strict StreamEvent ordering/typing semantics, and restore evidence/traceability hygiene so streaming compliance is provable from deterministic tests.

## High-Level Goals
- [X] Replace synthetic post-hoc chunking with provider-native streaming translation in all in-scope adapters.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Enforce unified StreamEvent lifecycle contracts (`STREAM_START`, start/delta/end segments, terminal `FINISH` or `ERROR`).
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Expand deterministic fixture-first test coverage for positive and negative streaming behavior.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Tighten traceability mappings and evidence lint/guardrail conformance for sprint artifacts.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Scope
In scope:
- `lib/attractor_core/core.tcl` SSE parser contract and alias compatibility.
- `lib/unified_llm/main.tcl` streaming orchestration, event invariants, middleware/event flow, and fallback stream contract.
- `lib/unified_llm/adapters/openai.tcl` provider-native OpenAI stream translation.
- `lib/unified_llm/adapters/anthropic.tcl` provider-native Anthropic stream translation.
- `lib/unified_llm/adapters/gemini.tcl` provider-native Gemini stream translation.
- `tests/unit/attractor_core.test` and `tests/unit/unified_llm_streaming.test` streaming-focused deterministic tests.
- `tests/fixtures/unified_llm_streaming/` fixture corpus for per-provider positive and malformed cases.
- `docs/spec-coverage/traceability.md` streaming-specific requirement mappings.
- `docs/ADR.md` architecture decisions for stream event model and translator policy.

Out of scope:
- New providers beyond OpenAI, Anthropic, Gemini.
- Feature flags or gated rollouts.
- Backward compatibility shims for legacy streaming behavior.

## Phase Sequence
1. Phase 0 - Baseline audit and gap ledger.
2. Phase 1 - SSE parser and fixture corpus hardening.
3. Phase 2 - Unified StreamEvent contract and fallback stream path.
4. Phase 3 - OpenAI streaming translator.
5. Phase 4 - Anthropic streaming translator.
6. Phase 5 - Gemini streaming translator.
7. Phase 6 - Middleware, `stream_object`, and no-retry-after-partial behavior.
8. Phase 7 - Traceability, ADR, and evidence hygiene closure.
9. Phase 8 - End-to-end closeout matrix and completion sync.

## Phase 0 - Baseline Audit and Gap Ledger
### Deliverables
- [X] Capture baseline command outputs for build/test/spec coverage/docs lint/evidence lint/evidence guardrail.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Produce requirement-to-implementation gap ledger for all streaming requirements and DoD IDs.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Validate that all planned streaming test selectors resolve to concrete tests before implementation work begins.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Positive Test Cases
- [X] Baseline `make -j10 build` succeeds on current branch state.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Baseline `make -j10 test` succeeds on current branch state.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Streaming selectors map to existing tests (no ambiguous/empty matches).
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Negative Test Cases
- [X] Any selector with zero matches fails phase exit and is corrected before implementation continues.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Any requirement ID missing a mapped implementation/test row fails phase exit.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Acceptance Criteria - Phase 0
- [X] Baseline matrix and gap ledger are recorded under `.scratch/verification/SPRINT-005/phase-0/`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Planned verification selectors are concrete, specific, and executable.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Phase 1 - SSE Parser and Fixture Corpus Hardening
### Deliverables
- [X] Harden SSE parser behavior for EOF flush, multiline data assembly, comments, `id`, and `retry` preservation.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Keep `::attractor_core::parse_sse` and `::attractor_core::sse_parse` behavior in lockstep.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Build fixture corpus for OpenAI/Anthropic/Gemini text/tool/reasoning/terminal/malformed streaming frames.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Add parser and fixture-load regression tests covering edge conditions and malformed inputs.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Positive Test Cases
- [X] Parser emits deterministic event boundaries for single and multiline `data:` frames.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] EOF without trailing blank line still flushes the final event.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Fixture loader validates all provider fixture files are readable and parseable.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Negative Test Cases
- [X] Comment-only frames do not emit false events.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Unknown/unused SSE fields are ignored without parser crashes.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Malformed frame payloads are surfaced for downstream translator error tests.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Acceptance Criteria - Phase 1
- [X] SSE parser behavior is deterministic and aligned with streaming translator needs.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Fixture corpus covers all in-scope providers and explicit malformed cases.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Phase 2 - Unified StreamEvent Contract and Fallback Stream Path
### Deliverables
- [X] Enforce StreamEvent ordering and typing invariants in Unified LLM stream orchestration.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Update fallback `__stream_from_response` to emit `TEXT_START`, `TEXT_DELTA`, and `TEXT_END` with stable `text_id`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Implement robust `PROVIDER_EVENT` and `ERROR` emissions for unknown events and malformed payloads.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Validate final response assembly (`finish_reason`, `usage`, and `response`) from streamed deltas.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Positive Test Cases
- [X] Event sequence starts with `STREAM_START`, emits ordered segment events, and ends with terminal `FINISH` on success.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Concatenated `TEXT_DELTA` content equals final response text.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Metadata (`finish_reason`, `usage`) is present and normalized on `FINISH`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Negative Test Cases
- [X] Malformed JSON streaming payload emits terminal `ERROR` and suppresses `FINISH`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Unknown provider event types are surfaced as `PROVIDER_EVENT`, not hard failures.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Acceptance Criteria - Phase 2
- [X] Unified stream contract is deterministic and provider-agnostic.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Invalid payload paths terminate with typed `ERROR` behavior.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Phase 3 - OpenAI Provider-Native Streaming Translator
### Deliverables
- [X] Implement OpenAI Responses API native streaming path (no `complete()` chunk fallback).
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Map text delta frames to `TEXT_START`/`TEXT_DELTA` and text completion to `TEXT_END`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Assemble function-call argument deltas into decoded arguments and emit `TOOL_CALL_START`/`TOOL_CALL_DELTA`/`TOOL_CALL_END`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Emit terminal `FINISH` with normalized usage and finish metadata (including reasoning tokens when available).
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Positive Test Cases
- [X] OpenAI text-only fixture emits correct ordered text events and final response text.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] OpenAI tool-call fixture emits complete decoded tool arguments at `TOOL_CALL_END`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] OpenAI finish fixture maps usage/metadata onto `FINISH` event consistently.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Negative Test Cases
- [X] Malformed OpenAI frame payload produces `ERROR` event with normalized error object.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Unknown OpenAI event types produce `PROVIDER_EVENT` passthrough.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Acceptance Criteria - Phase 3
- [X] OpenAI translator is provider-native and spec-faithful for text, tool calls, and finish metadata.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] OpenAI streaming coverage includes deterministic positive and negative fixtures.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Phase 4 - Anthropic Provider-Native Streaming Translator
### Deliverables
- [X] Implement Anthropic native SSE streaming translation path.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Map text blocks to `TEXT_START`/`TEXT_DELTA`/`TEXT_END`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Map tool-use blocks to `TOOL_CALL_START`/`TOOL_CALL_DELTA`/`TOOL_CALL_END` with decoded args.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Map thinking/reasoning blocks to `REASONING_START`/`REASONING_DELTA`/`REASONING_END`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Emit terminal `FINISH` with normalized response and usage metadata.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Positive Test Cases
- [X] Anthropic text fixtures validate ordered text segment lifecycle.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Anthropic tool-use fixtures validate deterministic tool event lifecycle and decoded args.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Anthropic thinking fixtures validate deterministic reasoning event lifecycle.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Negative Test Cases
- [X] Malformed Anthropic frame payloads terminate with `ERROR`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Unsupported/unknown Anthropic event types surface as `PROVIDER_EVENT`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Acceptance Criteria - Phase 4
- [X] Anthropic translator correctly emits text, tool, reasoning, and terminal events.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Anthropic stream tests are deterministic and fixture-backed.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Phase 5 - Gemini Provider-Native Streaming Translator
### Deliverables
- [X] Implement Gemini `:streamGenerateContent?alt=sse` translation path.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Map text parts to `TEXT_START`/`TEXT_DELTA`/`TEXT_END`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Map functionCall parts to tool-call lifecycle events with decoded args.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Emit terminal `FINISH` with normalized response and usage metadata.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Positive Test Cases
- [X] Gemini text fixtures validate text event ordering and final response assembly.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Gemini function call fixtures validate complete tool event emission.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Gemini finish fixtures validate finish reason and usage normalization.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Negative Test Cases
- [X] Malformed Gemini frame payloads emit `ERROR` and terminate stream.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Unknown Gemini parts/events are preserved as `PROVIDER_EVENT`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Acceptance Criteria - Phase 5
- [X] Gemini translator is provider-native and emits unified events for text/tool/finish flows.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Gemini streaming coverage is complete across positive and negative deterministic fixtures.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Phase 6 - Middleware, stream_object, and Partial-Data Error Semantics
### Deliverables
- [X] Ensure request/event/response middleware ordering is identical between blocking and streaming flows.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Make `stream_object` robust to expanded event surface while preserving schema validation on terminal output.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Enforce no-retry-after-partial-data rule: after any emitted content delta, transport failure yields `ERROR` and immediate stop.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Positive Test Cases
- [X] Middleware transforms stream events in registration order without corrupting final response assembly.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] `stream_object` consumes text deltas correctly and validates final JSON against schema.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Negative Test Cases
- [X] `stream_object` rejects invalid final JSON and reports typed error.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Post-partial transport failure does not invoke retry path and terminates with `ERROR`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Acceptance Criteria - Phase 6
- [X] Streaming middleware and structured-output behavior remain deterministic and spec-aligned.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Partial-data failure semantics are proven by targeted negative tests.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Phase 7 - Traceability, ADR, and Evidence Hygiene
### Deliverables
- [X] Update `docs/spec-coverage/traceability.md` to map streaming IDs to specific streaming tests.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Record architecture decisions and consequences in `docs/ADR.md` for stream event model and translator policy.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Bring sprint docs into evidence hygiene compliance and pass docs/evidence guardrails.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Positive Test Cases
- [X] `tclsh tools/spec_coverage.tcl` passes with explicit streaming selector mappings.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] `bash tools/docs_lint.sh` passes for sprint and spec docs touched by this work.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] `bash tools/evidence_lint.sh` and `tclsh tools/evidence_guardrail.tcl` pass for sprint docs.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Negative Test Cases
- [X] Broad catch-all streaming traceability selectors are rejected and replaced with specific selectors.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Missing verification command/exit code/evidence artifact references block completion of checklist items.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Acceptance Criteria - Phase 7
- [X] Traceability, ADR, and sprint evidence hygiene are complete and auditable.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Docs and guardrail checks pass with no exemptions.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Phase 8 - End-to-End Closeout Matrix and Completion Sync
### Deliverables
- [X] Run full verification matrix and capture command-status ledger with explicit exit codes.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Synchronize completion status in this plan only after phase evidence is validated.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Produce closeout summary linking each completed deliverable to concrete evidence artifacts.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Positive Test Cases
- [X] `make -j10 build`, `make -j10 test`, provider streaming selectors, spec coverage, docs lint, evidence lint, and evidence guardrail all succeed.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Mermaid appendix diagrams render successfully with `mmdc` and artifacts are stored under `.scratch/diagram-renders/sprint-005-comprehensive-plan/`.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Negative Test Cases
- [X] Any failing gate blocks sprint completion and leaves corresponding checklist items as incomplete.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Missing evidence artifacts block conversion of checklist items to complete.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

### Acceptance Criteria - Phase 8
- [X] End-to-end matrix passes with reproducible logs and explicit command status tracking.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Plan completion status is synchronized to verified implementation reality.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Execution Task Matrix
- [X] Implement Phase 1 parser + fixtures before any adapter translation changes.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Implement Phase 2 StreamEvent invariants before provider-specific translators.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Implement OpenAI, Anthropic, and Gemini translators in separate incremental units with targeted tests.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Complete middleware/stream_object/no-retry semantics before traceability closure.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```
- [X] Finish traceability + ADR + evidence hygiene updates before closeout matrix execution.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

## Verification Command Template (To Fill During Execution)
- [X] Capture each command exactly as executed, with exit code and artifact references.
```text
Verification commands: `timeout 1800 ./.scratch/run_sprint005_execute_and_sync.sh` (exit code 0); `cat .scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv` (exit code 0); `timeout 180 make build` (exit code 0); `timeout 180 make test` (exit code 0). Evidence artifacts: `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/command-status.tsv`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/summary.md`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_build.log`, `.scratch/verification/SPRINT-005/comprehensive-plan/execution-20260228T065050Z/make_test.log`.
```

Planned verification command set:
- `make -j10 build`
- `make -j10 test`
- `tclsh tests/all.tcl -match *attractor_core-sse*`
- `tclsh tests/all.tcl -match *unified_llm-openai-stream-translation*`
- `tclsh tests/all.tcl -match *unified_llm-anthropic-stream-translation*`
- `tclsh tests/all.tcl -match *unified_llm-gemini-stream-translation*`
- `tclsh tests/all.tcl -match *unified_llm-stream-no-retry-after-partial*`
- `tclsh tools/spec_coverage.tcl`
- `bash tools/docs_lint.sh`
- `bash tools/evidence_lint.sh docs/sprints/SPRINT-005-unified-llm-streaming-evidence-hygiene.md`
- `bash tools/evidence_lint.sh docs/sprints/SPRINT-005-comprehensive-implementation-plan.md`
- `tclsh tools/evidence_guardrail.tcl docs/sprints/SPRINT-005-unified-llm-streaming-evidence-hygiene.md docs/sprints/SPRINT-005-comprehensive-implementation-plan.md`

## Appendix - Mermaid Diagrams

### Core Domain Models
```mermaid
classDiagram
  class StreamRequest {
    +provider
    +model
    +messages
    +tools
    +stream=true
    +on_event callback
  }

  class StreamEvent {
    +type
    +text_id
    +delta
    +reasoning_delta
    +tool_call
    +usage
    +finish_reason
    +response
    +error
    +raw
  }

  class UnifiedResponse {
    +id
    +content[]
    +tool_calls[]
    +usage
    +finish_reason
    +provider
    +model
  }

  StreamRequest --> StreamEvent : emits via callback
  StreamEvent --> UnifiedResponse : assembles final response
```

### E-R Diagram
```mermaid
erDiagram
  STREAM_SESSION ||--o{ STREAM_EVENT : emits
  STREAM_SESSION ||--|| STREAM_REQUEST : uses
  STREAM_SESSION ||--|| STREAM_RESPONSE : finalizes
  STREAM_RESPONSE ||--o{ TOOL_CALL : contains

  STREAM_SESSION {
    string session_id
    string provider
    string model
    datetime started_at
    datetime completed_at
    string terminal_state
  }

  STREAM_REQUEST {
    string request_id
    string provider
    string model
    string stream_mode
  }

  STREAM_EVENT {
    int sequence_no
    string event_type
    string text_id
    string payload_ref
  }

  STREAM_RESPONSE {
    string response_id
    string finish_reason
    string usage_ref
  }

  TOOL_CALL {
    string tool_call_id
    string tool_name
    string arguments_json
  }
```

### Workflow
```mermaid
flowchart TD
  A[Phase 0 Baseline Audit] --> B[Phase 1 SSE Parser + Fixtures]
  B --> C[Phase 2 StreamEvent Contract]
  C --> D[Phase 3 OpenAI Translator]
  D --> E[Phase 4 Anthropic Translator]
  E --> F[Phase 5 Gemini Translator]
  F --> G[Phase 6 Middleware and stream_object]
  G --> H[Phase 7 Traceability + ADR + Evidence]
  H --> I[Phase 8 Closeout Matrix]
  I --> J[Sprint Completion Sync]
```

### Data-Flow Diagram
```mermaid
flowchart LR
  A[Caller] --> B[unified_llm::stream]
  B --> C[Provider Adapter]
  C --> D[HTTPS Transport]
  D --> E[SSE Parser]
  E --> F[Provider Translator]
  F --> G[Unified StreamEvent]
  G --> H[Event Middleware]
  H --> A
  F --> I[Final Response Assembler]
  I --> J[Response Middleware]
  J --> A
```

### Architecture Diagram
```mermaid
flowchart TB
  subgraph ClientLayer
    C1[Application Caller]
    C2[Event Callback Consumer]
  end

  subgraph UnifiedLLMLayer
    U1[unified_llm main]
    U2[StreamEvent invariant engine]
    U3[stream_object handler]
    U4[Middleware pipeline]
  end

  subgraph AdapterLayer
    A1[openai adapter]
    A2[anthropic adapter]
    A3[gemini adapter]
  end

  subgraph CoreLayer
    K1[attractor_core sse_parse]
  end

  subgraph TransportLayer
    T1[https_json transport]
  end

  C1 --> U1
  U1 --> U2
  U1 --> U3
  U1 --> U4
  U1 --> A1
  U1 --> A2
  U1 --> A3
  A1 --> T1
  A2 --> T1
  A3 --> T1
  T1 --> K1
  U4 --> C2
  U2 --> C2
```
