id: ULLM-DOD-8.1-CoreClient
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/main.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-provider-endpoints-*`
---
id: ULLM-DOD-8.2-DataModel
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/main.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-generate-object-*`
---
id: ULLM-DOD-8.3-MiddlewareOrder
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/main.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-middleware-order-*`
---
id: ULLM-DOD-8.4-NativeAdapters
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.5-StreamingEvents
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/main.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-stream-*`
---
id: ULLM-DOD-8.6-UsageMath
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/main.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-usage-add-*`
---
id: ULLM-DOD-8.7-ParallelTools
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/main.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-tool-loop-batch-*`
---
id: ULLM-DOD-8.8-StructuredOutput
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/main.tcl, lib/attractor_core/core.tcl
tests: tests/unit/unified_llm.test, tests/unit/attractor_core.test
verify: `tclsh tests/all.tcl -match unified_llm-generate-object-*`
---
id: ULLM-DOD-8.9-ParityMatrix
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl
tests: tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match integration-unified-llm-parity-*`
---
id: ULLM-DOD-8.10-Smoke
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/main.tcl
tests: tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match integration-unified-llm-parity-*`
---
id: ULLM-REQ-OPENAI-RESPONSES-ENDPOINT
spec: unified-llm-spec.md#section-4
impl: lib/unified_llm/adapters/openai.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-provider-endpoints-*`
---
id: ULLM-REQ-ANTHROPIC-ALTERNATION
spec: unified-llm-spec.md#section-4
impl: lib/unified_llm/adapters/anthropic.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-anthropic-merge-*`
---
id: ULLM-REQ-GEMINI-SYNTHETIC-TOOL-ID
spec: unified-llm-spec.md#section-4
impl: lib/unified_llm/adapters/gemini.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-gemini-synthetic-tool-id-*`
---
id: ULLM-REQ-UNKNOWN-TOOL-ERROR-RESULT
spec: unified-llm-spec.md#section-5
impl: lib/unified_llm/main.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-unknown-tool-*`
---
id: ULLM-REQ-PROMPT-MESSAGES-EXCLUSIVE
spec: unified-llm-spec.md#section-3
impl: lib/unified_llm/main.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-prompt-messages-exclusive-*`
---
id: ULLM-REQ-MODEL-CATALOG
spec: unified-llm-spec.md#section-7
impl: lib/unified_llm/main.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-model-catalog-*`
---
id: CAL-DOD-9.1-ToolRegistry
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-tool-registry-*`
---
id: CAL-DOD-9.2-ExecutionEnvironment
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/tools/core.tcl, lib/attractor_core/core.tcl
tests: tests/unit/coding_agent_loop.test, tests/unit/attractor_core.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-shell-*`
---
id: CAL-DOD-9.3-EnvFiltering
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/main.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-env-filter-*`
---
id: CAL-DOD-9.4-Cancellation
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/tools/core.tcl, lib/attractor_core/core.tcl
tests: tests/unit/coding_agent_loop.test, tests/unit/attractor_core.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-shell-cancel-*`
---
id: CAL-DOD-9.5-TruncationOrder
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/tools/core.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-truncate-order-*`
---
id: CAL-DOD-9.6-Profiles
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-profile-*`
---
id: CAL-DOD-9.7-SessionLoop
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/main.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.8-Steering
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/main.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-steer-*`
---
id: CAL-DOD-9.9-LimitsAndWarnings
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/main.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-turn-limit-*`
---
id: CAL-DOD-9.10-Events
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/main.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-session-events-*`
---
id: CAL-DOD-9.11-Subagents
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/tools/core.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-subagent-*`
---
id: CAL-DOD-9.12-ParityMatrix
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match integration-coding-agent-loop-*`
---
id: CAL-DOD-9.13-Smoke
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/main.tcl
tests: tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match integration-coding-agent-loop-*`
---
id: CAL-REQ-UNKNOWN-TOOL-ERROR
spec: coding-agent-loop-spec.md#section-5
impl: lib/coding_agent_loop/main.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-unknown-tool-*`
---
id: CAL-REQ-TOOL-END-FULL-OUTPUT
spec: coding-agent-loop-spec.md#section-2
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-tool-call-full-output-*`
---
id: CAL-REQ-EDIT-FILE-ERRORS
spec: coding-agent-loop-spec.md#section-6
impl: lib/coding_agent_loop/tools/core.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-edit-file-errors-*`
---
id: CAL-REQ-APPLY-PATCH-GRAMMAR
spec: coding-agent-loop-spec.md#section-6
impl: lib/coding_agent_loop/tools/core.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-apply-patch-*`
---
id: ATR-DOD-11.1-CoreTypes
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-parse-validate-*`
---
id: ATR-DOD-11.2-DotParser
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-parse-*`
---
id: ATR-DOD-11.3-ValidationRules
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-validate-*`
---
id: ATR-DOD-11.4-ExecutionEngine
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-run-*`
---
id: ATR-DOD-11.5-EdgeSelection
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-edge-selection-*`
---
id: ATR-DOD-11.6-Handlers
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-handler-*`
---
id: ATR-DOD-11.7-CheckpointResume
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-resume-*`
---
id: ATR-DOD-11.8-RunArtifacts
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-run-artifacts-*`
---
id: ATR-DOD-11.9-Interviewer
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-human-gate-*`
---
id: ATR-DOD-11.10-CLI
spec: attractor-spec.md#section-11
impl: bin/attractor
tests: tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match e2e-attractor-cli-*`
---
id: ATR-DOD-11.11-ResumeCLI
spec: attractor-spec.md#section-11
impl: bin/attractor
tests: tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match e2e-attractor-cli-resume-*`
---
id: ATR-DOD-11.12-ParityMatrix
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match attractor-*`
---
id: ATR-DOD-11.13-Smoke
spec: attractor-spec.md#section-11
impl: bin/attractor
tests: tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match e2e-attractor-cli-*`
---
id: ATR-REQ-START-EXIT-INVARIANTS
spec: attractor-spec.md#section-5
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-validate-start-exit-*`
---
id: ATR-REQ-CONDITION-EVAL
spec: attractor-spec.md#section-6
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-condition-*`
---
id: ATR-REQ-TOOL-HANDLER-COMMAND
spec: attractor-spec.md#section-7
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-tool-handler-*`
