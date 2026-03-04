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

## ADR-011: Opt-In Live E2E Harness with Explicit HTTPS Transport Injection and Secret-Scan Enforcement
- Date: 2026-02-27
- Status: Accepted

### Context
The deterministic test suite validates runtime behavior using offline fixtures, but it does not prove real provider integration behavior over HTTPS (auth headers, payload shape, and response parsing). We needed a live smoke path that is intentionally opt-in and auditable without allowing ambient environment secrets to alter default offline tests.

### Decision
- Add a provider-agnostic live transport callback (`::unified_llm::transports::https_json::call`) and require explicit `client_new -transport ...` injection for live suite execution.
- Keep default offline test entrypoint (`tests/all.tcl`) separate from live entrypoint (`tests/e2e_live.tcl`), wired as `make test-e2e`.
- Make live harness provider selection deterministic:
  - default: all providers with configured keys
  - explicit allowlist via `E2E_LIVE_PROVIDERS`
  - fail-fast on empty selection or requested provider missing key
- Treat redaction as a correctness requirement:
  - redact auth headers in adapter response request metadata
  - run post-suite artifact secret scan against loaded key values and fail on matches
- Persist run-level evidence (`run.json`, per-component/provider artifacts, `secret-leaks.json`) under `.scratch/verification/SPRINT-004/live/<run_id>/`.

### Consequences
Positive:
- Live provider connectivity and end-to-end behavior can be validated without changing default deterministic workflows.
- Secret handling becomes auditable and testable rather than best-effort.
- Developers can run partial provider sets while still receiving deterministic skip/fail-fast behavior.

Tradeoffs:
- Live test runs now depend on provider availability, credentials, and account/model compatibility.
- Additional harness and artifact-management code increases maintenance scope.

## ADR-012: Live Provider Payload Compatibility and Transport Robustness for Sprint #004 Closeout
- Date: 2026-02-27
- Status: Accepted

### Context
After enabling live E2E execution with real provider credentials, the initial closeout pass exposed provider-facing compatibility failures that were not visible in offline fixtures:
- URL joining duplicated version paths when base URLs already contained `/v1`.
- Transport emitted duplicated `Content-Type` headers (`application/json,application/json`) for OpenAI.
- Coding Agent Loop requests omitted model selection, causing provider-side validation failures.
- Anthropic and Gemini rejected direct `system` role messages in `messages`/`contents` payloads.
- Gemini default model (`gemini-1.5-pro`) was not available for the current API/account baseline.

### Decision
- Harden HTTPS transport behavior:
  - deduplicate base-path + endpoint joins
  - split content type from explicit headers and set it exactly once
  - include bounded HTTP/network error body summaries in error messages for deterministic debugging
- Extend Coding Agent Loop request control:
  - profile-level model defaults (with environment overrides)
  - session-level model override (`config.model`)
  - session-level system prompt override (`config.system_prompt`) for provider-compatibility tests
- Normalize provider request translation:
  - Anthropic: move `system` content to top-level `system` field
  - Gemini: move `system` content to `systemInstruction`; remap `assistant` role to `model`
- Update Gemini live default model to `gemini-2.0-flash` for current availability.
- Add/expand regression tests for URL joins, payload encoding behavior, and Coding Agent Loop model/system override forwarding.

### Consequences
Positive:
- `make test-e2e` now passes for OpenAI, Anthropic, and Gemini in the validated environment.
- Live smoke behavior is deterministic across success and fail-fast paths.
- Transport and adapter failures surface actionable, bounded diagnostics without leaking secrets.

Tradeoffs:
- JSON encoding compatibility logic is more nuanced and requires continued regression coverage.
- Provider payload translation now contains more provider-specific normalization behavior.

## ADR-013: Provider-Native Unified LLM Streaming Translation and Evidence-Backed Stream Contract
- Date: 2026-02-28
- Status: Accepted

### Context
Unified LLM `stream()` behavior previously synthesized `TEXT_DELTA` events from blocking `complete()` responses. This obscured provider-native streaming semantics (SSE frame translation, event ordering, tool-call deltas, reasoning blocks) and weakened proof for streaming-related requirements in traceability.

### Decision
- Adopt provider-native streaming translation for OpenAI, Anthropic, and Gemini adapters:
  - OpenAI: parse `/v1/responses` SSE event payloads and map `response.*` event types into unified StreamEvents.
  - Anthropic: parse `content_block_*` + `message_*` SSE event payloads into text/tool/reasoning unified StreamEvents.
  - Gemini: parse `:streamGenerateContent?alt=sse` candidate parts into text/tool StreamEvents and emit FINISH at clean end-of-stream even without explicit finish marker.
- Expand runtime stream contract in `lib/unified_llm/main.tcl`:
  - explicit StreamEvent constructor/validation helper
  - ordering invariants for text/tool lifecycles
  - terminal semantics allowing `FINISH` or `ERROR` as terminal event
- Upgrade synthetic fallback stream behavior to emit `TEXT_START` and `TEXT_END` around `TEXT_DELTA`.
- Update `stream_object` collection logic to track target `text_id`, ignore non-text events safely, and return typed streaming errors when streams terminate with `ERROR`.
- Treat fixture-driven translator tests as the primary deterministic verification path for streaming parity, with targeted traceability verify patterns for streaming requirement IDs.

### Consequences
Positive:
- Unified streaming behavior now reflects provider-native event semantics and ordering.
- Tool-call argument deltas can be verified end-to-end as decoded argument dictionaries at `TOOL_CALL_END`.
- Streaming requirement mappings are now specific and auditable instead of broad catch-all patterns.

Tradeoffs:
- Adapter stream translators are more complex and require ongoing fixture maintenance as provider event formats evolve.
- Streaming failure handling is explicit (`ERROR` terminal) and places more responsibility on callers to handle non-FINISH terminal paths.

## ADR-014: Sprint #006 NLSpec Gap Closure for Attractor Mapping, Manager Loop, and Anthropic Thinking Fidelity
- Date: 2026-03-03
- Status: Accepted

### Context
Sprint #006 identified four high-impact NLSpec gaps:
- Attractor shape-to-handler resolution diverged from the canonical mapping table.
- `stack.manager_loop` was implemented as a stub without supervisor semantics or telemetry artifacts.
- `::unified_llm::from_env` rejected multi-provider environments and did not provide a deterministic multi-provider client configuration contract.
- Anthropic translation did not fully support DEVELOPER/TOOL role semantics or thinking/redacted thinking round-tripping with signatures.

### Decision
- Align Attractor handler resolution with canonical mappings:
  - `hexagon -> wait.human`
  - `parallelogram -> tool`
  - `component -> parallel`
  - `tripleoctagon -> parallel.fan_in`
  - `house -> stack.manager_loop`
  - retain `parallel.fan_in` with `fan-in` alias support
- Implement a minimal `stack.manager_loop` supervisor handler:
  - consumes `stack.child_dotfile`, `stack.child_autostart`, `manager.poll_interval`, `manager.max_cycles`, `manager.stop_condition`, and `manager.actions`
  - emits cycle telemetry under `<logs_root>/<node>/manager_loop.json`
  - returns deterministic failures for missing child configuration, child failure, invalid stop/action config, and cycle exhaustion
- Introduce a multi-provider client-state contract in Unified LLM:
  - `default_provider`
  - `providers` dictionary with per-provider `api_key`, `base_url`, `transport`, and `provider_options`
  - `from_env` registers all configured providers, chooses deterministic default ordering, and enforces optional `UNIFIED_LLM_PROVIDER` override validity
- Extend Anthropic adapter/message normalization:
  - normalize supported roles (`system`, `developer`, `user`, `assistant`, `tool`)
  - translate TOOL role messages into Anthropic `tool_result` blocks in `user` messages
  - preserve `thinking` and `redacted_thinking` blocks (with `signature`) in request translation and response parsing for `complete()` and `stream()`

### Consequences
Positive:
- Attractor execution behavior now matches canonical NLSpec handler selection and manager-loop semantics.
- Unified LLM clients can be built once and route across multiple configured providers deterministically.
- Anthropic round-tripping of reasoning artifacts is preserved for continuation fidelity and regression-protected by unit/streaming tests.

Tradeoffs:
- Unified LLM client state and Anthropic translation paths are more complex and require ongoing fixture coverage as provider payload schemas evolve.
- Manager-loop behavior is intentionally minimal and synchronous; future enhancements may be required for fully asynchronous child lifecycle control.

## ADR-015: Sprint #008 Local-First Web Dashboard via Filesystem Run Store, Worker Subprocesses, and SSE
- Date: 2026-03-04
- Status: Accepted

### Context
The Attractor runtime already supported deterministic CLI execution and filesystem artifacts, but lacked a web control plane required by spec section 9.5/9.6. Human gates were operable only through non-web interviewers, and there was no server-side event stream for live UI updates.

### Decision
- Add a local-first web runtime package (`attractor_web`) served by `bin/attractor serve` with default bind `127.0.0.1`.
- Keep the engine headless and synchronous; web-mode execution runs each pipeline in a dedicated worker subprocess (`bin/attractor-worker`) to keep the HTTP server responsive.
- Use a filesystem run-store contract under `runs_root/run_id/`:
  - `pipeline.dot`, `web.json`, `manifest.json`, `checkpoint.json`, `events.ndjson`, `questions/*.pending.json`, `questions/*.answer.json`, per-node artifacts.
- Add additive event hooks to `::attractor::run` (`-on_event`, `-run_id`) to emit lifecycle events without changing default CLI behavior.
- Implement web-operable `wait.human` via a filesystem interviewer handshake in the worker:
  - write pending question files
  - unblock on answer files or fail deterministically on timeout.
- Implement SSE endpoints:
  - `GET /events` for global snapshot updates
  - `GET /events/<run_id>` for replay + tail of `events.ndjson`.

### Consequences
Positive:
- Satisfies web-operable human-gate and real-time event-stream requirements with deterministic, offline-testable behavior.
- Preserves Tcl 8.5 compatibility and existing CLI workflows.
- Avoids introducing a database or in-process async runtime complexity.

Tradeoffs:
- Filesystem polling for SSE convergence is simple but less efficient than in-memory publish/subscribe.
- JSON persistence uses existing project encoding helpers; empty-string representation in some persisted artifacts may require future normalization work.
- Worker supervision is best-effort and intentionally lightweight for localhost usage.

## ADR-016: Provider Prompt Parity Alignment with swift-omnikit Prompt Sources
- Date: 2026-03-04
- Status: Accepted

### Context
`coding_agent_loop` previously assembled a compact generic system prompt from profile `identity` and `tool_guidance`. This diverged from the provider-native prompt structures used by `swift-omnikit`, reducing parity for Codex/OpenAI, Claude/Anthropic, and Gemini profiles.

### Decision
- Introduce a dedicated prompt composition module at `lib/coding_agent_loop/prompts.tcl` and route session prompt generation through it.
- Vendor prompt source material from `swift-omnikit` into repository resources:
  - `lib/coding_agent_loop/resources/CodexPrompts/*.md` for Codex/OpenAI model-specific base prompts and apply-patch instructions.
  - `lib/coding_agent_loop/resources/OmniKitPromptSources/ClaudeSystemPrompt.swift` and `GeminiSystemPrompt.swift` as canonical parity references.
- Implement model-aware Codex prompt selection (`gpt-5.2`, `gpt-5.1`, codex variants, codex-max) and append apply-patch instructions exactly as the upstream selection model describes.
- Implement provider-specific system prompt builders:
  - OpenAI: Codex base prompt + environment context + optional project/user sections.
  - Anthropic: Claude-style section assembly (tool descriptions, core sections, environment/git context, optional project/user sections) populated from the vendored Claude source constants.
  - Gemini: Gemini CLI-style composed mandates/workflows/operational sections + environment footer + optional project/user sections.
- Update coding-agent-loop profile defaults to match `swift-omnikit` profile defaults:
  - OpenAI `gpt-5.2`
  - Anthropic `claude-haiku-4-5`
  - Gemini `gemini-3-flash-preview`

### Consequences
Positive:
- Prompt behavior is provider-native and materially closer to `swift-omnikit` composition semantics.
- Codex prompt resources are now byte-vendored in-tree, reducing drift for OpenAI model-family prompts.
- Prompt-generation logic is centralized and easier to validate with deterministic tests.

Tradeoffs:
- Prompt subsystem complexity increased substantially versus the prior generic formatter.
- Claude parity currently depends on parsing vendored Swift constants; upstream structural changes may require parser maintenance.
- Default model changes can alter live smoke behavior/cost characteristics for environments relying on implicit defaults.

## ADR-017: Provider-Backed DOT Streaming Endpoints and Real Default Codergen Backend
- Date: 2026-03-04
- Status: Accepted

### Context
The web dashboard lacked a prompt-to-DOT generator path, and the default Attractor codergen backend still used the mock provider. This blocked end-to-end "create from prompt -> run pipeline" behavior against real providers and diverged from the expected DOT generate/fix/iterate loop.

### Decision
- Add provider-backed streaming DOT endpoints in `attractor_web`:
  - `POST /api/v1/dot/generate/stream`
  - `POST /api/v1/dot/fix/stream`
  - `POST /api/v1/dot/iterate/stream`
- Implement server-side DOT generation with `::unified_llm::stream` and SSE frames:
  - `data: {"delta":"..."}`
  - `data: {"done":true,"dotSource":"..."}`
  - terminal stream failures emit `data: {"error":"...","code":"GENERATION_ERROR"}`
- Add a shared DOT system prompt and markdown-fence stripping (`normalize_dot_source`) before returning final DOT source.
- Replace `::attractor::default_codergen_backend` mock behavior with a real Unified LLM call using provider/model resolution from environment defaults (`ATTRACTOR_PROVIDER`, `UNIFIED_LLM_PROVIDER`, provider model env vars).
- Extend live e2e coverage to include `attractor_web` DOT streaming smoke tests for selected real providers.

### Consequences
Positive:
- Prompt-driven DOT generation/fix/iterate is now implemented end-to-end with real providers.
- Default codergen behavior now reflects production provider-backed execution rather than mock output.
- Live e2e coverage includes the web DOT stream loop, improving confidence in API-level create workflows.

Tradeoffs:
- Local runs with codergen nodes now require valid provider configuration instead of silently using mock output.
- Streaming endpoint implementation introduces additional server-side LLM configuration surface and associated failure modes.

## ADR-018: Remove Runtime Stub Providers and Enforce Provider-Realistic E2E via Browser Automation
- Date: 2026-03-04
- Status: Accepted

### Context
The runtime still contained non-production fallback behavior (`mock` provider and offline adapter responses), and the dashboard flow lacked browser-level end-to-end verification in the default `make test-e2e` path.

### Decision
- Remove runtime stub provider behavior from Unified LLM:
  - drop `mock` provider support from provider allowlists and dispatch.
  - remove adapter offline response fallback paths.
- Remove `attractor_web` server-level DOT transport injection (`-dot_llm_transport`) and keep only real provider env resolution plus explicit injected client support (`-dot_llm_client`) for deterministic test fixtures.
- Rewrite affected tests to use explicit provider adapters (`openai`/`anthropic`/`gemini`) with deterministic transport fixtures, instead of `mock` provider behavior.
- Extend `make test-e2e` to run:
  - live provider smoke suite (`tests/e2e_live.tcl`)
  - browser e2e dashboard flow (`tests/e2e_playwright.mjs`)
- Add Docker-backed Playwright server mode for environments where local Tcl/TLS cannot call provider HTTPS APIs.

### Consequences
Positive:
- Runtime behavior now consistently exercises real provider adapters rather than synthetic offline paths.
- `make test-e2e` validates API-level and browser-level create/iterate/fix/run loops against real provider-backed endpoints.
- Older local Tcl/TLS environments can still execute browser e2e through Docker-backed server mode.

Tradeoffs:
- Test infrastructure depends on Node + Playwright availability in addition to Tcl.
- Browser e2e runtime is longer, especially when Docker-backed server startup is required.
