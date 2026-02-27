# Architecture Decision Record Log

## ADR-001: Tcl 8.5-First Modular Runtime For NLSpec Implementation
- Date: 2026-02-25
- Status: Accepted

### Context
The repository currently contains only NLSpecs and needs a full implementation of Attractor, Unified LLM, and Coding Agent Loop in Tcl. Runtime constraints include Tcl 8.5 compatibility and deterministic local testing.

### Decision
Adopt a modular package layout with shared core utilities:
- `lib/attractor/`
- `lib/unified_llm/`
- `lib/coding_agent_loop/`
- `lib/attractor_core/`

Use dictionary-based domain models and callback-oriented streaming APIs to preserve Tcl 8.5 compatibility.

Require deterministic offline verification using local mock provider servers, with live-provider smoke tests gated by environment secrets.

Use a requirement-ID traceability model (`ATR-*`, `CAL-*`, `ULLM-*`) mapped to implementation files, tests, and verification commands.

### Consequences
Positive:
- Enables parallel work across modules with stable boundaries.
- Keeps tests deterministic and reproducible in CI and local environments.
- Creates auditable proof of spec compliance via traceability and evidence logs.

Tradeoffs:
- Callback-based streaming APIs require explicit buffering helpers for deterministic test assertions.
- Traceability maintenance adds documentation overhead that must be kept in sync with code and tests.

### Follow-up
Any future change to package boundaries, runtime data model shape, or streaming/event contract must add a new ADR entry before implementation.

## ADR-002: Deterministic Verification and CLI Validation Contract
- Date: 2026-02-26
- Status: Accepted

### Context
Sprint closeout required strict evidence-backed completion, deterministic CLI verification coverage, and reduced runtime coupling to ambient environment variable ambiguity.

### Decision
- Strengthen traceability validation with duplicate-ID checks, required path checks, and family summaries in `tools/spec_coverage.tcl`.
- Add explicit Attractor CLI `validate` command so parse/validate workflows are first-class and testable independently of execution.
- Harden Unified LLM runtime behavior:
  - Explicit provider override support via `UNIFIED_LLM_PROVIDER`.
  - Ambiguous multi-key environments fail fast in `from_env`.
  - `generate` uses provider-scoped ephemeral clients when needed and safely handles stale default client handles.
- Enforce non-zero harness exit behavior for failed tests in `tests/all.tcl`.

### Consequences
Positive:
- Verification output is auditable and consistent across local and CI runs.
- CLI behavior now aligns with validate/run/resume matrix requirements.
- Provider-selection behavior is safer in mixed-secret environments.

Tradeoffs:
- Stricter environment handling surfaces errors earlier and may require explicit configuration in multi-provider setups.
- Additional integration tests and evidence logs increase maintenance overhead.

## ADR-003: Spec-Derived Requirement Catalog and Strict Traceability Set Equality
- Date: 2026-02-27
- Status: Accepted

### Context
Previous spec coverage checks validated traceability block shape/path hygiene but did not guarantee completeness versus the source specs. This allowed false-green coverage when large portions of DoD and normative requirements were unmapped.

### Decision
- Introduce explicit `req_id` annotations in all three spec documents for:
  - every `Definition of Done` checkbox
  - every normative statement containing `MUST`, `MUST NOT`, or `REQUIRED` (outside code fences)
- Add `tools/requirements_catalog.tcl` to:
  - validate `req_id` coverage and format (`--check-ids`)
  - generate deterministic catalog artifacts (`requirements.json`, `requirements.md`)
  - report family/kind summaries (`--summary`)
- Extend `tools/spec_coverage.tcl` to enforce strict catalog/traceability ID set equality:
  - catalog IDs missing from traceability fail
  - unknown traceability IDs fail
  - duplicate traceability IDs fail
- Add verify-command sanity enforcement:
  - each `verify` command must include `tests/all.tcl -match <pattern>`
  - pattern must resolve to at least one real test name

### Consequences
Positive:
- Coverage status now reflects completeness, not only formatting.
- Spec and implementation mapping is auditable with deterministic artifacts.
- Drift is surfaced immediately when specs add requirements.

Tradeoffs:
- Spec edits now require explicit `req_id` maintenance.
- Traceability file is significantly larger and must remain curated.
- Verification rigor adds upfront maintenance work but removes false-green risk.

## ADR-004: Structured Catalog JSON Validation and Sprint-Agnostic Evidence Linting
- Date: 2026-02-27
- Status: Accepted

### Context
`tools/spec_coverage.tcl` originally collected catalog IDs with regex extraction, which could hide malformed test fixtures and non-object catalog structures. `tools/evidence_lint.sh` was also hardcoded to `SPRINT-001` evidence paths, limiting reuse for other sprint docs.

### Decision
- Enforce structured catalog parsing in `tools/spec_coverage.tcl` using JSON-object semantics:
  - top-level object required
  - `requirements` array required
  - each requirement must be an object with non-empty `id`
  - duplicate catalog IDs fail fast
- Update integration fixtures/tests to emit valid JSON objects so failures represent real contract violations.
- Make `tools/evidence_lint.sh` sprint-agnostic:
  - detect sprint ID from doc filename when present
  - accept evidence references under `.scratch/verification/<SPRINT-ID>/...`
  - accept diagram evidence references under `.scratch/diagram-renders/<sprint-id>/...`

### Consequences
Positive:
- Eliminates false-green behavior caused by regex-only catalog extraction.
- Moves catalog contract errors to clear, deterministic failures.
- Allows the same evidence lint workflow across sprint documents.

Tradeoffs:
- Tests and ad-hoc fixtures must now be strict JSON objects.
- Guardrail expectations are stricter, increasing up-front discipline for doc updates.

## ADR-005: Precommit Enforcement for Requirement-ID and Coverage Equality Gates
- Date: 2026-02-27
- Status: Accepted

### Context
`make build` and `make test` depend on `precommit`, but `tools/build_check.tcl` previously verified only package loadability. This left requirement catalog ID integrity and traceability equality checks outside the default developer gate unless run manually.

### Decision
- Extend `tools/build_check.tcl` to run:
  - `tclsh tools/requirements_catalog.tcl --check-ids`
  - `tclsh tools/spec_coverage.tcl`
- Keep package load checks as the first stage so runtime import failures remain visible.
- Treat these checks as mandatory for all standard build/test paths through `make`.

### Consequences
Positive:
- Prevents false-green local runs where code builds but spec mapping is stale.
- Makes spec-traceability regressions fail fast during normal developer workflows.
- Aligns local and CI behavior around a single precommit enforcement contract.

Tradeoffs:
- `make build` and `make test` now run additional validation and take slightly longer.
- Contributors working only on non-spec areas still pay this validation cost.

## ADR-006: Fail Fast on Malformed Traceability Mapping Blocks and Pin Baseline Catalog Counts
- Date: 2026-02-27
- Status: Accepted

### Context
`tools/spec_coverage.tcl` previously ignored non-empty traceability blocks that lacked `id`, which could hide accidental malformed mappings. We also wanted a deterministic guardrail that surfaces unexpected requirement-catalog shrink/churn immediately in CI.

### Decision
- Update `tools/spec_coverage.tcl` so non-empty mapping blocks missing `id` are reported as `MALFORMED_BLOCK` and fail validation.
- Add a stable baseline summary test in `tests/unit/requirements_catalog.test` that asserts default catalog totals/family/kind counts.

### Consequences
Positive:
- Malformed traceability edits can no longer pass silently.
- Catalog regressions now fail fast and require explicit test/document updates.

Tradeoffs:
- Intentional spec changes that alter catalog counts require synchronized test updates.
- Traceability parser behavior is stricter and may fail where prior versions were permissive.

## ADR-007: Unified LLM Parity Data Model and Deterministic Provider Translation
- Date: 2026-02-27
- Status: Accepted

### Context
The prior Unified LLM implementation used text-only request payloads, synthesized streaming from blocking responses, and permissive provider fallback behavior (`mock` when no configuration was present). Sprint #003 required deterministic configuration errors, richer content parts, native provider payload mapping, and stronger typed error behavior.

### Decision
- Promote message normalization to first-class content parts (`text`, `thinking`, `image_url`, `image_base64`, `image_path`, `tool_result`).
- Require deterministic provider selection errors when no provider is configured or the environment is ambiguous.
- Keep deterministic offline behavior with transport callbacks but add native HTTP transport path support for provider adapters.
- Add provider-specific option validation (`extra_headers`, Anthropic `beta_headers`, Gemini `safety_settings`) before transport execution.
- Add streaming event model (`STREAM_START`, `TEXT_DELTA`, `TOOL_CALL_END`, `FINISH`) as adapter-supported behavior rather than only post-hoc wrapping.
- Expand unified usage normalization to include cache-write token accounting.

### Consequences
Positive:
- Cross-provider behavior is explicit and deterministic under tests.
- Multimodal input and structured-output paths now have typed validation failures.
- Callers can distinguish config/input/provider transport failures by error code.

Tradeoffs:
- Request normalization and provider translation code paths are significantly larger.
- More adapter-level test fixtures are required to keep translation correctness stable.

## ADR-008: Coding Agent Loop ExecutionEnvironment and Session-State Machine Parity
- Date: 2026-02-27
- Status: Accepted

### Context
The prior Coding Agent Loop directly executed filesystem/process operations in tool procedures and had limited session-state semantics for steering, aborts, and loop detection. Sprint #003 required a clear execution contract, deterministic truncation/cancellation behavior, and richer event semantics.

### Decision
- Introduce explicit `ExecutionEnvironment` abstraction with a local reference implementation for file/process/search operations.
- Route tool implementations through `ExecutionEnvironment` so sessions and subagents can share one runtime environment.
- Add session steering queue semantics so `steer` modifies the next model request payload.
- Expand session event emissions with model request lifecycle and turn-end semantics.
- Add explicit session abort handling and subagent depth-limit enforcement.
- Add repeated tool-signature loop detection to emit deterministic warning events.

### Consequences
Positive:
- Tool behavior is more testable and composable across session/subagent boundaries.
- Steering and abort semantics are observable and deterministic.
- Default truncation and shell-timeout semantics are centrally controlled by session config.

Tradeoffs:
- Session internals now manage more state fields and event transitions.
- Subagent management needs stricter cleanup to avoid dangling sessions in tests.

## ADR-009: Attractor DOT/Validation/Handler Parity with Warning-Preserving CLI Validate
- Date: 2026-02-27
- Status: Accepted

### Context
The previous Attractor runtime handled only a narrow DOT subset and coarse validation rules. Sprint #003 required stricter start/exit invariants, richer diagnostic metadata, additional handler behavior, and validate/run/resume parity with deterministic artifacts.

### Decision
- Replace parser statement splitting with quote/bracket/brace-aware parsing and support chained edges, defaults, and subgraph flattening.
- Enforce one start (`shape=Mdiamond`) and one exit (`shape=Msquare`) invariants with structured diagnostics (`severity`, `rule`, `message`).
- Emit reachability warnings while allowing execution when warnings exist.
- Strengthen edge validity by requiring explicitly declared nodes.
- Expand runtime handler coverage (`wait.human`, `conditional`, `parallel`, `fan-in`, `tool`, `stack.manager_loop`) and custom-handler registration.
- Add built-in interviewer implementations (`autoapprove`, `queue`, `callback`, `console`).
- Update CLI `validate` to fail only on error-severity diagnostics and surface warnings in output.

### Consequences
Positive:
- Parse/validate behavior is explicit and test-covered for both positive and negative paths.
- Runtime routing and interviewer behavior are deterministic under fixtures.
- CLI workflows align with spec-required validate/run/resume contracts.

Tradeoffs:
- Parser and validator complexity increased.
- Existing DOT examples had to migrate from legacy shape markers to `Mdiamond`/`Msquare`.

## ADR-010: Phase-Scoped Sprint Verification Evidence as a First-Class Contract
- Date: 2026-02-27
- Status: Accepted

### Context
Sprint #003 closeout artifacts were historically easy to reproduce but were coarse-grained: many checklist lines referenced a single umbrella run, making it harder to audit phase-level proof and command-to-artifact linkage.

### Decision
- Adopt a phase-scoped execution evidence layout for Sprint #003 under `.scratch/verification/SPRINT-003/execution-2026-02-27/`.
- Record command-level status in both per-phase and aggregate tables:
  - `phase-*/command-status.tsv`
  - `command-status-all.tsv`
- Require deterministic generation of a requirement-family gap ledger by comparing requirement catalog IDs against traceability IDs.
- Treat appendix diagram rendering (`mmdc`) as a mandatory closeout artifact, stored under `.scratch/diagram-renders/sprint-003/`.

### Consequences
Positive:
- Checklist completion can be audited at phase and command granularity.
- Requirement ownership closure is explicitly provable from generated ledgers.
- Diagram and docs verification become repeatable, explicit closeout gates.

Tradeoffs:
- Evidence generation adds additional local execution time during sprint closeout.
- Maintaining phase indexes increases documentation overhead, especially for small doc-only changes.
