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
