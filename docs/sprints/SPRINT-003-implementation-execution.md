Legend: [ ] Incomplete, [X] Complete

# Sprint #003 Implementation Execution - Close Full Spec Parity (Tcl)

## Executive Summary
Execute and re-verify full Tcl parity for:
- `unified-llm-spec.md`
- `coding-agent-loop-spec.md`
- `attractor-spec.md`

This document is the execution log for a fresh verification-backed implementation pass.

## Goal
Deliver a deterministic, offline-verifiable parity implementation where each Sprint #003 requirement maps to:
- implementation location
- automated unit/integration/e2e tests
- reproducible verification evidence under `.scratch/verification/SPRINT-003/execution-2026-02-27/`

## Definition of Done
- `timeout 180 make build` succeeds.
- `timeout 180 make test` succeeds.
- `tclsh tools/spec_coverage.tcl` reports no missing or unknown requirement mappings.
- `docs/spec-coverage/traceability.md` resolves ULLM/CAL/ATR requirement IDs to implementation/tests/evidence.
- Mermaid appendix diagrams render successfully via `mmdc` into `.scratch/diagram-renders/sprint-003/`.

## Phase Sequence
1. Phase 0: Re-baseline and evidence scaffolding.
2. Phase 1: Unified LLM parity closure.
3. Phase 2: Coding Agent Loop parity closure.
4. Phase 3: Attractor runtime parity closure.
5. Phase 4: Cross-runtime integration closure.
6. Phase 5: Traceability, ADR, and closeout.

## Phase 0 - Re-baseline and Evidence Scaffolding
### Deliverables
- [ ] Create this execution sprint document and initialize all checklist items as incomplete.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Capture baseline command status for build/test/coverage and persist command+exit-code table.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Generate a requirement-family gap ledger for ULLM/CAL/ATR ownership from catalog and traceability outputs.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Create per-phase evidence indexes under `.scratch/verification/SPRINT-003/execution-2026-02-27/phase-*/README.md`.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Acceptance Criteria - Phase 0
- [ ] No unowned requirement IDs remain in the gap ledger.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Baseline evidence is reproducible from command tables and logs.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Phase 1 - Unified LLM Parity Closure
### Deliverables
- [ ] Verify provider resolution semantics (explicit provider/default/ambiguity errors) in `lib/unified_llm/main.tcl`.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify normalized message/content-part parity for `text`, `thinking`, `image_url`, `image_base64`, `image_path`, `tool_call`, `tool_result`.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify adapter translation parity across blocking and streaming in `lib/unified_llm/adapters/openai.tcl`, `lib/unified_llm/adapters/anthropic.tcl`, and `lib/unified_llm/adapters/gemini.tcl`.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify tool-call loop continuation semantics and deterministic round limits.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify structured output parity (`generate_object`, `stream_object`) with deterministic `INVALID_JSON` and `SCHEMA_MISMATCH` failures.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify usage/reasoning/caching normalization and `provider_options` validation behavior.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Test Matrix - Phase 1
Positive cases:
- Prompt-only and messages-only generation produce normalized outputs.
- Streaming event order is deterministic and equivalent to blocking content.
- Multimodal and tool loop flows are normalized consistently across providers.
- Structured object generation succeeds with valid schema-compatible content.

Negative cases:
- Prompt+messages conflict fails deterministically.
- Missing provider and ambiguous provider env fail deterministically.
- Invalid tool arguments fail deterministically.
- Invalid JSON and schema mismatch return deterministic structured output errors.

### Acceptance Criteria - Phase 1
- [ ] ULLM unit/integration parity coverage is green for OpenAI, Anthropic, Gemini.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] ULLM requirement IDs in traceability resolve to implementation/tests/evidence.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Phase 2 - Coding Agent Loop Parity Closure
### Deliverables
- [ ] Verify `ExecutionEnvironment` and `LocalExecutionEnvironment` contracts in `lib/coding_agent_loop/tools/core.tcl`.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify loop lifecycle semantics in `lib/coding_agent_loop/main.tcl` (completion, per-input rounds, turn limits, cancellation).
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify truncation marker behavior while preserving complete terminal output payloads.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify `steer` and `follow_up` queue injection semantics.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify required event-kind parity and loop-warning semantics.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify profile prompt construction and project-document discovery in `lib/coding_agent_loop/profiles/*.tcl`.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify subagent lifecycle parity (spawn/send_input/wait/close, shared env, independent history, depth limits).
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Acceptance Criteria - Phase 2
- [ ] CAL unit/integration parity coverage is green for lifecycle/tools/steering/subagents/events.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] CAL requirement IDs in traceability resolve to implementation/tests/evidence.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Phase 3 - Attractor Runtime Parity Closure
### Deliverables
- [ ] Verify DOT parser parity in `lib/attractor/main.tcl` for supported syntax, quoting, chained edges, defaults, and comment stripping.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify validation parity for start/exit invariants, reachability, edge validity, and deterministic rule/severity metadata.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify execution parity for handler resolution, edge routing priority, and checkpoint/resume equivalence.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify built-in handler parity for `start`, `exit`, `codergen`, `wait.human`, `conditional`, `parallel`, `fan-in`, `tool`, and `stack.manager_loop`.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify interviewer parity (`AutoApprove`, `Console`, `Callback`, `Queue`) and `wait.human` option routing behavior.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify condition expression and stylesheet specificity behavior.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify CLI contract parity in `bin/attractor` for `validate`, `run`, and `resume`.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Acceptance Criteria - Phase 3
- [ ] ATR unit/integration/e2e parity coverage is green for parser/validator/execution/handlers/interviewer/CLI.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] ATR requirement IDs in traceability resolve to implementation/tests/evidence.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Phase 4 - Cross-Runtime Integration Closure
### Deliverables
- [ ] Verify deterministic end-to-end flow across Attractor traversal, CAL codergen execution, and ULLM provider mocks.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify checkpoint persistence, resume behavior, artifact layout, and event stream integrity across runtime boundaries.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify provider-specific integrated fixture paths for OpenAI, Anthropic, and Gemini.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify CLI e2e success/failure exit-code assertions for `validate`, `run`, and `resume`.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Acceptance Criteria - Phase 4
- [ ] Offline `make test` execution is sufficient to validate integrated ULLM + CAL + ATR behavior.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Integration evidence indexes include commands, exit codes, and artifact paths for all scenarios.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Phase 5 - Traceability, ADR, and Closeout
### Deliverables
- [ ] Verify `docs/spec-coverage/traceability.md` closes all Sprint #003 mappings with implementation/test/evidence references.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Verify requirement catalog consistency with `tclsh tools/requirements_catalog.tcl --check-ids` and `--summary`.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Update `docs/ADR.md` with final Sprint #003 architecture decisions introduced in this implementation pass.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Run sprint docs/evidence lint checks for Sprint #003 planning and execution documents.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Render and verify all appendix mermaid diagrams with `mmdc`, storing outputs in `.scratch/diagram-renders/sprint-003/`.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Acceptance Criteria - Phase 5
- [ ] Traceability closure is complete and `tclsh tools/spec_coverage.tcl` returns a clean status.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Sprint closeout evidence is reproducible from phase README command tables.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Canonical Verification Command Set
- `timeout 180 make build`
- `timeout 180 make test`
- `timeout 180 tclsh tests/all.tcl -match *unified_llm*`
- `timeout 180 tclsh tests/all.tcl -match *coding_agent_loop*`
- `timeout 180 tclsh tests/all.tcl -match *attractor*`
- `timeout 180 tclsh tools/requirements_catalog.tcl --check-ids`
- `timeout 180 tclsh tools/requirements_catalog.tcl --summary`
- `timeout 180 tclsh tools/spec_coverage.tcl`
- `timeout 180 bash tools/evidence_lint.sh docs/sprints/SPRINT-003-close-spec-parity-tcl.md`
- `timeout 180 bash tools/evidence_lint.sh docs/sprints/SPRINT-003-implementation-plan.md`
- `timeout 180 bash tools/evidence_lint.sh docs/sprints/SPRINT-003-implementation-execution.md`

## Appendix - Mermaid Diagrams

### Core Domain Models
```mermaid
classDiagram
  class UnifiedLLMClient {
    +generate(req)
    +stream(req, onEvent)
    +generateObject(req, schema)
    +streamObject(req, schema, onObject)
  }

  class ProviderAdapter {
    +translateRequest(req)
    +complete(req)
    +stream(req, onEvent)
  }

  class CALSession {
    +submit(input)
    +steer(input)
    +followUp(input)
    +abort()
    +events()
  }

  class ExecutionEnvironment {
    +readFile(path)
    +writeFile(path, content)
    +applyPatch(patch)
    +execCommand(cmd)
  }

  class AttractorEngine {
    +parse(dot)
    +validate(ast)
    +run(ast)
    +resume(checkpoint)
  }

  UnifiedLLMClient --> ProviderAdapter
  CALSession --> UnifiedLLMClient
  CALSession --> ExecutionEnvironment
  AttractorEngine --> CALSession : codergen backend
```

### E-R Diagram
```mermaid
erDiagram
  SPRINT_RUN ||--o{ PHASE_RUN : contains
  PHASE_RUN ||--o{ VERIFY_COMMAND : executes
  PHASE_RUN ||--o{ EVIDENCE_ARTIFACT : emits
  TRACEABILITY_ROW }o--|| REQUIREMENT_ID : maps
  TRACEABILITY_ROW }o--|| TEST_CASE : verifies
  TRACEABILITY_ROW }o--|| IMPLEMENTATION_UNIT : points_to
```

### Workflow Diagram
```mermaid
flowchart TD
  A[Load requirement catalog] --> B[Build gap ledger]
  B --> C[Implement parity work]
  C --> D[Run unit/integration/e2e tests]
  D --> E[Capture evidence and exit codes]
  E --> F[Update traceability mappings]
  F --> G[Run coverage checks]
  G --> H{All requirements mapped and green?}
  H -->|No| C
  H -->|Yes| I[Sprint closeout]
```

### Data-Flow Diagram
```mermaid
flowchart LR
  SPEC[Spec docs] --> REQ[Requirements catalog]
  REQ --> PLAN[Sprint plan]
  PLAN --> CODE[lib and bin]
  CODE --> TESTS[unit integration e2e]
  TESTS --> EVIDENCE[.scratch verification artifacts]
  EVIDENCE --> TRACE[traceability matrix]
  TRACE --> COVERAGE[spec coverage check]
```

### Architecture Diagram
```mermaid
flowchart TB
  subgraph Interfaces
    CLI[bin/attractor]
    TOOLS[tools/spec_coverage.tcl]
  end

  subgraph Runtime
    ATR[lib/attractor/main.tcl]
    CAL[lib/coding_agent_loop/main.tcl]
    ULLM[lib/unified_llm/main.tcl]
    CORE[lib/attractor_core/core.tcl]
  end

  subgraph Adapters
    OA[lib/unified_llm/adapters/openai.tcl]
    AN[lib/unified_llm/adapters/anthropic.tcl]
    GM[lib/unified_llm/adapters/gemini.tcl]
  end

  subgraph Verification
    TESTSUITE[tests/all.tcl]
    MOCK[tests/support/mock_http_server.tcl]
    TRACE[docs/spec-coverage/traceability.md]
  end

  CLI --> ATR
  ATR --> CAL
  ATR --> ULLM
  ATR --> CORE
  CAL --> ULLM
  ULLM --> OA
  ULLM --> AN
  ULLM --> GM
  TESTSUITE --> ATR
  TESTSUITE --> CAL
  TESTSUITE --> ULLM
  MOCK --> ULLM
  TOOLS --> TRACE
```
