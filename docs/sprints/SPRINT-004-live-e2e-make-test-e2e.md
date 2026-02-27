Legend: [ ] Incomplete, [X] Complete

_Evidence for every completed checklist item must include the exact verification command (wrapped with backticks) plus its exit code and artifact paths (logs, `.scratch` transcripts) directly beneath the item._

# Sprint #004 - Live E2E Smoke Suite (`make test-e2e`)

## Objective
Add a live end-to-end smoke test suite that exercises real provider APIs (requires API keys) to prove that:
- `unified_llm` can successfully call OpenAI/Anthropic/Gemini over HTTPS
- `coding_agent_loop` can drive a live LLM session end-to-end (natural completion path)
- `attractor` can run a small pipeline using a live codergen backend and produce artifacts/checkpoints

The suite must run via:
- `make test-e2e`

## Context & Problem
Today the repo’s tests are deterministic and offline. This is good for correctness and CI stability, but it does not prove that the real provider HTTP integrations work in practice (keys, HTTPS, headers, payload shapes, response decoding).

We need an explicit, opt-in live suite that developers can run intentionally to validate real-world integration.

## Current State Snapshot (Verified 2026-02-27)
- [X] `make -j10 test` passes offline.
```text
Verification:
- `make -j10 test` (exit 0)
Evidence:
- `.scratch/verification/SPRINT-004/baseline/make-test.log`
- `.scratch/verification/SPRINT-004/baseline/make-test.exitcode`
Notes:
- Baseline test suite is deterministic/offline.
```
- [X] There is no `make test-e2e` target.
```text
Verification:
- `make test-e2e` (exit 2)
Evidence:
- `.scratch/verification/SPRINT-004/baseline/make-test-e2e.log`
- `.scratch/verification/SPRINT-004/baseline/make-test-e2e.exitcode`
Notes:
- This sprint adds `make test-e2e` as an opt-in live suite entrypoint.
```
- [X] `tests/all.tcl` currently sources `tests/e2e/*.test`, so “live tests” must not be placed there.
```text
Verification:
- `rg -n "foreach dir \\{unit integration e2e\\}" tests/all.tcl` (exit 0)
Evidence:
- `.scratch/verification/SPRINT-004/baseline/tests-all-sources-e2e.log`
- `.scratch/verification/SPRINT-004/baseline/tests-all-sources-e2e.exitcode`
Notes:
- Live tests must live in a separate directory and be executed by a separate harness.
```

## Scope
In scope:
- A new live test harness that is not executed by `make test`
- A `make test-e2e` Makefile target that:
  - depends on `precommit`
  - fails fast with a descriptive error if no provider API keys are configured
- A real HTTPS transport implementation used only when explicitly injected (so offline tests never start calling the network just because keys exist in the shell environment)
- Live E2E tests for Unified LLM, Coding Agent Loop, and Attractor
- Safe logging: never print API keys or Authorization headers into test output or artifacts

Out of scope:
- Making live tests run in CI by default
- Full NLSpec parity (handled by Sprint #003)
- Any rate-limit/retry/backoff policy work

## Evidence Rules
- Every checklist item includes a verification/evidence block directly beneath it.
- Evidence artifacts live under `.scratch/verification/SPRINT-004/...` and are referenced by exact path.
- Mark an item `[X]` only once the verification commands have been run and evidence artifacts exist.

## Provider Selection Semantics (Live Suite)
- Default provider set for live runs: all providers with configured API keys in the environment.
- If multiple provider keys are configured, tests must run provider-by-provider using explicit configuration (do not rely on `unified_llm::from_env`, which is intentionally ambiguous when multiple keys are present).
- If a developer explicitly requests a provider (via a live-suite env var), and that provider’s key is missing, the suite must fail fast and must not attempt any network calls.
- If a provider’s key is not configured and that provider was not explicitly requested, its live tests must be skipped with a clear summary (so a “partial key set” is still useful).

## Execution Order
1. Phase 0: Baseline + design decisions
2. Phase 1: Live HTTPS transport + redaction
3. Phase 2: Unified LLM live E2E tests (per provider)
4. Phase 3: Coding Agent Loop live E2E tests (per provider)
5. Phase 4: Attractor live E2E tests (per provider)
6. Phase 5: Makefile target + documentation + closeout

## Phase 0 - Baseline + Design Decisions
- [ ] Confirm baseline offline behavior and document the “no network by default” rule for tests.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Add an ADR describing why live HTTP transport is opt-in via explicit `-transport` injection (prevents ambient environment secrets from changing offline test behavior).
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Define required environment variables and defaults for live tests (keys, optional model overrides, optional base URL overrides).
```text
{placeholder for verification justification/reasoning and evidence log}
```
Contract to define (must be documented in Phase 5):
- Provider API keys:
  - OpenAI: `OPENAI_API_KEY`
  - Anthropic: `ANTHROPIC_API_KEY`
  - Gemini: `GEMINI_API_KEY`
- Optional provider selection:
  - `E2E_LIVE_PROVIDERS` as a comma-separated allowlist (example: `openai,anthropic`).
- Optional model overrides (keep smoke tests cheap by default, but configurable):
  - `OPENAI_MODEL` (default: `gpt-4o-mini`)
  - `ANTHROPIC_MODEL` (default: `claude-sonnet-4-5`)
  - `GEMINI_MODEL` (default: `gemini-1.5-pro`)
- Optional base URL overrides (for proxies/self-hosted gateways):
  - `OPENAI_BASE_URL` (default: `https://api.openai.com`)
  - `ANTHROPIC_BASE_URL` (default: `https://api.anthropic.com`)
  - `GEMINI_BASE_URL` (default: `https://generativelanguage.googleapis.com`)

### Acceptance Criteria - Phase 0
- [ ] A contributor can read the ADR + docs and understand exactly how to run live tests and why they are not part of the offline suite.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Phase 1 - Live HTTPS Transport + Redaction
- [ ] Implement a provider-agnostic HTTPS JSON transport (Tcl `http` + `tls`) callable via `client_new -transport ...`.
```text
{placeholder for verification justification/reasoning and evidence log}
```
Implementation notes (be explicit in ADR + code comments where appropriate):
- Recommended location: `lib/unified_llm/transports/https_json.tcl`
- Recommended entrypoint proc: `::unified_llm::transports::https_json::call`
- Transport input dict (passed by `::unified_llm::adapters::__invoke_transport`):
  - `provider` (one of `openai|anthropic|gemini`)
  - `base_url` (optional; may be empty)
  - `endpoint` (starts with `/`)
  - `payload` (dict; transport JSON-encodes it)
  - `headers` (dict; transport converts to header list)
- Transport output dict (must match existing tests’ expectations):
  - `status_code` (integer)
  - `headers` (dict; keys lower-cased)
  - `body` (string; raw response body)
- HTTPS support:
  - Ensure `https://` requests work by registering TLS socket once: `http::register https 443 ::tls::socket`
- Base URL resolution order (highest precedence first):
  - request `base_url` (from client `-base_url`, if provided)
  - provider env var override (`OPENAI_BASE_URL`, `ANTHROPIC_BASE_URL`, `GEMINI_BASE_URL`)
  - provider default:
    - OpenAI: `https://api.openai.com`
    - Anthropic: `https://api.anthropic.com`
    - Gemini: `https://generativelanguage.googleapis.com`
- Error handling contract (needed for deterministic negative live tests):
  - Non-2xx HTTP responses must raise a Tcl error with `-errorcode` shaped like:
    - `UNIFIED_LLM TRANSPORT HTTP <provider> <status_code>`
  - Network/TLS failures must raise a Tcl error with `-errorcode` shaped like:
    - `UNIFIED_LLM TRANSPORT NETWORK <provider>`
  - Error messages must not include API keys or auth header values.

- [ ] Ensure request/response logging redacts secrets (including in error surfaces and in any structured artifacts).
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- never log `Authorization`, `x-api-key`, `x-goog-api-key`
- never log raw env var values for API keys
- Ensure `unified_llm` response dicts do not carry raw secrets (especially the `response.request.headers` field, since tcltest failure output may print dicts).
  - Preferred approach: store a redacted copy of request headers in the returned response dict and keep raw secrets only in-memory for the actual HTTP call.

- [ ] Add deterministic unit/integration tests for the transport layer using a local in-process HTTP server fixture (no real provider calls).
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- Server fixture:
  - Implement a minimal HTTP server using `socket -server` in `tests/support/` (or inline in the transport test file if preferred).
  - Capture the full request line + headers + body so tests can assert:
    - JSON body matches expected payload
    - `Content-Type` header is correct
    - Secret headers are present in the *wire* request but redacted in *logs/artifacts*
- Transport tests:
  - Happy path: transport posts JSON and returns `{status_code, headers, body}` with headers normalized to lower-case keys
  - Negative path: server returns a non-2xx status and transport raises the correct errorcode without secrets in the message

### Acceptance Criteria - Phase 1
- [ ] The live transport can successfully reach a local server, send JSON, and receive JSON, with redaction proven by tests.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Phase 2 - Unified LLM Live E2E Tests
- [ ] Add a new live test harness that is not executed by `tests/all.tcl` (example: `tests/e2e_live.tcl` sourcing `tests/e2e_live/*.test`).
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- The harness performs pre-flight selection + validation:
  - Determine configured providers from env (API keys + `E2E_LIVE_PROVIDERS`)
  - If zero providers are selected, print a descriptive message and exit non-zero
- The harness prints a clear run summary (selected providers, selected components, artifact root path).

- [ ] Implement OpenAI live smoke tests (requires `OPENAI_API_KEY`).
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- Use a short, low-variance prompt (example: “Say hello in one sentence.”) and assert:
  - blocking generation returns non-empty text
  - response has a provider-generated `response_id` (not the synthetic default)
  - response `usage.input_tokens > 0` and `usage.output_tokens > 0`
  - response `request.headers` (if present) is redacted (no bearer token)

- [ ] Implement Anthropic live smoke tests (requires `ANTHROPIC_API_KEY`).
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- Use a short, low-variance prompt and assert:
  - blocking generation returns non-empty text
  - response has a provider-generated `response_id` (not the synthetic default)
  - response `usage.input_tokens > 0` and `usage.output_tokens > 0`
  - response `request.headers` (if present) is redacted (no raw `x-api-key`)

- [ ] Implement Gemini live smoke tests (requires `GEMINI_API_KEY`).
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- Use a short, low-variance prompt and assert:
  - blocking generation returns non-empty text
  - response `raw.candidates` exists (to distinguish live responses from the offline transport stub)
  - response `usage.input_tokens > 0` and `usage.output_tokens > 0`
  - response `request.headers` (if present) is redacted (no raw `x-goog-api-key`)

### Test Matrix - Phase 2 (Explicit)
Positive cases (must be implemented):
- OpenAI: simple prompt -> non-empty response
- Anthropic: simple prompt -> non-empty response
- Gemini: simple prompt -> non-empty response

Negative cases (must be implemented):
- No provider keys configured at all: the harness fails fast with a descriptive error message (and does not attempt any network calls)
- Explicit provider requested but missing key: the harness fails fast with a descriptive error message (and does not attempt any network calls)
- Invalid key: provider returns an auth error; test asserts a deterministic failure surface (exit code + error classification or message pattern) and confirms no secrets appear in failure output

### Acceptance Criteria - Phase 2
- [ ] `make test-e2e` can run the Unified LLM live suite for at least one configured provider and produces an auditable log under `.scratch/verification/SPRINT-004/unified_llm/`.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Phase 3 - Coding Agent Loop Live E2E Tests
- [ ] Add live tests proving `coding_agent_loop` can complete a session with natural completion (text-only response) for each configured provider profile.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Assert the minimal event contract is emitted in live runs.
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- SESSION_START
- USER_INPUT
- ASSISTANT_TEXT_END

### Test Matrix - Phase 3 (Explicit)
Positive cases:
- For each configured provider profile: `session submit` returns non-empty text and emits required events

Negative cases:
- Invalid key: session submit fails deterministically and does not leak secrets

### Acceptance Criteria - Phase 3
- [ ] Live agent loop tests run under `make test-e2e` and store logs under `.scratch/verification/SPRINT-004/coding_agent_loop/`.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Phase 4 - Attractor Live E2E Tests
- [ ] Add a live codergen backend used only by tests that calls `unified_llm` with the live transport and returns the response text.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Add a live Attractor run test per configured provider.
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- runs a minimal pipeline (start -> codergen -> exit)
- writes `checkpoint.json` and per-node artifacts (`status.json`, `prompt.md`, `response.md`)

### Test Matrix - Phase 4 (Explicit)
Positive cases:
- For each configured provider: run succeeds and artifacts exist on disk

Negative cases:
- Invalid key: run fails deterministically and still writes a useful failure artifact/log (no secret leakage)

### Acceptance Criteria - Phase 4
- [ ] Attractor live tests run under `make test-e2e` and store artifacts under `.scratch/verification/SPRINT-004/attractor/`.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Phase 5 - Makefile Target + Docs + Closeout
- [ ] Add `test-e2e` target to `Makefile`.
```text
{placeholder for verification justification/reasoning and evidence log}
```
Details to cover:
- `test-e2e: precommit`
- runs only the live harness (not `tests/all.tcl`)

- [ ] Add `docs/howto/live-e2e.md` documenting required env vars, expected costs/side-effects, and where logs/artifacts are written.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] Ensure mermaid diagrams in this sprint render correctly via `mmdc` and store render artifacts under `.scratch/diagram-renders/sprint-004/`.
```text
{placeholder for verification justification/reasoning and evidence log}
```

### Acceptance Criteria - Phase 5
- [ ] `make test-e2e` fails fast and descriptively when no keys are configured, and passes when at least one provider is configured and all its tests pass.
```text
{placeholder for verification justification/reasoning and evidence log}
```
- [ ] No secrets appear in any captured logs or artifacts.
```text
{placeholder for verification justification/reasoning and evidence log}
```

## Appendix - Mermaid Diagrams (Verify Render With mmdc)

### Core Domain Models
```mermaid
%% Source: .scratch/diagrams/sprint-004/domain.mmd
classDiagram
  class LiveTransport {
    +call(request) response
    +redact(headers) safeHeaders
  }
  class UnifiedLLMClient {
    +complete()
    +stream()
    +generate()
  }
  class LiveE2EHarness {
    +requireEnv()
    +runProvider(provider)
    +writeEvidence()
  }
  class ProviderEnv {
    +keyVar
    +modelVar
    +baseURLVar
  }

  UnifiedLLMClient --> LiveTransport
  LiveE2EHarness --> UnifiedLLMClient
  LiveE2EHarness --> ProviderEnv
```

### E-R Diagram
```mermaid
%% Source: .scratch/diagrams/sprint-004/er.mmd
erDiagram
  E2E_RUN ||--o{ PROVIDER_RUN : contains
  PROVIDER_RUN ||--o{ HTTP_EXCHANGE : records
  PROVIDER_RUN ||--o{ ARTIFACT : stores
```

### Workflow Diagram
```mermaid
%% Source: .scratch/diagrams/sprint-004/workflow.mmd
flowchart TD
  MAKE[make test-e2e] --> HARNESS[tests/e2e_live.tcl]
  HARNESS --> ENV[Validate env keys]
  ENV -->|ok| RUN[Run provider smoke tests]
  ENV -->|missing| FAIL[Fail fast with message]
  RUN --> LOGS[Write redacted logs/artifacts]
  LOGS --> DONE[Exit 0 if passing]
```

### Data-Flow Diagram
```mermaid
%% Source: .scratch/diagrams/sprint-004/dataflow.mmd
flowchart LR
  ENVVARS[Env vars] --> HARNESS[Live test harness]
  HARNESS --> HTTP[HTTPS calls]
  HTTP --> RESP[Provider responses]
  RESP --> ASSERT[Assertions]
  ASSERT --> ART[Artifacts in .scratch]
```

### Architecture Diagram
```mermaid
%% Source: .scratch/diagrams/sprint-004/arch.mmd
flowchart TB
  subgraph Make
    TARGET[make test-e2e]
  end
  subgraph Tests
    HARNESS[tests/e2e_live.tcl]
    SUITE[tests/e2e_live/*.test]
  end
  subgraph Runtime
    ULLM[lib/unified_llm]
    CAL[lib/coding_agent_loop]
    ATR[lib/attractor]
    CORE[lib/attractor_core]
  end

  TARGET --> HARNESS --> SUITE
  SUITE --> ULLM
  SUITE --> CAL
  SUITE --> ATR
  ULLM --> CORE
  CAL --> ULLM
  ATR --> ULLM
  ATR --> CORE
```
