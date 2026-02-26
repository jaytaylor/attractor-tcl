Legend: [ ] Incomplete, [X] Complete

# Sprint #003 - Close Full Spec Parity (Unified LLM + Coding Agent Loop + Attractor)

## Objective
Deliver a Tcl 8.5+ implementation that matches the behavior required by:
- `unified-llm-spec.md`
- `coding-agent-loop-spec.md`
- `attractor-spec.md`

Success is declared only when:
- The Sprint #002 spec-derived requirement catalog is green (no uncovered requirements).
- Every requirement has mapping evidence (impl/tests/verify) in `docs/spec-coverage/traceability.md`.
- The full deterministic test suite passes (`make -j10 test`) and includes explicit positive + negative cases for each major spec feature.

## Context & Problem
The current Tcl implementation is a functional baseline with deterministic tests, but it intentionally compresses many spec behaviors into coarse “coverage IDs” and simplified runtime semantics. This sprint closes the gap by implementing the missing behavior and expanding tests so “green” means “spec-complete”.

## Evidence + Verification Logging Plan
- Store all phase evidence under `.scratch/verification/SPRINT-003/<phase>/...` (unit logs, integration logs, e2e logs, fixture inputs, rendered diagrams).
- Each phase directory should include a short `README.md` index listing:
  - the verification commands that were executed
  - the captured exit codes
  - the paths to the relevant artifacts
- Keep offline deterministic tests as the default; “live API key smoke tests” (if any) must be clearly separated and never required for `make -j10 test`.

## Prerequisites
- Sprint #002 must land first, so we have a spec-derived requirement catalog and completeness enforcement.

## Execution Order
1. Phase 0: ADR alignment + harness
2. Phase 1: Unified LLM parity
3. Phase 2: Coding Agent Loop parity
4. Phase 3: Attractor parity
5. Phase 4: Cross-spec integration + e2e closure
6. Phase 5: Documentation + closeout

## Current State Snapshot (Verified 2026-02-26)
- [ ] Baseline tests pass.
```text
Verification:
- `make -j10 test` (exit code 0)
Evidence:
- `.scratch/verification/SPRINT-003/baseline/make-test.log`
Notes:
- {placeholder for verification justification/reasoning and evidence log}
```
- [ ] Baseline coverage tool is green under the *current* traceability scheme.
```text
Verification:
- `tclsh tools/spec_coverage.tcl` (exit code 0)
Evidence:
- `.scratch/verification/SPRINT-003/baseline/spec-coverage.log`
Notes:
- {placeholder for verification justification/reasoning and evidence log}
```
- [ ] Baseline spec parity audit exists and is referenced from this sprint (lists the largest behavior gaps).
```text
Verification:
- `test -f .scratch/verification/SPRINT-003/baseline/parity-audit.md` (exit code 0)
Evidence:
- `.scratch/verification/SPRINT-003/baseline/parity-audit.md`
Notes:
- {placeholder for verification justification/reasoning and evidence log}
```

## Scope
In scope:
- Implement missing MUST/REQUIRED behaviors in all three runtimes.
- Expand unit/integration/e2e coverage until parity is proven by tests (offline deterministic by default).
- Ensure CLI workflows cover validate/run/resume requirements.
- Update traceability mappings as requirements are closed.

Out of scope:
- UI/TUI/IDE frontends (event stream consumers are out of scope; the event contract is in scope)
- Backwards compatibility with today’s simplified behavior (this sprint may change APIs to match specs)

## Deliverables
### Phase 0 - Architecture Alignment + ADRs
- [ ] Record an ADR for any material architecture decisions required to close parity (streaming/event model, concurrency approach, DOT parsing strategy).
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Create a parity test harness plan under `.scratch/verification/SPRINT-003/harness/` describing how provider mocks, SSE fixtures, and offline deterministic tests are structured.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Acceptance Criteria - Phase 0
- [ ] ADRs exist for the core design choices and are referenced by this sprint.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Phase 1 - Unified LLM Parity
- [ ] Implement the full message/content model required by the spec (roles, content parts, tool calls/results, thinking blocks) and update adapters accordingly.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement multimodal content parts (image URL, image base64, local image path) with per-provider translation or deterministic “unsupported” errors.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement real provider adapters that speak native APIs via HTTP (OpenAI Responses, Anthropic Messages, Gemini generateContent) while keeping deterministic offline tests via a local mock server.
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- OpenAI: `/v1/responses`
- Anthropic: `/v1/messages`
- Gemini: `/v1beta/models/*:generateContent`
- [ ] Implement streaming as a first-class API producing start/delta/end style events (and ensure middleware can observe streaming).
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement reasoning/thinking token reporting and reasoning effort pass-through for each provider where supported.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement prompt caching usage fields and provider-specific caching hooks as specified (ensuring deterministic offline coverage for usage field extraction).
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement tool calling semantics including active/passive tools, max tool rounds enforcement, and batched tool-result continuation requests.
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- active vs passive tools
- max tool rounds enforcement
- batch tool-results continuation requests
- [ ] Implement structured output (`generate_object`, `stream_object`) with schema validation and deterministic negative failure paths.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement provider-specific escape hatches (`provider_options`) and required headers (e.g., Anthropic beta headers) without leaking provider details into the unified surface.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement error typing and translation (configuration errors, auth errors, retryable errors) so callers can make correct decisions.
```text
{placeholder for verification justification/reasoning and evidence log}
```

#### Test Matrix - Phase 1 (Explicit)
Positive cases to cover:
- Generate with `prompt`
- Generate with `messages`
- Reject when both prompt + messages are provided
- Streaming emits STREAM_START, one-or-more deltas, and FINISH; concatenated deltas equal blocking output
- Image input (URL)
- Image input (base64)
- Image input (local file path)
- Tool loop:
  - single tool call
  - multiple tool calls in one response
  - continuation request includes all tool results in one payload
- Structured output success (valid JSON matching schema)
- Provider-specific options pass through and are visible to the adapter layer

Negative cases to cover:
- Unknown tool call produces error tool result (not an exception)
- Tool execute handler throws -> error tool result
- Structured output invalid JSON -> deterministic error type
- Structured output schema mismatch -> deterministic error type
- Provider header/options validation fails fast for malformed provider_options

### Acceptance Criteria - Phase 1
- [ ] The parity matrix tests for OpenAI/Anthropic/Gemini pass using deterministic provider mocks and confirm native endpoint usage.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Phase 2 - Coding Agent Loop Parity
- [ ] Implement an explicit `ExecutionEnvironment` interface and `LocalExecutionEnvironment` reference implementation that provides file and process operations.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Align tool output truncation defaults and markers to the spec, and allow overrides via `SessionConfig`.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Align command execution max-duration defaults and per-call overrides to the spec, including deterministic cancellation semantics.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement the session loop semantics including natural completion, per-input tool round limit, session turn limits, and abort/cancellation behavior.
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- natural completion
- per-input tool round limit
- session turn limits
- abort/cancellation behavior
- [ ] Implement steering semantics (`steer`, `follow_up`) matching the spec’s queue/injection behavior, not just event emission.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement event system parity: emit all required event kinds and ensure TOOL_CALL_END retains full output.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement provider profiles that generate full system prompts including identity/tool guidance, environment context, and project doc discovery.
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- identity + tool usage guidance
- environment context (platform/git/cwd/date)
- project doc discovery (AGENTS + provider-specific)
- [ ] Implement subagents with depth limiting and independent history, sharing the same execution environment.
```text
{placeholder for verification justification/reasoning and evidence log}
```

#### Test Matrix - Phase 2 (Explicit)
Positive cases to cover:
- Simple file create task across profiles using mocked Unified LLM
- Shell max-duration produces deterministic cancellation marker and event sequence
- Tool output truncation marker appears and full output preserved in TOOL_CALL_END
- Steering injected after a tool round changes the next model request
- Subagent lifecycle: spawn -> send_input -> wait -> close

Negative cases to cover:
- Unknown tool call -> error tool result and loop continues
- Invalid tool argument schema -> error tool result, includes schema_error payload
- Depth limit prevents recursive spawning

### Acceptance Criteria - Phase 2
- [ ] Cross-provider parity tests exist for each profile and validate tool-format expectations (apply_patch vs edit_file, etc.).
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Phase 3 - Attractor Parity
- [ ] Implement a DOT parser that accepts the supported subset, including multi-line attribute blocks, chaining, default blocks, quoting, and comment stripping.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement linting/validation parity including start/exit invariants, reachability checks, edge validity, and severity/rule metadata.
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- exactly one start (shape=Mdiamond) and one exit (shape=Msquare)
- reachability checks
- edge references must be valid
- severity (error vs warning) and rule naming
- [ ] Implement execution engine parity including shape-to-handler mapping, edge selection priority, goal gates/routing, and checkpoint/resume equivalence.
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- shape-to-handler mapping with `type` override
- edge selection priority rules
- goal gates and retry routing rules
- checkpoint/resume producing equivalent outcomes
- [ ] Implement handler parity (start/exit/codergen/wait.human/conditional/parallel/fan-in/tool/stack.manager_loop) and ensure each is test-covered with deterministic fixtures.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement condition expression language parity (`=`, `!=`, `&&`, `outcome`, `preferred_label`, `context.*`).
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement model stylesheet parsing and specificity rules, applying overrides correctly.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Implement transforms and extensibility hooks (AST transforms + custom handler registration).
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Ensure CLI parity for validate/run/resume and artifacts are emitted in the required on-disk layout.
```text
{placeholder for verification justification/reasoning and evidence log}
```

#### Test Matrix - Phase 3 (Explicit)
Positive cases to cover:
- Parse and validate a linear pipeline
- Parse chained edges and multi-line node attrs
- Execute linear pipeline and produce status.json + prompt.md/response.md
- Goal gate blocks exit until satisfied
- Checkpoint/resume yields same completion and artifacts
- Wait.human offers edge labels and routes on selection

Negative cases to cover:
- Missing start node -> validation error
- Missing exit node -> validation error
- Orphan node -> warning (and reported with rule metadata)
- Invalid condition expression -> validation error

### Acceptance Criteria - Phase 3
- [ ] The Attractor parity matrix tests exist and cover each handler class and routing/validation rule.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Phase 4 - Cross-Spec Integration + E2E Closure
- [ ] Add an end-to-end deterministic pipeline test that exercises traversal, codergen via Coding Agent Loop, Unified LLM mocks, plus artifacts/events/checkpoints.
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- Attractor engine traversal
- codergen handler backed by Coding Agent Loop
- Coding Agent Loop backed by Unified LLM mocks
- artifacts, events, and checkpoints
- [ ] Add CLI e2e tests for validate/run/resume that validate exit codes and artifact output contracts.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Acceptance Criteria - Phase 4
- [ ] Running `make -j10 test` is sufficient to prove spec parity in offline mode.
```text
Verification:
- `make -j10 test` (exit code 0)
Evidence:
- `.scratch/verification/SPRINT-003/phase-4/make-test.log`
Notes:
- {placeholder for verification justification/reasoning and evidence log}
```

### Phase 5 - Documentation + Closeout
- [ ] Update `docs/spec-coverage/traceability.md` to reflect final mappings for every requirement ID.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Update `docs/ADR.md` with any final follow-up ADRs required by implementation tradeoffs.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Acceptance Criteria - Phase 5
- [ ] Sprint documentation contains no placeholder TODOs and all evidence references resolve.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Appendix - Mermaid Diagrams (Verify Render With mmdc)

### Core Domain Models
```mermaid
%% Source: .scratch/diagrams/sprint-003/domain.mmd
classDiagram
  class UnifiedLLMClient {
    +providers
    +middleware
    +complete()
    +stream()
    +generate()
    +generate_object()
  }
  class ProviderAdapter {
    +name
    +complete()
    +stream()
  }
  class CALSession {
    +profile
    +env
    +history
    +events
    +submit()
    +steer()
    +follow_up()
  }
  class ExecutionEnvironment {
    +read_file()
    +write_file()
    +edit_file()
    +apply_patch()
    +shell()
  }
  class AttractorEngine {
    +parse_dot()
    +validate()
    +run()
    +resume()
  }

  UnifiedLLMClient --> ProviderAdapter
  CALSession --> UnifiedLLMClient
  CALSession --> ExecutionEnvironment
  AttractorEngine --> CALSession : codergenBackend
```

### E-R Diagram
```mermaid
%% Source: .scratch/diagrams/sprint-003/er.mmd
erDiagram
  RUN ||--o{ NODE_RUN : contains
  RUN ||--|| CHECKPOINT : snapshots
  NODE_RUN ||--o{ ARTIFACT : writes
  CAL_SESSION ||--o{ TURN : contains
  TURN ||--o{ TOOL_INVOCATION : triggers
  TOOL_INVOCATION ||--|| TOOL_RESULT : produces
```

### Workflow Diagram
```mermaid
%% Source: .scratch/diagrams/sprint-003/workflow.mmd
flowchart TD
  DOT[DOT pipeline] --> PARSE[Parse/transform]
  PARSE --> LINT[Validate/lint]
  LINT -->|errors| STOP[Return diagnostics]
  LINT -->|ok| RUN[Traverse graph]
  RUN --> NODE[Execute handler]
  NODE -->|codergen| CAL[Coding Agent Loop]
  CAL -->|LLM| ULLM[Unified LLM]
  ULLM --> CAL
  NODE --> CKPT[Write checkpoint + artifacts]
  CKPT --> RUN
```

### Data-Flow Diagram
```mermaid
%% Source: .scratch/diagrams/sprint-003/dataflow.mmd
flowchart LR
  INPUT[User + DOT] --> ATTR[Attractor]
  ATTR --> OUTCOME[Outcomes]
  ATTR --> ARTIFACTS[Artifacts + checkpoints]
  ATTR --> EVENTS[Event stream]
  ATTR --> CAL[Agent loop]
  CAL --> ULLM[Unified LLM]
  ULLM --> CAL
```

### Architecture Diagram
```mermaid
%% Source: .scratch/diagrams/sprint-003/arch.mmd
flowchart TB
  subgraph CLI
    BIN_ATR[bin/attractor]
  end
  subgraph Runtime
    ATR[lib/attractor]
    CAL[lib/coding_agent_loop]
    ULLM[lib/unified_llm]
    CORE[lib/attractor_core]
  end
  subgraph Verification
    TESTS[tests/all.tcl]
    MOCK[tests/support/mock_http_server.tcl]
    COV[tools/spec_coverage.tcl]
  end

  BIN_ATR --> ATR
  ATR --> CAL
  ATR --> ULLM
  CAL --> ULLM
  ULLM --> CORE
  ATR --> CORE
  TESTS --> ATR
  TESTS --> CAL
  TESTS --> ULLM
  MOCK --> ULLM
  COV --> TESTS
```
