Legend: [ ] Incomplete, [X] Complete

_Evidence for every completed checklist item must include the exact verification command (wrapped with backticks) plus its exit code and artifacts (logs, `.scratch` transcripts, diagram renders) directly beneath the item when the work is performed._

# Sprint #005 - Unified LLM Streaming and Evidence Hygiene

## Objective
Make Unified LLM streaming spec-faithful (provider-native streaming translation with correct StreamEvent types and ordering) and restore the repo's evidence/traceability hygiene so streaming compliance is provable against the NLSpecs.

## Context
Current state (codex-3 baseline):
- Unified LLM `stream()` synthesizes streaming by chunking a completed response; it does not parse provider-native streaming formats (SSE/JSON chunks).
- The stream event model is incomplete versus `unified-llm-spec.md` (missing TEXT_START/TEXT_END, tool-call deltas, reasoning blocks).
- The repo has strong spec coverage gates, but streaming-related traceability mappings are currently too coarse to be trustworthy.
- Evidence linting is present (`tools/evidence_lint.sh`) but existing sprint docs do not consistently meet its contract.

Improvements available from other branches:
- codex-2 demonstrates provider-native SSE parsing and live streaming adapter scaffolding.
- codex-1 demonstrates stricter evidence discipline patterns and a more complete SSE field set (event/data/id/retry/comment handling).

This sprint ports the *substance* of those improvements into the codex-3 foundation while keeping deterministic offline testing as the default.

## Non-Goals
- No new providers beyond OpenAI, Anthropic, and Gemini.
- No compatibility shims (e.g., OpenAI Chat Completions as the primary path).
- No feature flags.

## StreamEvent Contract (Target)
This sprint aligns the Tcl implementation with `unified-llm-spec.md` Section 3.13/3.14 by representing each stream event as a Tcl dict with:
- `type` (required): `STREAM_START`, `TEXT_START`, `TEXT_DELTA`, `TEXT_END`, `REASONING_START`, `REASONING_DELTA`, `REASONING_END`, `TOOL_CALL_START`, `TOOL_CALL_DELTA`, `TOOL_CALL_END`, `FINISH`, `ERROR`, `PROVIDER_EVENT`.
- `text_id` (optional): stable identifier that correlates TEXT_* deltas to a segment.
- `delta` (optional): incremental text (TEXT_DELTA).
- `reasoning_delta` (optional): incremental thinking/reasoning text (REASONING_DELTA).
- `tool_call` (optional): partial or complete tool call dict (TOOL_CALL_*).
- `finish_reason` (optional): unified finish reason dict at FINISH.
- `usage` (optional): unified usage dict at FINISH.
- `response` (optional): final accumulated unified response dict at FINISH.
- `error` (optional): normalized error dict at ERROR.
- `raw` (optional): raw provider event dict for passthrough/debug.

Notes:
- For providers that do not naturally expose multiple concurrent text segments, a single `text_id` (e.g., `text-1`) is sufficient.
- For OpenAI Responses API, prefer the provider's output item ID when available to populate `text_id`.

## Design Notes
- Public API shape remains callback-driven (`::unified_llm::stream -on_event ...`) for Tcl 8.5 compatibility; the work in this sprint is about correctness of event typing/ordering and provider translation, not introducing a new async iterator abstraction.
- Provider adapters must implement `stream()` by enabling provider-native streaming on the request and translating SSE/JSON chunks; they must not call `complete()` and then chunk a full response string.
- Deterministic offline tests are the default: provider streaming translators are validated against fixture payloads and mock transports.
- Error semantics:
  - If streaming fails after partial deltas have been delivered, emit `ERROR` and stop (do not retry).
  - Unmapped provider events should be surfaced as `PROVIDER_EVENT` with `raw` populated.

## Plan
Execution order: Track A -> Track B -> Track C -> Track D -> Track E.

### Track A - SSE Parser Contract (Core)
- [ ] A1 - Harden SSE parser behavior for real streaming payloads (EOF flush, multi-line data, comment lines, id/retry fields) and expose a stable API for Unified LLM to consume.
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *attractor_core-sse*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-a/sse-parser/tests-all-attractor-core-sse.log`
```

- [ ] A2 - Add an offline fixture corpus of minimal SSE frames for OpenAI/Anthropic/Gemini that covers: text deltas, tool call deltas, reasoning blocks, terminal frames, and malformed frames.
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *unified_llm-stream-fixture*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-a/fixtures/tests-all-unified-llm-stream-fixture.log`
```

- [ ] A3 - Add SSE parser regression tests for EOF-without-blank-line flush and ensure `::attractor_core::parse_sse` exists (as an alias) for cross-branch/tooling compatibility.
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *attractor_core-sse*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-a/sse-parser/tests-all-attractor-core-sse-regressions.log`
```

#### Acceptance Criteria - Track A
- Parser emits identical event boundaries as defined in `unified-llm-spec.md` Section 7.7 (SSE Parsing).
- Fixtures are sufficient to test each provider translator without any live network calls.

### Track B - Unified StreamEvent Model (Spec Parity)
- [ ] B1 - Implement StreamEvent emission helpers and invariants (type/field validation, text_id lifecycle, and deterministic ordering) so adapters can be tested against the spec contract.
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *unified_llm-stream-event-model*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-b/event-model/tests-all-unified-llm-stream-event-model.log`
```

- [ ] B2 - Update the synthetic stream path (mock + "stream-from-complete" fallback) to emit TEXT_START/TEXT_DELTA/TEXT_END and to preserve tool call boundaries consistently.
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *unified_llm-stream-events*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-b/synthetic/tests-all-unified-llm-stream-events.log`
```

- [ ] B3 - Implement `PROVIDER_EVENT` and `ERROR` stream events, plus negative tests that validate behavior on malformed JSON and unexpected provider event types.
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *unified_llm-stream-error*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-b/errors/tests-all-unified-llm-stream-error.log`
```

#### Acceptance Criteria - Track B
- Streaming follows the start/delta/end pattern for text segments (ULLM-DOD-8.31).
- TEXT_DELTA events concatenate to the final response text (ULLM-DOD-8.29).

### Track C - Provider-Native Streaming Translation
- [ ] C1 - OpenAI Responses API: implement real streaming translation by parsing SSE events and mapping them to StreamEvent types per `unified-llm-spec.md` Section 7.7 (OpenAI Streaming).
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *unified_llm-openai-stream-translation*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-c/openai/tests-all-unified-llm-openai-stream-translation.log`
```

Implementation notes (must be covered by unit tests using fixtures):
- `response.output_text.delta` -> TEXT_START (first delta for a text_id) + TEXT_DELTA.
- `response.function_call_arguments.delta` -> TOOL_CALL_DELTA (retain raw partial JSON string until TOOL_CALL_END).
- `response.output_item.done` (text) -> TEXT_END.
- `response.output_item.done` (function_call) -> TOOL_CALL_END (tool_call dict must be complete and JSON arguments decoded).
- `response.completed` -> FINISH (usage must include reasoning_tokens when present).

- [ ] C2 - Anthropic Messages API: implement real streaming translation for text/tool_use/thinking blocks per `unified-llm-spec.md` Section 7.7 (Anthropic Streaming).
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *unified_llm-anthropic-stream-translation*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-c/anthropic/tests-all-unified-llm-anthropic-stream-translation.log`
```

Implementation notes (must be covered by unit tests using fixtures):
- `content_block_start` (text) -> TEXT_START with stable `text_id` derived from block index/id.
- `content_block_delta` (text) -> TEXT_DELTA.
- `content_block_stop` (text) -> TEXT_END.
- `content_block_start/delta/stop` (tool_use) -> TOOL_CALL_START/DELTA/END.
- `content_block_start/delta/stop` (thinking) -> REASONING_START/DELTA/END.
- `message_stop` -> FINISH with accumulated response + usage.

- [ ] C3 - Gemini Streaming: implement `:streamGenerateContent?alt=sse` translation for text and functionCall parts per `unified-llm-spec.md` Section 7.7 (Gemini Streaming).
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *unified_llm-gemini-stream-translation*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-c/gemini/tests-all-unified-llm-gemini-stream-translation.log`
```

Implementation notes (must be covered by unit tests using fixtures):
- `data: {"candidates":[...]}` with `parts[].text` -> TEXT_START (first delta for text_id) + TEXT_DELTA.
- `parts[].functionCall` -> TOOL_CALL_START + TOOL_CALL_END (Gemini typically provides full calls in one chunk).
- `candidate.finishReason` present -> TEXT_END.
- Final chunk -> FINISH with accumulated response + usage (usageMetadata fields mapped when present).

- [ ] C4 - Validate tool-call streaming assembly end-to-end in unit tests: partial tool args deltas accumulate correctly and TOOL_CALL_END contains a decoded arguments dictionary (not only a raw JSON string).
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *unified_llm-stream-tool-call*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-c/tool-calls/tests-all-unified-llm-stream-tool-call.log`
```

#### Acceptance Criteria - Track C
- Provider-native streaming payloads are parsed and translated without buffering a full `complete()` response first.
- FINISH events include usage and metadata consistent with the corresponding `complete()` translation.

### Track D - API Surface, Middleware, and Structured Streaming
- [ ] D1 - Ensure request/response/event middleware semantics apply to streaming exactly as specified (request before call, per-event transforms in order, response transforms on final response).
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *unified_llm-stream-middleware*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-d/middleware/tests-all-unified-llm-stream-middleware.log`
```

- [ ] D2 - Make `stream_object` robust to the expanded event model (TEXT_START/TEXT_END, reasoning/tool-call events) while continuing to validate the final buffered JSON against schema.
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *unified_llm-stream-object*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-d/stream-object/tests-all-unified-llm-stream-object.log`
```

- [ ] D3 - Record an ADR for the streaming changes (expanded StreamEvent contract + provider-native streaming translation approach + any transport API extensions).
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `rg -n \"ADR-\" docs/ADR.md`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-d/adr/adr-streaming-entry.txt`
```

- [ ] D4 - Verify the "no retry after partial data" contract for streaming: when a transport error occurs after emitting at least one TEXT_DELTA, the stream emits ERROR and stops without re-invoking transport.
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tests/all.tcl -match *unified_llm-stream-no-retry-after-partial*`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-d/no-retry/tests-all-unified-llm-stream-no-retry-after-partial.log`
```

#### Acceptance Criteria - Track D
- Stream middleware can observe/transform events without breaking final response assembly.
- Structured output streaming continues to validate schema and fails with typed errors on invalid JSON.

### Track E - Traceability and Evidence Contract Closure
- [ ] E1 - Tighten traceability mappings for streaming requirements so they reference the new streaming tests (avoid catch-all `*unified*` patterns for streaming-specific IDs).
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tools/spec_coverage.tcl`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-e/traceability/spec-coverage.log`
```

- [ ] E2 - Update traceability for streaming-specific IDs (minimum set) to point to the new streaming tests and keep mappings truthful:
  - `ULLM-REQ-MOST-PROVIDERS-USE-SERVER-SENT-EVENTS`
  - `ULLM-REQ-RESPONSES-API-STREAMING-FORMAT-PROVIDES-REASONING`
  - `ULLM-DOD-8.29-YIELDS-EVENTS-CONCATENATE-FULL-RESPONSE-TEXT`
  - `ULLM-DOD-8.30-YIELDS-EVENTS-CORRECT-METADATA`
  - `ULLM-DOD-8.31-STREAMING-FOLLOWS-START-DELTA-END-PATTERN`
  - `ULLM-DOD-8.70-STREAMING-DOES-RETRY-AFTER-PARTIAL-DATA`
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `tclsh tools/spec_coverage.tcl`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-e/traceability/spec-coverage-streaming-ids.log`
```

- [ ] E3 - Bring sprint documentation evidence blocks into conformance with `tools/evidence_lint.sh` and add a small regression harness that runs docs lint + evidence lint + evidence guardrail for the current sprint doc before closeout.
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `bash tools/docs_lint.sh`
- `bash tools/evidence_lint.sh docs/sprints/SPRINT-005-unified-llm-streaming-evidence-hygiene.md`
- `tclsh tools/evidence_guardrail.tcl docs/sprints/SPRINT-005-unified-llm-streaming-evidence-hygiene.md`
- Expect: exit code 0
- Evidence: `.scratch/verification/SPRINT-005/track-e/evidence/docs-and-evidence-lint.log`
```

- [ ] E4 - Render the Appendix Mermaid diagrams with `mmdc` and store outputs under `.scratch/diagram-renders/sprint-005/` (these renders become evidence artifacts referenced by completed items).
```text
{placeholder for verification justification/reasoning and evidence log}

Planned verification:
- `mmdc -i .scratch/diagram-renders/sprint-005/unified-llm-streaming-flow.mmd -o .scratch/diagram-renders/sprint-005/unified-llm-streaming-flow.svg`
- `mmdc -i .scratch/diagram-renders/sprint-005/event-ordering-contract.mmd -o .scratch/diagram-renders/sprint-005/event-ordering-contract.svg`
- `ls .scratch/diagram-renders/sprint-005`
- Expect: exit code 0
- Evidence: `.scratch/diagram-renders/sprint-005/unified-llm-streaming-flow.svg`
```

#### Acceptance Criteria - Track E
- `tools/spec_coverage.tcl` remains strict and streaming requirements map to streaming-specific tests.
- Evidence lint and evidence guardrail pass for the SPRINT-005 doc (and for any sprint docs modified as part of the sprint).

## Verification Summary (What "Done" Looks Like)
- `tclsh tools/build_check.tcl` (exit code 0)
- `tclsh tests/all.tcl` (exit code 0)
- `bash tools/docs_lint.sh` (exit code 0)
- Live optional: `tclsh tests/e2e_live.tcl -match *unified-llm*` (exit code 0) when provider secrets are configured.

## Appendix - Mermaid Diagrams

### Streaming Flow (Unified LLM)
```mermaid
flowchart LR
  A[Caller] -->|unified_llm stream| B[Client stream]
  B --> C[Provider adapter stream]
  C --> D[HTTPS transport]
  D --> E[SSE parser]
  E --> F[Provider stream translator]
  F --> G[Unified StreamEvent]
  G --> H[Event middleware]
  H --> A
  F --> I[Final response assembler]
  I --> J[Response middleware]
  J --> A
```

### Event Ordering Contract
```mermaid
sequenceDiagram
  participant Caller
  participant ULLM as unified_llm
  participant Adapter
  participant Transport

  Caller->>ULLM: stream(request, -on_event cb)
  ULLM->>Adapter: stream(request)
  Adapter->>Transport: POST stream request
  Transport-->>Adapter: SSE frames
  Adapter-->>ULLM: STREAM_START
  Adapter-->>ULLM: TEXT_START
  loop Zero or more
    Adapter-->>ULLM: TEXT_DELTA
  end
  Adapter-->>ULLM: TEXT_END
  Adapter-->>ULLM: FINISH (response, usage)
  ULLM-->>Caller: cb(event...) in order
```
