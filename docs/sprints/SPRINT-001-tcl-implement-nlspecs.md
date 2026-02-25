# Sprint #001 - Implement Attractor NLSpecs In Tcl (100% Spec Coverage)

Legend: `[ ]` Incomplete, `[X]` Complete

Evidence bar (copied from the golden sample): every checked item MUST include:
- The exact verification command(s) wrapped in backticks
- The exit code(s)
- References to artifacts (logs, `.scratch` transcripts, captured outputs) stored under `.scratch/verification/SPRINT-001/...`

## Objective
Implement all NLSpecs in this repository in Tcl:
- [attractor-spec.md](../../attractor-spec.md)
- [coding-agent-loop-spec.md](../../coding-agent-loop-spec.md)
- [unified-llm-spec.md](../../unified-llm-spec.md)

Success means:
- 100% coverage of each spec's "Definition of Done" checklist (Attractor: Section 11, Agent Loop: Section 9, Unified LLM: Section 8).
- A traceable spec-to-tests matrix proving coverage (not just high unit test line coverage).
- A runnable, documented Tcl implementation with deterministic tests.

## Scope
In scope:
- A working Tcl implementation of all three specs (library + minimal CLIs) suitable as a foundation for a "software factory".
- Deterministic test suite with local mocks for providers; live-provider smoke tests gated by env vars.
- A spec coverage system (traceability) proving completeness.

Out of scope (unless required by the specs):
- A polished TUI/GUI/IDE integration (we expose event streams/hooks; UI is a separate concern).
- Production-grade multi-tenant HTTP service (Attractor HTTP server mode is optional per spec; if implemented, it is minimal).
- Packaging for every Tcl distribution system (TEA/teapot). We focus on repo-local packages first.

## Current State Snapshot
This repository currently contains NLSpecs only (no Tcl implementation yet). The sprint delivers the initial Tcl implementation from scratch, plus tests and examples.

## Constraints, Assumptions, And Targets
- **Language/runtime target:** Tcl 8.5+ (current environment shows `tclsh 8.5.9`; no TclOO). Prefer pure Tcl + tcllib; use `snit` if OO helps.
- **Available deps (already present in this environment):** `http`, `tls`, `json`, `yaml`, `base64`, `sha1`, `md5`, `snit`, `Thread`, and CLI tools `curl`, `jq`, `rg`, `dot`.
- **Async model mapping:** Specs use "async iterator" language. In Tcl, implement streaming as:
  - Callback/event-driven streaming APIs (push), plus
  - A "pull" test harness that buffers events for deterministic assertions.
- **Provider networking:** Use TLS-enabled `http` for HTTPS calls.
- **Spec coverage definition:** "100%" means every checkbox in each spec's DoD section is green with evidence, and every MUST/SHALL requirement is either implemented or explicitly documented as out-of-scope only where the spec itself marks it optional (e.g., Attractor HTTP server mode: "if implemented").
- **Security/privacy default:** never log API keys or secrets; redact known secret patterns in logs and error messages; keep `.scratch/verification` artifacts safe for sharing.

## Golden Sample Review (SPRINT-047-google-oauth.md)
This sprint plan should match the quality bar demonstrated by `~/src/ai-digital-twin2/docs/sprints/SPRINT-047-google-oauth.md`.

What the golden sample does well (copy these patterns):
- **Execution order + dependency-aware tracks.** It explicitly sequences tracks (A->B->C...), preventing churn.
- **Checklist items with verifiable evidence.** Each item defines positive + negative tests and where logs live.
- **Clear "scope per item".** Items state touched components and expected behavior, which makes parallel work safe.
- **Artifacts discipline.** It standardizes `.scratch/verification/...` as the source of truth for completion.
- **Acceptance matrices.** Parity matrices force coverage across multiple variants (providers, paths, failure cases).
- **Non-happy-path emphasis.** Negative tests are first-class deliverables, not afterthoughts.

Potential improvements to the golden sample (avoid these pitfalls here):
- Keep critical checklists **untruncated** and easy to grep (avoid burying key requirements inside long prose).
- Prefer "why this matters" notes only where they prevent mistakes; otherwise keep items crisp.
- Ensure any "current models" references are **data-driven** (a catalog file) to avoid staleness.

## Proposed Repository Layout
Create three Tcl packages plus a small shared core:
- `lib/attractor/` (Attractor pipeline runner)
- `lib/unified_llm/` (Unified LLM client SDK)
- `lib/coding_agent_loop/` (Coding Agent Loop library)
- `lib/attractor_core/` (shared utils: logging, JSON helpers, schema validation, SSE parsing)

Top-level:
- `bin/attractor` CLI entrypoint
- `bin/agentloop_smoke` optional small driver for Coding Agent Loop smoke runs
- `tests/` unit + integration + e2e tests
- `examples/` DOT pipelines and agent loop examples
- `docs/` additional usage docs as needed

Suggested file breakdown (non-binding, but reduces bikeshedding):
- `lib/unified_llm/client.tcl`, `lib/unified_llm/highlevel.tcl`, `lib/unified_llm/errors.tcl`
- `lib/unified_llm/adapters/openai.tcl`, `lib/unified_llm/adapters/anthropic.tcl`, `lib/unified_llm/adapters/gemini.tcl`
- `lib/unified_llm/streaming/sse.tcl`, `lib/unified_llm/streaming/accumulator.tcl`
- `lib/coding_agent_loop/session.tcl`, `lib/coding_agent_loop/events.tcl`, `lib/coding_agent_loop/profiles/*.tcl`
- `lib/coding_agent_loop/tools/*.tcl` (read_file/write_file/edit_file/apply_patch/shell/grep/glob/subagents)
- `lib/attractor/dot/*.tcl` (tokenize/parse/stylesheet)
- `lib/attractor/engine/*.tcl` (runner/state/handlers/interviewer/events)

## Public API Contracts (Tcl)
These are the intended "stable surfaces" for downstream consumers (CLIs, UIs, other tools). Keep them small and versioned.

Unified LLM (`package require unified_llm`):
- `::unified_llm::set_default_client $client_cmd`
- `::unified_llm::default_client` -> client cmd (lazy `from_env` init)
- `::unified_llm::generate args...` -> dict (GenerateResult)
- `::unified_llm::stream args... -on_event $cmdPrefix` -> stream handle
- `::unified_llm::generate_object args...` -> dict
- `::unified_llm::stream_object args... -on_object $cmdPrefix` -> stream handle
- Client object command:
  - `$client complete $requestDict`
  - `$client stream $requestDict -on_event $cmdPrefix`
  - `$client close`

Coding Agent Loop (`package require coding_agent_loop`):
- `::coding_agent_loop::session new -profile $profileCmd -env $envCmd ?-config $dict?` -> session cmd
- `$session submit $text` (blocking by default; optionally `-async 1`)
- `$session steer $text`
- `$session follow_up $text`
- `$session events -on_event $cmdPrefix` (subscribe) and `$session close`

Attractor (`package require attractor`):
- `::attractor::parse_dot $dotSource` -> graph dict
- `::attractor::validate $graphDict` -> list of diagnostics
- `::attractor::run $graphDict ?-backend $codergenBackendCmd? ?-interviewer $interviewerCmd? ...` -> final outcome dict
- `::attractor::runner new ...` -> runner cmd for event subscription / incremental control

Note: object commands above can be implemented via `snit` or command-prefix closures; prefer whichever is simplest in Tcl 8.5.

## High-Level Architecture

### Attractor (Pipeline Runner)
```mermaid
flowchart LR
  DOT[.dot file] --> PARSE[Parse DOT subset]
  PARSE --> XFORM[Transforms: stylesheet + $goal expansion]
  XFORM --> VALIDATE[Lint/Validate -> Diagnostics]
  VALIDATE -->|errors| STOP[Refuse to execute]
  VALIDATE -->|ok| INIT[Init run dir + context + checkpoint]
  INIT --> EXEC[Execute traversal loop]
  EXEC -->|events| OBS[Observers / UI / logs]
  EXEC --> FINAL[Finalize + checkpoint]
```

### Unified LLM Client (SDK)
```mermaid
flowchart TD
  API[generate/stream/generate_object] --> CLIENT[Client: routing + middleware]
  CLIENT --> ADAPTERS[Provider adapters]
  ADAPTERS -->|HTTPS| OPENAI[OpenAI Responses API]
  ADAPTERS -->|HTTPS| ANTH[Anthropic Messages API]
  ADAPTERS -->|HTTPS| GEM[Gemini API]
  API --> TOOLS[Tool loop: parallel execution + batching]
```

### Coding Agent Loop
```mermaid
flowchart TD
  HOST[Host app] -->|submit| SESSION[Session.process_input]
  SESSION -->|Request| ULLM[Unified LLM Client.complete/stream]
  ULLM -->|tool calls| TOOLS[ToolRegistry -> ExecutionEnvironment]
  TOOLS -->|ToolResult| SESSION
  SESSION -->|events| HOST
  SESSION --> SUBAGENTS[spawn_agent tool]
```

## Domain Model (Mermaid)

### Attractor Core Types
```mermaid
classDiagram
  class Graph {
    +string id
    +dict graph_attrs
    +dict nodes
    +list edges
  }
  class Node {
    +string id
    +dict attrs
  }
  class Edge {
    +string from
    +string to
    +dict attrs
  }
  class Context {
    +dict values
  }
  class Outcome {
    +string status
    +string preferred_label
    +list suggested_next_ids
    +dict context_updates
    +string notes
    +string failure_reason
  }
  class Checkpoint {
    +string timestamp
    +string current_node
    +list completed_nodes
    +dict node_retries
    +dict context_values
  }
  Graph --> Node
  Graph --> Edge
  Node --> Outcome
  Context --> Outcome
  Checkpoint --> Context
```

### Unified LLM Core Types
```mermaid
classDiagram
  class Client
  class ProviderAdapter
  class Request
  class Response
  class Message
  class ContentPart
  class Tool
  class ToolCall
  class ToolResult
  class StreamEvent
  Client --> ProviderAdapter
  Client --> Request
  Client --> Response
  Response --> Message
  Message --> ContentPart
  Request --> Tool
  Response --> ToolCall
  ToolCall --> ToolResult
  StreamEvent --> Response
```

## Spec Coverage Strategy (Non-Negotiable)
To claim 100% NLSpec coverage, we will build a traceability system:
- Extract each spec's DoD checkbox into a stable requirement ID (e.g., `ATR-DOD-11.3-EdgeSelection`, `CAL-DOD-9.5-TruncationOrder`, `ULLM-DOD-8.7-ParallelTools`).
- Extract all `MUST` / `MUST NOT` / `REQUIRED` statements into requirement IDs (e.g., `ULLM-REQ-2.7-NativeAPI`, `CAL-REQ-5.3-CharTruncFirst`).
- Maintain `docs/spec-coverage/traceability.md` mapping:
  - Requirement ID -> implementation file(s) -> test file(s) -> verification command(s).
- Add a `tools/spec_coverage.tcl` script that:
  - Parses the traceability file
  - Fails CI if any requirement is missing tests
  - Emits a coverage report summary

Traceability file format (keep it grep-friendly):
- One requirement per block with stable keys:
  - `id:`
  - `spec:` (file + section anchor)
  - `impl:` (file paths)
  - `tests:` (file paths)
  - `verify:` (commands)

Requirement ID conventions:
- `ULLM-DOD-8.x-*` for Unified LLM DoD checkboxes
- `CAL-DOD-9.x-*` for Coding Agent Loop DoD checkboxes
- `ATR-DOD-11.x-*` for Attractor DoD checkboxes
- `ULLM-REQ-*`, `CAL-REQ-*`, `ATR-REQ-*` for MUST/REQUIRED statements not already in DoD lists

## Tricky Rules Cheat Sheet (Implementer Guardrails)
These are common sources of subtle non-compliance; treat them as "must get right the first time":

Unified LLM:
- Middleware execution order: request in registration order, response in reverse order (onion model).
- Tool loop parallelism: execute all N calls concurrently, then send all N results back in a single continuation request (preserve ordering).
- OpenAI adapter: Responses API required for reasoning token reporting; do not silently downgrade to Chat Completions.

Coding Agent Loop:
- Tool output truncation order is mandatory: character truncation FIRST, line truncation SECOND; TOOL_CALL_END must carry full output.
- Shell timeout handling must be killable: SIGTERM then SIGKILL after 2 seconds (process group).
- Unknown tool calls return error ToolResult (model can recover); do not throw.

Attractor:
- Edge selection priority order: condition match -> preferred label -> suggested IDs -> highest weight -> lexical tiebreak.
- Start/exit resolution must match spec (shape-based first; id fallback); enforce no incoming edges to start, no outgoing edges from exit.
- Fidelity precedence: edge fidelity > node fidelity > graph default_fidelity > compact; full fidelity requires thread key resolution.
- Checkpoint resume must perform the one-hop fidelity degrade when prior node was full fidelity (in-memory sessions not serializable).

## Test Harness Approach (Provider Mocks)
Provider adapters MUST be testable without real API keys.
Plan:
- Implement a tiny HTTP test server in Tcl under `tests/support/mock_http_server.tcl`.
- It should support:
  - Request capture (method/path/headers/body)
  - Scripted responses (JSON) and scripted streaming (SSE frames / chunked JSON)
  - Per-route assertions (e.g., "OpenAI adapter used /v1/responses", "Anthropic alternation was fixed up")
- Tests should:
  - Run entirely offline by default
  - Gate live-provider tests behind env vars and mark them as "smoke" only

## On-Disk Contracts (Attractor)
Attractor is required to produce a stable run directory structure for auditability and resume:
```
{logs_root}/
  manifest.json
  checkpoint.json
  artifacts/
    {artifact_id}.json
  {node_id}/
    status.json
    prompt.md
    response.md
```

`status.json` must align with the spec's Status File Contract (Appendix C in attractor-spec.md). Internally we can use `preferred_label`, but the on-disk contract uses `preferred_next_label`; explicitly map between them and accept both when reading for forward/backward compatibility.

## Event Taxonomy (Minimal Shapes)
Keep events as plain Tcl dicts so host apps can consume them without object coupling.

Unified LLM streaming events:
- Emit spec StreamEventType names (STREAM_START, TEXT_DELTA, TOOL_CALL_END, FINISH, ERROR, etc.) with fields from unified-llm-spec.md Section 3.13/3.14.

Coding Agent Loop session events:
- Emit the DoD-required events from coding-agent-loop-spec.md (Section 2.9/9.10) with at least:
  - `SESSION_START`, `SESSION_END`
  - `USER_INPUT`
  - `ASSISTANT_TEXT_END`
  - `TOOL_CALL_START`, `TOOL_CALL_END` (TOOL_CALL_END must include full untruncated output)
  - `STEERING_INJECTED`, `LOOP_DETECTION`, `TURN_LIMIT`, `WARNING`

Attractor pipeline events:
- Emit the pipeline/stage/parallel/human/checkpoint events described in attractor-spec.md Section 9.6.

## Evidence Directory Convention
Standardize where proof lives so "100% coverage" is auditable:
- `.scratch/verification/SPRINT-001/attractor/...`
- `.scratch/verification/SPRINT-001/unified_llm/...`
- `.scratch/verification/SPRINT-001/coding_agent_loop/...`
- `.scratch/verification/SPRINT-001/integration/...`

Each checklist item marked `[X]` must link to at least one artifact in those folders.

## Execution Order (Tracks)
This plan is dependency-ordered to minimize rewrites:
1. Track A - Scaffolding and shared utilities
2. Track B - Unified LLM Client (foundation for the agent loop)
3. Track C - Coding Agent Loop
4. Track D - Attractor pipeline runner
5. Track E - Integration, e2e, and coverage closure

## Implementation Plan Refresh (2026-02-25)
This is the initial sprint plan for this repository. When reality diverges, do not rewrite history: append a new dated "refresh" section describing:
- what changed
- why it changed
- what is now the critical path

## Evidence + Verification Logging Plan
Carry the golden sample's "auditability" discipline forward:
- Every `[X]` line must include at least one concrete verification command and at least one artifact path under `.scratch/verification/SPRINT-001/...`.
- Prefer timeboxed verification commands so CI/humans don't hang:
  - Use `perl -e 'alarm 60; exec @ARGV' <cmd...>` as the default cross-platform timeout wrapper.
  - If `timeout` is available, it's fine too, but use one convention consistently.
- Standardize log capture:
  - `bash -lc '<cmd> 2>&1 | tee <logpath>; printf \"exit_code=%d\\n\" ${PIPESTATUS[0]} >> <logpath>'`
  - For negative tests, record the expected non-zero exit code explicitly in the log.
- Add (and then use everywhere) a tiny helper script:
  - `tools/verify_cmd.sh` (runs a command, tees output to a log, appends exit_code=, returns the command's exit code)

## Track A - Project Scaffolding (Tcl Packages + Test Harness)
- [ ] **A0 - Baseline notes (scope + environment)**
  - Deliverables:
    - `.scratch/notes/sprint-001-baseline.md` capturing: Tcl version, available packages, OS, and any known limitations (no TclOO, streaming approach, etc.)
  - Verification:
    - `test -f .scratch/notes/sprint-001-baseline.md` (exit 0)

- [ ] **A1 - Package scaffolding**
  - Deliverables:
    - `pkgIndex.tcl` at repo root
    - `lib/{attractor,unified_llm,coding_agent_loop,attractor_core}/...` with `package provide`
    - `tests/all.tcl` driving `tcltest` across all test files
  - Verification:
    - `tclsh tests/all.tcl` (exit 0)

- [ ] **A2 - Shared utilities**
  - Deliverables (in `lib/attractor_core/`):
    - JSON encode/decode helpers (wrapping `::json::*`)
    - Minimal JSON Schema validator (object/properties/required/type/enum) for tool args + structured output
    - SSE parser (for provider streaming)
    - Cross-platform process exec helper (timeout + kill semantics)
  - Verification:
    - `tclsh tests/all.tcl -match attractor_core-*` (exit 0)

- [ ] **A3 - `.scratch` evidence scaffolding**
  - Deliverables:
    - `.scratch/verification/SPRINT-001/README.md` describing evidence rules
  - Verification:
    - `test -f .scratch/verification/SPRINT-001/README.md` (exit 0)

- [ ] **A4 - CI smoke workflow**
  - Deliverables:
    - A minimal CI job (GitHub Actions or equivalent) that runs: `tclsh tests/all.tcl`
    - A separate job (manual trigger) for live-provider smoke tests, gated by secrets.
  - Verification:
    - CI run link (captured in `.scratch/verification/SPRINT-001/ci/...`)

- [ ] **A5 - Plan guardrails (docs lint + evidence lint)**
  - Deliverables:
    - `tools/docs_lint.sh` that fails on: `T[O]DO`, `{placeholder`, and missing required headings in sprint docs
    - `tools/evidence_lint.sh` that fails if any `[X]` item in this sprint doc lacks a `.scratch/verification/SPRINT-001/...` reference
  - Verification:
    - `bash tools/docs_lint.sh` (exit 0)
    - `bash tools/evidence_lint.sh docs/sprints/SPRINT-001-tcl-implement-nlspecs.md` (exit 0)

### Acceptance Criteria - Track A
- [ ] From a clean checkout, `tclsh tests/all.tcl` passes and produces deterministic output.
- [ ] Baseline notes exist and capture known constraints/assumptions for Tcl 8.5 implementation.
- [ ] `tools/docs_lint.sh` passes and `tools/evidence_lint.sh` passes on this sprint plan.
- [ ] CI runs `tclsh tests/all.tcl` on PRs (and optionally runs live-provider smoke tests only when explicitly enabled).

## Track B - Unified LLM Client (unified-llm-spec.md)

### B0 - Requirements Indexing
- [ ] **B0.1 - Build ULLM traceability map**
  - Deliverables:
    - Requirement IDs for ULLM DoD 8.1-8.10 + MUST statements
    - Initial `docs/spec-coverage/traceability.md` skeleton
  - Verification:
    - `rg "ULLM-" docs/spec-coverage/traceability.md` (exit 0)

### B1 - Core Client + Data Model
- [ ] **B1.1 - Data model types (Message/ContentPart/Request/Response/etc.)**
  - Notes:
    - Use Tcl dicts as records; provide constructors/accessors mirroring spec (e.g., `Message.system`, `Response.text`).
    - Ensure role mapping is explicit (SYSTEM/USER/ASSISTANT/TOOL/DEVELOPER).
  - Tests:
    - Round-trip tests for tool calls/results and thinking blocks.

- [ ] **B1.2 - Error hierarchy**
  - Deliverables:
    - `SDKError` base + all subclasses in spec (ProviderError and children, NetworkError, AbortError, etc.)
    - HTTP status -> error mapping + retryable flags + Retry-After parsing.

- [ ] **B1.3 - Client routing + middleware**
  - Deliverables:
    - `Client.from_env`
    - Adapter registry + default provider resolution (never guess)
    - Middleware chain order (request forward, response reverse), including streaming middleware wrapping.
    - Module-level default client (`set_default_client`, lazy `from_env` on first use)

- [ ] **B1.4 - RateLimitInfo + usage math**
  - Deliverables:
    - Parse provider rate limit headers into RateLimitInfo when present
    - `Usage` supports addition for multi-step totals (None treated as 0 for optional fields)

### B2 - Provider Utilities
- [ ] **B2.1 - HTTP helper**
  - Requirements:
    - TLS
    - timeouts (connect/request/stream_read) mapped to Tcl http behaviors
    - header capture for rate limit fields
    - request/response logging hooks with secret redaction

- [ ] **B2.2 - SSE parser + stream accumulator**
  - Requirements:
    - Correct SSE framing (event/data/retry/comments/blank lines)
    - StreamEvent normalization: start/delta/end pattern; FINISH includes usage + response.

### B3 - Provider Adapters (Native APIs)
- [ ] **B3.1 - OpenAI adapter**
  - Hard requirement:
    - Use Responses API shape (not Chat Completions) for reasoning token support.
  - Deliverables:
    - Message translation (instructions extraction, input items)
    - Tool call + tool result translation
    - Streaming translation of Responses SSE events
    - Reasoning token reporting via Responses usage fields

- [ ] **B3.2 - Anthropic adapter**
  - Hard requirements:
    - Messages API shape, strict alternation handling, thinking signature round-tripping
    - Prompt caching injection via `cache_control` and beta headers when needed
    - Strict alternation fixups (merge consecutive same-role content)

- [ ] **B3.3 - Gemini adapter**
  - Hard requirements:
    - Native Gemini API shape, synthetic tool call IDs mapping to function names
    - Streaming translation (JSON chunk or SSE alt)
    - thoughtsTokenCount -> reasoning_tokens mapping when present

### B4 - High-Level APIs + Tool Loop
- [ ] **B4.1 - generate()/stream() wrappers**
  - Requirements:
    - prompt vs messages exclusivity
    - timeouts (total + per-step) and abort signals
    - usage aggregation across steps

- [ ] **B4.2 - Tool calling loop**
  - Requirements:
    - Active vs passive tools
    - max_tool_rounds semantics (`0` disables)
    - Parallel tool calls: execute concurrently, batch results into a single continuation request, preserve ordering
    - Unknown tool calls become error ToolResult (not thrown)
    - ToolChoice mode translations (auto/none/required/named), including Anthropic "none" via omitting tools

- [ ] **B4.4 - Prompt caching**
  - Deliverables:
    - OpenAI: surface cache_read_tokens from Responses usage fields
    - Anthropic: automatic cache_control injection + required beta header when enabled
    - Gemini: surface cache_read_tokens when present

- [ ] **B4.3 - generate_object()/stream_object()**
  - Requirements:
    - Provider-specific structured output where supported
    - Validation with JSON schema; errors raise NoObjectGeneratedError

### B5 - Model Catalog
- [ ] **B5.1 - Model catalog data file**
  - Deliverables:
    - `lib/unified_llm/models.json` or similar, loaded by SDK
    - `get_model_info`, `list_models`, `get_latest_model`

### B6 - ULLM Parity Matrix + Smoke Tests
- [ ] **B6.1 - Cross-provider parity matrix (ULLM DoD 8.9)**
  - Tests:
    - Use a local mock HTTP server for deterministic unit tests where possible
    - Gate real-provider tests behind env vars (OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY)

- [ ] **B6.2 - Integration smoke test (ULLM DoD 8.10)**
  - Evidence:
    - Logs under `.scratch/verification/SPRINT-001/unified_llm/smoke/...`

### Acceptance Criteria - Track B
- [ ] Offline adapter tests (mock server) validate: request translation, tool call/result handling, streaming event normalization, error mapping, and usage accounting.
- [ ] `generate()` tool loop passes a deterministic test proving: parallel tool calls execute concurrently, all results are batched into one continuation request, and result ordering is preserved.
- [ ] OpenAI adapter uses Responses API endpoints (not Chat Completions) in tests; reasoning_tokens + cache_read_tokens are surfaced when present.
- [ ] Anthropic adapter enforces strict alternation and round-trips thinking signatures; caching injection is implemented and testable.
- [ ] Gemini adapter assigns synthetic tool call IDs and correctly maps functionResponse payloads back to ToolResults.
- [ ] Parity matrix (ULLM DoD 8.9) is green offline; live-provider smoke tests are green when keys are present (and are gated by env vars/secrets).

## Track C - Coding Agent Loop (coding-agent-loop-spec.md)

### C0 - Requirements Indexing
- [ ] **C0.1 - Build CAL traceability map**

### C1 - Tool Registry + Execution Environment
- [ ] **C1.1 - ToolRegistry**
  - Requirements:
    - argument JSON validation against schema
    - unknown tools return error result, not exception

- [ ] **C1.2 - LocalExecutionEnvironment**
  - Requirements:
    - read/write/edit/apply_patch support per profile needs
    - shell with timeouts and process group kill semantics
    - env var filtering defaults (exclude `*_API_KEY`, `*_SECRET`, etc.)
    - grep/glob implementations (prefer `rg` when present)
  - Explicit tests:
    - env filtering excludes `*_API_KEY`, `*_SECRET`, `*_TOKEN`, `*_PASSWORD`, `*_CREDENTIAL` by default
    - timeout sends SIGTERM then SIGKILL after 2s and returns partial output + timeout marker

### C2 - Truncation + Context Awareness
- [ ] **C2.1 - Tool output truncation**
  - Hard requirements:
    - character truncation runs FIRST
    - line truncation runs SECOND (shell/grep/glob defaults)
    - truncation marker includes removed size and instructions
    - TOOL_CALL_END event always carries full untruncated output

- [ ] **C2.2 - Context window awareness warning events**

### C3 - Provider Profiles (Provider-Aligned Toolsets)
- [ ] **C3.1 - OpenAI profile (codex-rs-aligned)**
  - Requirements:
    - apply_patch tool (v4a) + system prompt topics
  - Deliverables:
    - apply_patch v4a parser + executor (add/update/delete/move)
    - Verification of hunk matching rules and multi-hunk updates

- [ ] **C3.2 - Anthropic profile (Claude Code-aligned)**
  - Requirements:
    - edit_file old_string/new_string semantics + system prompt topics
  - Deliverables:
    - edit_file exact match with "not found" and "not unique" errors
    - optional whitespace-normalization fallback with explicit reporting (per spec guidance)

- [ ] **C3.3 - Gemini profile (gemini-cli-aligned)**

### C4 - Session Core Loop + Events + Steering
- [ ] **C4.1 - Session + process_input core loop**
  - Requirements:
    - natural completion (text-only response)
    - max_tool_rounds_per_input + max_turns enforcement
    - abort signal -> graceful shutdown
    - loop detection -> SteeringTurn warning
    - multiple sequential inputs

- [ ] **C4.2 - Event system**
  - Requirements:
    - all event kinds emitted at correct times
    - async-ish consumption (callback or queue)

- [ ] **C4.3 - System prompt assembly**
  - Requirements:
    - layered prompt construction
    - environment context block
    - git context snapshot
    - project doc discovery rules (AGENTS.md + provider-specific)

### C5 - Subagents
- [ ] **C5.1 - Subagent spawning tools**
  - Requirements:
    - depth limiting (default 1)
    - independent history but shared filesystem/execution env
    - tools: spawn_agent/send_input/wait/close_agent

### C6 - CAL Parity Matrix + Smoke Test
- [ ] **C6.1 - Cross-provider parity matrix (CAL DoD 9.12)**
- [ ] **C6.2 - Integration smoke test (CAL DoD 9.13)**

### Acceptance Criteria - Track C
- [ ] Agent loop runs deterministically against the mock Unified LLM provider(s): submit -> tool loop -> natural completion.
- [ ] Truncation is spec-correct: character truncation first, line truncation second; TOOL_CALL_END events contain full untruncated output.
- [ ] ExecutionEnvironment timeouts kill process groups reliably (SIGTERM then SIGKILL after 2s) and surface actionable timeout markers.
- [ ] Provider profiles are aligned: OpenAI uses apply_patch, Anthropic uses edit_file(old_string/new_string), Gemini uses gemini-cli-like toolset.
- [ ] Session emits the required event kinds and supports steer/follow_up, loop detection warnings, and limit enforcement.
- [ ] Subagents work with depth limiting and independent history (shared filesystem), and can be used from a profile toolset.

## Track D - Attractor (attractor-spec.md)

### D0 - Requirements Indexing
- [ ] **D0.1 - Build ATR traceability map**

### D1 - DOT Parser (Subset)
- [ ] **D1.1 - Comment stripping + tokenizer**
- [ ] **D1.2 - Parser: digraph subset + typed attributes**
- [ ] **D1.3 - Defaults (graph/node/edge), chained edges, subgraphs flattening**
  - Must cover:
    - qualified keys (`a.b.c`)
    - typed values (string/int/float/bool/duration)
    - multi-line attribute blocks
    - commas required between attrs

### D2 - Stylesheet + Transforms
- [ ] **D2.1 - Stylesheet parser + specificity rules**
- [ ] **D2.2 - Transform registry + built-in transforms ($goal expansion, stylesheet apply)**
  - Also include:
    - Preamble transform (execution-time) for fidelity modes that require summarization/compact carryover

### D3 - Validation / Linting
- [ ] **D3.1 - Diagnostic model**
- [ ] **D3.2 - Built-in lint rules + validate_or_raise**
- [ ] **D3.3 - Custom rule extension point**

### D4 - State: Context / Outcome / Checkpoint / Artifacts
- [ ] **D4.1 - Context (thread-safe)**
- [ ] **D4.2 - Outcome model + status.json contract**
- [ ] **D4.3 - Checkpoint save/load + resume behavior (fidelity degrade hop)**
- [ ] **D4.4 - Artifact store + run directory layout**
  - Deliverables:
    - `{logs_root}/{node_id}/status.json` written for each non-terminal node
    - `{logs_root}/{node_id}/prompt.md` + `response.md` for codergen
    - `{logs_root}/checkpoint.json` updated after each node

### D5 - Condition Expression Language
- [ ] **D5.1 - Condition parser + evaluator**

### D6 - Execution Engine
- [ ] **D6.1 - Core traversal loop**
- [ ] **D6.2 - Edge selection algorithm (5-step)**
- [ ] **D6.3 - Goal gates + retry_target routing**
- [ ] **D6.4 - Retry policy + backoff + jitter**
- [ ] **D6.5 - Failure routing + loop_restart**

### D7 - Handlers
- [ ] **D7.1 - Handler registry + custom handlers**
- [ ] **D7.2 - start + exit**
- [ ] **D7.3 - codergen + CodergenBackend interface**
  - Integration plan:
    - Provide a CodergenBackend implementation backed by Unified LLM `generate()` for basic LLM calls.
    - Provide an optional CodergenBackend backed by Coding Agent Loop Session for tool-using coding tasks.
- [ ] **D7.4 - wait.human + interviewer integration**
- [ ] **D7.5 - conditional**
- [ ] **D7.6 - parallel fan-out + fan-in (Thread package, isolated cloned contexts)**
- [ ] **D7.7 - tool handler (shell/exec)**
  - Spec-aligned node attributes:
    - `tool_command` (required)
- [ ] **D7.8 - stack.manager_loop handler (child pipeline supervision)**
  - Spec-aligned attributes:
    - graph attrs: `stack.child_dotfile`, `stack.child_workdir`, `stack.child_autostart`
    - node attrs: `manager.poll_interval`, `manager.max_cycles`, `manager.stop_condition`, `manager.actions`

### D8 - Human-in-the-Loop (Interviewers)
- [ ] **D8.1 - Interviewer interface**
- [ ] **D8.2 - AutoApprove/Console/Callback/Queue/Recording implementations**
- [ ] **D8.3 - Timeout behavior + defaults**

### D9 - Events / Observability / Hooks
- [ ] **D9.1 - Event model and delivery**
- [ ] **D9.2 - Tool call hooks (pre/post)**

### D10 - CLI (Minimum Required UX)
- [ ] **D10.1 - `bin/attractor run pipeline.dot`**
  - Requirements:
    - parse -> validate -> execute
    - emits events to console
    - writes run dir structure with checkpoint/status/prompt/response
- [ ] **D10.2 - Resume from checkpoint**
- [ ] **D10.3 - Optional: render SVG via `dot`**

### D11 - Optional HTTP Server Mode
- [ ] **D11.1 - HTTP server mode (only if we choose to implement)**
  - Note: This is marked optional by the spec ("if implemented"). Decide explicitly during execution whether to include it in this sprint.

### D12 - ATR Parity Matrix + Smoke Test
- [ ] **D12.1 - Cross-feature parity matrix (ATR DoD 11.12)**
- [ ] **D12.2 - Integration smoke test (ATR DoD 11.13)**

### Acceptance Criteria - Track D
- [ ] DOT parsing + validation match the spec: supported subset, typed attrs, defaults, chained edges, subgraph flattening, comment stripping, and stylesheet parsing.
- [ ] Engine traversal is deterministic and spec-correct: handler resolution, checkpointing, edge selection priority, retries/backoff/jitter, failure routing, goal gates, and loop_restart.
- [ ] Run directory contract is stable: `checkpoint.json`, per-node `status.json`, and codergen `prompt.md/response.md` are written as specified.
- [ ] Human gates work via Interviewers (AutoApprove/Queue for tests; Console for manual), including timeouts/default choice behavior.
- [ ] Parallel fan-out/fan-in run with isolated cloned contexts; fan-in selection and consolidation are deterministic and tested.
- [ ] The parity matrix (ATR DoD 11.12) and smoke test (ATR DoD 11.13) are green using mock backends by default.

## Track E - Cross-Spec Integration + Coverage Closure
- [ ] **E1 - Attractor codergen backend uses Unified LLM**
  - Demonstrate an Attractor pipeline that:
    - runs codergen nodes with model stylesheet defaults
    - uses $goal expansion
    - writes prompt.md/response.md

- [ ] **E2 - Attractor codergen backend uses Coding Agent Loop**
  - Demonstrate a pipeline node that runs a tool-using coding task (read/edit/shell) via Session.

- [ ] **E3 - End-to-end examples**
  - Deliverables:
    - `examples/` DOT pipelines for: linear, branching, retries, goal gates, human gate, parallel, tool handler, manager loop.

- [ ] **E4 - Spec coverage report is green**
  - Verification:
    - `tclsh tools/spec_coverage.tcl` (exit 0)

### Acceptance Criteria - Track E
- [ ] A single command can run an Attractor example pipeline end-to-end using the Unified LLM backend (mocked by default) and produces the expected run directory artifacts.
- [ ] A second example demonstrates CodergenBackend integration via Coding Agent Loop for a tool-using stage (read/edit/shell), with event logs proving tool usage.
- [ ] `tools/spec_coverage.tcl` is green and traceability demonstrates 100% coverage of DoD checklists and MUST/REQUIRED requirements across all three specs.

## Test Strategy (By Layer)
- Unit tests:
  - DOT parser/validator edge cases (comments, multiline attrs, chained edges, defaults, subgraphs).
  - Condition evaluator truth table.
  - Truncation behavior (char first, line second; marker correctness).
  - JSON schema validator (tool args + structured output).
  - Provider request translation (golden JSON fixtures) without needing network.
- Integration tests:
  - Local mock servers for OpenAI/Anthropic/Gemini HTTP + SSE streaming to validate adapters deterministically.
  - Tool execution end-to-end (shell timeouts, env filtering).
- End-to-end tests:
  - Run Attractor CLI against example DOT and assert run dir outputs + deterministic checkpoint/resume.
  - (Optional/gated) live-provider smoke tests with real keys.

## Risks And Mitigations
- Risk: **Tcl 8.5 lacks coroutines/TclOO**, making "async iterator" semantics awkward.
  - Mitigation: callback-based streaming + buffered event streams for tests; document API mapping precisely.
- Risk: Provider APIs and beta headers evolve.
  - Mitigation: keep provider adapters isolated; keep model catalog data-driven; implement `provider_options` escape hatch fully.
- Risk: True 100% spec coverage is large.
  - Mitigation: enforce traceability early (Track A/B0/C0/D0) so we never "lose" requirements.

## Definition Of Done (Sprint-Level)
- [ ] All three spec DoD checklists are satisfied with evidence.
- [ ] `tclsh tests/all.tcl` passes from a clean checkout.
- [ ] `docs/spec-coverage/traceability.md` + `tools/spec_coverage.tcl` prove no uncovered requirements remain.
- [ ] At least one end-to-end Attractor pipeline runs using:
  - Unified LLM backend (mocked by default, live gated by env)
  - Coding Agent Loop backend for a tool-using node
