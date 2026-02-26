id: ULLM-DOD-8.1-CoreClient
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/main.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-*`
---
id: ULLM-DOD-8.7-ParallelTools
spec: unified-llm-spec.md#section-8
impl: lib/unified_llm/main.tcl
tests: tests/unit/unified_llm.test
verify: `tclsh tests/all.tcl -match unified_llm-tool-loop-*`
---
id: CAL-DOD-9.5-TruncationOrder
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/tools/core.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-truncate-order-*`
---
id: CAL-DOD-9.10-Events
spec: coding-agent-loop-spec.md#section-9
impl: lib/coding_agent_loop/main.tcl
tests: tests/unit/coding_agent_loop.test
verify: `tclsh tests/all.tcl -match coding_agent_loop-session-events-*`
---
id: ATR-DOD-11.2-DotParser
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-parse-*`
---
id: ATR-DOD-11.8-RunArtifacts
spec: attractor-spec.md#section-11
impl: lib/attractor/main.tcl
tests: tests/unit/attractor.test
verify: `tclsh tests/all.tcl -match attractor-run-artifacts-*`
---
id: ATR-DOD-11.13-Smoke
spec: attractor-spec.md#section-11
impl: bin/attractor
tests: tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match e2e-attractor-cli-*`
