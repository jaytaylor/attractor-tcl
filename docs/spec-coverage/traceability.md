id: ATR-REQ-BARE-IDENTIFIERS-FOR-NODE-IDS-NODE
spec: attractor-spec.md#L113
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-REQ-COMMAS-REQUIRED-BETWEEN-ATTRIBUTES-INSIDE-ATTRIBUTE
spec: attractor-spec.md#L114
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-REQ-SEMICOLONS-OPTIONAL-STATEMENT-TERMINATING-SEMICOLONS-ARE
spec: attractor-spec.md#L117
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-REQ-NODES-REPRESENT-CRITICAL-STAGES-MUST-SUCCEED
spec: attractor-spec.md#L457
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-REQ-EVERY-GRAPH-MUST-HAVE-EXACTLY-ONE
spec: attractor-spec.md#L635
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-REQ-EVERY-GRAPH-MUST-HAVE-EXACTLY-ONE-2
spec: attractor-spec.md#L647
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-REQ-HANDLERS-MUST-BE-STATELESS-OR-PROTECT
spec: attractor-spec.md#L988
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-REQ-HANDLER-PANICS-EXCEPTIONS-MUST-BE-CAUGHT
spec: attractor-spec.md#L989
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-REQ-VALIDATION-PRODUCES-LIST-DIAGNOSTICS-EACH-SEVERITY
spec: attractor-spec.md#L1378
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-REQ-HUMAN-GATES-MUST-OPERABLE-VIA-WEB
spec: attractor-spec.md#L1608
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-REQ-ALL-CLAUSES-MUST-EVALUATE-TO-TRUE
spec: attractor-spec.md#L1688
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.1-PARSER-ACCEPTS-SUPPORTED-DOT-SUBSET-DIGRAPH
spec: attractor-spec.md#L1782
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.2-GRAPH-LEVEL-ATTRIBUTES-EXTRACTED-CORRECTLY
spec: attractor-spec.md#L1783
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.3-NODE-ATTRIBUTES-PARSED-INCLUDING-MULTI-LINE
spec: attractor-spec.md#L1784
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.4-EDGE-ATTRIBUTES-PARSED-CORRECTLY
spec: attractor-spec.md#L1785
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.5-CHAINED-EDGES-PRODUCE-INDIVIDUAL-EDGES-EACH
spec: attractor-spec.md#L1786
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.6-NODE-EDGE-DEFAULT-BLOCKS-APPLY-SUBSEQUENT
spec: attractor-spec.md#L1787
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.7-SUBGRAPH-BLOCKS-FLATTENED-CONTENTS-KEPT-WRAPPER
spec: attractor-spec.md#L1788
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.8-ATTRIBUTE-NODES-MERGES-ATTRIBUTES-STYLESHEET
spec: attractor-spec.md#L1789
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.9-QUOTED-UNQUOTED-ATTRIBUTE-VALUES-BOTH
spec: attractor-spec.md#L1790
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.10-COMMENTS-STRIPPED-BEFORE-PARSING
spec: attractor-spec.md#L1791
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.11-EXACTLY-ONE-START-NODE-SHAPE-MDIAMOND
spec: attractor-spec.md#L1795
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.12-EXACTLY-ONE-EXIT-NODE-SHAPE-MSQUARE
spec: attractor-spec.md#L1796
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.13-START-NODE-HAS-INCOMING-EDGES
spec: attractor-spec.md#L1797
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.14-EXIT-NODE-HAS-OUTGOING-EDGES
spec: attractor-spec.md#L1798
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.15-ALL-NODES-REACHABLE-START-ORPHANS
spec: attractor-spec.md#L1799
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.16-ALL-EDGES-REFERENCE-VALID-NODE-IDS
spec: attractor-spec.md#L1800
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.17-CODERGEN-NODES-SHAPE-BOX-HAVE-NON
spec: attractor-spec.md#L1801
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.18-CONDITION-EXPRESSIONS-EDGES-PARSE-WITHOUT-ERRORS
spec: attractor-spec.md#L1802
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.19-THROWS-ERROR-SEVERITY-VIOLATIONS
spec: attractor-spec.md#L1803
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.20-LINT-RESULTS-INCLUDE-RULE-NAME-SEVERITY
spec: attractor-spec.md#L1804
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.21-ENGINE-RESOLVES-START-NODE-BEGINS-EXECUTION
spec: attractor-spec.md#L1808
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.22-EACH-NODE-S-HANDLER-RESOLVED-VIA
spec: attractor-spec.md#L1809
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.23-HANDLER-CALLED-NODE-CONTEXT-GRAPH-LOGSROOT
spec: attractor-spec.md#L1810
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.24-OUTCOME-WRITTEN
spec: attractor-spec.md#L1811
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.25-EDGE-SELECTION-FOLLOWS-5-STEP-PRIORITY
spec: attractor-spec.md#L1812
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.26-ENGINE-LOOPS-EXECUTE-NODE-SELECT-EDGE
spec: attractor-spec.md#L1813
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.27-TERMINAL-NODE-SHAPE-MSQUARE-STOPS-EXECUTION
spec: attractor-spec.md#L1814
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.28-PIPELINE-OUTCOME-SUCCESS-ALL-GOALGATE-NODES
spec: attractor-spec.md#L1815
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.29-NODES-TRACKED-THROUGHOUT-EXECUTION
spec: attractor-spec.md#L1819
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.30-BEFORE-ALLOWING-EXIT-VIA-TERMINAL-NODE
spec: attractor-spec.md#L1820
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.31-ANY-GOAL-GATE-NODE-HAS-SUCCEEDED
spec: attractor-spec.md#L1821
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.32-RETRYTARGET-GOAL-GATES-UNSATISFIED-PIPELINE-OUTCOME
spec: attractor-spec.md#L1822
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.33-NODES-RETRIED-RETRY-FAIL-OUTCOMES
spec: attractor-spec.md#L1826
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.34-RETRY-COUNT-TRACKED-PER-NODE-RESPECTS
spec: attractor-spec.md#L1827
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.35-BACKOFF-BETWEEN-RETRIES-CONSTANT-LINEAR-EXPONENTIAL
spec: attractor-spec.md#L1828
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.36-JITTER-APPLIED-BACKOFF-DELAYS-CONFIGURED
spec: attractor-spec.md#L1829
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.37-AFTER-RETRY-EXHAUSTION-NODE-S-FINAL
spec: attractor-spec.md#L1830
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.38-START-HANDLER-RETURNS-SUCCESS-IMMEDIATELY-OP
spec: attractor-spec.md#L1834
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.39-EXIT-HANDLER-RETURNS-SUCCESS-IMMEDIATELY-OP
spec: attractor-spec.md#L1835
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.40-CODERGEN-HANDLER-EXPANDS-PROMPT-CALLS-WRITES
spec: attractor-spec.md#L1836
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.41-WAIT-HUMAN-HANDLER-PRESENTS-OUTGOING-EDGE
spec: attractor-spec.md#L1837
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.42-CONDITIONAL-HANDLER-PASSES-THROUGH-ENGINE-EVALUATES
spec: attractor-spec.md#L1838
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.43-PARALLEL-HANDLER-FANS-OUT-MULTIPLE-TARGET
spec: attractor-spec.md#L1839
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.44-FAN-HANDLER-WAITS-ALL-PARALLEL-BRANCHES
spec: attractor-spec.md#L1840
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.45-TOOL-HANDLER-EXECUTES-CONFIGURED-TOOL-COMMAND
spec: attractor-spec.md#L1841
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.46-CUSTOM-HANDLERS-CAN-REGISTERED-TYPE-STRING
spec: attractor-spec.md#L1842
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.47-CONTEXT-KEY-VALUE-STORE-ACCESSIBLE-ALL
spec: attractor-spec.md#L1846
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.48-HANDLERS-CAN-READ-CONTEXT-RETURN-OUTCOME
spec: attractor-spec.md#L1847
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.49-CONTEXT-UPDATES-MERGED-AFTER-EACH-NODE
spec: attractor-spec.md#L1848
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.50-CHECKPOINT-SAVED-AFTER-EACH-NODE-COMPLETION
spec: attractor-spec.md#L1849
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.51-RESUME-CHECKPOINT-LOAD-CHECKPOINT-RESTORE-STATE
spec: attractor-spec.md#L1850
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.52-ARTIFACTS-WRITTEN-PROMPT-MD-RESPONSE-MD
spec: attractor-spec.md#L1851
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.53-INTERVIEWER-INTERFACE
spec: attractor-spec.md#L1855
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.54-QUESTION-SUPPORTS-TYPES-SINGLESELECT-MULTISELECT-FREETEXT
spec: attractor-spec.md#L1856
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.55-AUTOAPPROVEINTERVIEWER-ALWAYS-SELECTS-FIRST-OPTION-AUTOMATION
spec: attractor-spec.md#L1857
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.56-CONSOLEINTERVIEWER-PROMPTS-TERMINAL-READS-USER-INPUT
spec: attractor-spec.md#L1858
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.57-CALLBACKINTERVIEWER-DELEGATES-PROVIDED-FUNCTION
spec: attractor-spec.md#L1859
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.58-QUEUEINTERVIEWER-READS-PRE-FILLED-ANSWER-QUEUE
spec: attractor-spec.md#L1860
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.59-EQUALS-OPERATOR-STRING-COMPARISON
spec: attractor-spec.md#L1864
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.60-EQUALS-OPERATOR
spec: attractor-spec.md#L1865
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.61-CONJUNCTION-MULTIPLE-CLAUSES
spec: attractor-spec.md#L1866
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.62-VARIABLE-RESOLVES-CURRENT-NODE-S-OUTCOME
spec: attractor-spec.md#L1867
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.63-VARIABLE-RESOLVES-OUTCOME-S-PREFERRED-LABEL
spec: attractor-spec.md#L1868
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.64-VARIABLES-RESOLVE-CONTEXT-VALUES-MISSING-KEYS
spec: attractor-spec.md#L1869
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.65-EMPTY-CONDITION-ALWAYS-EVALUATES-TRUE-UNCONDITIONAL
spec: attractor-spec.md#L1870
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.66-STYLESHEET-PARSED-GRAPH-S-ATTRIBUTE
spec: attractor-spec.md#L1874
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.67-SELECTORS-SHAPE-NAME-E-G
spec: attractor-spec.md#L1875
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.68-SELECTORS-CLASS-NAME-E-G
spec: attractor-spec.md#L1876
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.69-SELECTORS-NODE-ID-E-G
spec: attractor-spec.md#L1877
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.70-SPECIFICITY-ORDER-UNIVERSAL-SHAPE-CLASS-ID
spec: attractor-spec.md#L1878
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.71-STYLESHEET-PROPERTIES-OVERRIDDEN-EXPLICIT-NODE-ATTRIBUTES
spec: attractor-spec.md#L1879
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.72-AST-TRANSFORMS-CAN-MODIFY-GRAPH-BETWEEN
spec: attractor-spec.md#L1883
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.73-TRANSFORM-INTERFACE
spec: attractor-spec.md#L1884
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.74-BUILT-VARIABLE-EXPANSION-TRANSFORM-REPLACES-PROMPTS
spec: attractor-spec.md#L1885
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.75-CUSTOM-TRANSFORMS-CAN-REGISTERED-RUN-ORDER
spec: attractor-spec.md#L1886
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-DOD-11.76-HTTP-SERVER-MODE-IMPLEMENTED-POST-RUN
spec: attractor-spec.md#L1887
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: ATR-REQ-TERMINAL-ERRORS-PERMANENT-FAILURES-RE-EXECUTION
spec: attractor-spec.md#L2081
impl: lib/attractor/main.tcl, bin/attractor
tests: tests/unit/attractor.test, tests/integration/attractor_integration.test, tests/e2e/attractor_cli_e2e.test
verify: `tclsh tests/all.tcl -match *attractor*`
---
id: CAL-REQ-SYSTEM-PROMPT-SHOULD-MIRROR-CLAUDE-CODE
spec: coding-agent-loop-spec.md#L632
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-REQ-THESE-REQUIRED-IMPLEMENTATIONS-THEY-DEMONSTRATE-EXTENSIBILITY
spec: coding-agent-loop-spec.md#L781
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-REQ-TOOL-OUTPUT-EXCEEDS-CONFIGURED-LIMIT-MUST
spec: coding-agent-loop-spec.md#L843
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-REQ-CHARACTER-BASED-TRUNCATION-SECTION-5-1
spec: coding-agent-loop-spec.md#L889
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-REQ-WHY-CHARACTER-TRUNCATION-MUST-COME-FIRST
spec: coding-agent-loop-spec.md#L935
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-REQ-ANTHROPIC-PROFILE-MIRROR-CLAUDE-CODE-SYSTEM
spec: coding-agent-loop-spec.md#L996
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-REQ-SPEC-DOES-PRESCRIBE-FULL-SYSTEM-PROMPT
spec: coding-agent-loop-spec.md#L999
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.1-SESSION-CAN-CREATED-PROVIDERPROFILE-EXECUTIONENVIRONMENT
spec: coding-agent-loop-spec.md#L1141
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.2-RUNS-AGENTIC-LOOP-LLM-CALL-TOOL
spec: coding-agent-loop-spec.md#L1142
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.3-NATURAL-COMPLETION-MODEL-RESPONDS-TEXT-ONLY
spec: coding-agent-loop-spec.md#L1143
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.4-ROUND-LIMITS-STOPS-LOOP-REACHED
spec: coding-agent-loop-spec.md#L1144
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.5-SESSION-TURN-LIMITS-STOPS-LOOP-ACROSS
spec: coding-agent-loop-spec.md#L1145
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.6-ABORT-SIGNAL-CANCELLATION-STOPS-LOOP-KILLS
spec: coding-agent-loop-spec.md#L1146
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.7-LOOP-DETECTION-CONSECUTIVE-IDENTICAL-TOOL-CALL
spec: coding-agent-loop-spec.md#L1147
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.8-MULTIPLE-SEQUENTIAL-INPUTS-SUBMIT-WAIT-COMPLETION
spec: coding-agent-loop-spec.md#L1148
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.9-OPENAI-PROFILE-PROVIDES-CODEX-RS-ALIGNED
spec: coding-agent-loop-spec.md#L1152
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.10-ANTHROPIC-PROFILE-PROVIDES-CLAUDE-CODE-ALIGNED
spec: coding-agent-loop-spec.md#L1153
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.11-GEMINI-PROFILE-PROVIDES-GEMINI-CLI-ALIGNED
spec: coding-agent-loop-spec.md#L1154
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.12-EACH-PROFILE-PRODUCES-PROVIDER-SPECIFIC-SYSTEM
spec: coding-agent-loop-spec.md#L1155
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.13-CUSTOM-TOOLS-CAN-REGISTERED-TOP-ANY
spec: coding-agent-loop-spec.md#L1156
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.14-TOOL-NAME-COLLISIONS-RESOLVED-CUSTOM-REGISTRATION
spec: coding-agent-loop-spec.md#L1157
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.15-TOOL-CALLS-DISPATCHED-THROUGH-TOOLREGISTRY
spec: coding-agent-loop-spec.md#L1161
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.16-UNKNOWN-TOOL-CALLS-RETURN-ERROR-RESULT
spec: coding-agent-loop-spec.md#L1162
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.17-TOOL-ARGUMENT-JSON-PARSED-VALIDATED-AGAINST
spec: coding-agent-loop-spec.md#L1163
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.18-TOOL-EXECUTION-ERRORS-CAUGHT-RETURNED-ERROR
spec: coding-agent-loop-spec.md#L1164
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.19-PARALLEL-TOOL-EXECUTION-PROFILE-S-TRUE
spec: coding-agent-loop-spec.md#L1165
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.20-IMPLEMENTS-ALL-FILE-COMMAND-OPERATIONS
spec: coding-agent-loop-spec.md#L1169
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.21-COMMAND-TIMEOUT-DEFAULT-10-SECONDS
spec: coding-agent-loop-spec.md#L1170
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.22-COMMAND-TIMEOUT-OVERRIDABLE-PER-CALL-VIA
spec: coding-agent-loop-spec.md#L1171
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.23-TIMED-OUT-COMMANDS-PROCESS-GROUP-RECEIVES
spec: coding-agent-loop-spec.md#L1172
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.24-ENVIRONMENT-VARIABLE-FILTERING-EXCLUDES-SENSITIVE-VARIABLES
spec: coding-agent-loop-spec.md#L1173
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.25-INTERFACE-IMPLEMENTABLE-CONSUMERS-CUSTOM-ENVIRONMENTS-DOCKER
spec: coding-agent-loop-spec.md#L1174
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.26-CHARACTER-BASED-TRUNCATION-RUNS-FIRST-ALL
spec: coding-agent-loop-spec.md#L1178
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.27-LINE-BASED-TRUNCATION-RUNS-SECOND-CONFIGURED
spec: coding-agent-loop-spec.md#L1179
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.28-TRUNCATION-INSERTS-VISIBLE-MARKER
spec: coding-agent-loop-spec.md#L1180
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.29-FULL-UNTRUNCATED-OUTPUT-AVAILABLE-VIA-EVENT
spec: coding-agent-loop-spec.md#L1181
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.30-DEFAULT-CHARACTER-LIMITS-MATCH-TABLE-SECTION
spec: coding-agent-loop-spec.md#L1182
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.31-BOTH-CHARACTER-LINE-LIMITS-OVERRIDABLE-VIA
spec: coding-agent-loop-spec.md#L1183
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.32-QUEUES-MESSAGE-INJECTED-AFTER-CURRENT-TOOL
spec: coding-agent-loop-spec.md#L1187
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.33-QUEUES-MESSAGE-PROCESSED-AFTER-CURRENT-INPUT
spec: coding-agent-loop-spec.md#L1188
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.34-STEERING-MESSAGES-APPEAR-STEERINGTURN-HISTORY
spec: coding-agent-loop-spec.md#L1189
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.35-STEERINGTURNS-CONVERTED-USER-ROLE-MESSAGES-LLM
spec: coding-agent-loop-spec.md#L1190
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.36-PASSED-THROUGH-LLM-SDK-REQUEST
spec: coding-agent-loop-spec.md#L1194
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.37-CHANGING-MID-SESSION-TAKES-EFFECT-NEXT
spec: coding-agent-loop-spec.md#L1195
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.38-VALID-VALUES-LOW-MEDIUM-HIGH-NULL
spec: coding-agent-loop-spec.md#L1196
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.39-SYSTEM-PROMPT-INCLUDES-PROVIDER-SPECIFIC-BASE
spec: coding-agent-loop-spec.md#L1200
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.40-SYSTEM-PROMPT-INCLUDES-ENVIRONMENT-CONTEXT-PLATFORM
spec: coding-agent-loop-spec.md#L1201
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.41-SYSTEM-PROMPT-INCLUDES-TOOL-DESCRIPTIONS-ACTIVE
spec: coding-agent-loop-spec.md#L1202
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.42-PROJECT-DOCUMENTATION-FILES-AGENTS-MD-PROVIDER
spec: coding-agent-loop-spec.md#L1203
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.43-USER-INSTRUCTION-OVERRIDES-APPENDED-LAST-HIGHEST
spec: coding-agent-loop-spec.md#L1204
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.44-ONLY-RELEVANT-PROJECT-FILES-LOADED-E
spec: coding-agent-loop-spec.md#L1205
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.45-SUBAGENTS-CAN-SPAWNED-SCOPED-TASK-VIA
spec: coding-agent-loop-spec.md#L1209
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.46-SUBAGENTS-SHARE-PARENT-S-EXECUTION-ENVIRONMENT
spec: coding-agent-loop-spec.md#L1210
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.47-SUBAGENTS-MAINTAIN-INDEPENDENT-CONVERSATION-HISTORY
spec: coding-agent-loop-spec.md#L1211
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.48-DEPTH-LIMITING-PREVENTS-RECURSIVE-SPAWNING-DEFAULT
spec: coding-agent-loop-spec.md#L1212
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.49-SUBAGENT-RESULTS-RETURNED-PARENT-TOOL-RESULTS
spec: coding-agent-loop-spec.md#L1213
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.50-TOOLS-CORRECTLY
spec: coding-agent-loop-spec.md#L1214
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.51-ALL-EVENT-KINDS-LISTED-SECTION-2
spec: coding-agent-loop-spec.md#L1218
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.52-EVENTS-DELIVERED-VIA-ASYNC-ITERATOR-LANGUAGE
spec: coding-agent-loop-spec.md#L1219
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.53-EVENTS-CARRY-FULL-UNTRUNCATED-TOOL-OUTPUT
spec: coding-agent-loop-spec.md#L1220
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.54-SESSION-LIFECYCLE-EVENTS-SESSIONSTART-SESSIONEND-BRACKET
spec: coding-agent-loop-spec.md#L1221
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.55-TOOL-EXECUTION-ERRORS-ERROR-RESULT-SENT
spec: coding-agent-loop-spec.md#L1225
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.56-LLM-API-TRANSIENT-ERRORS-429-500
spec: coding-agent-loop-spec.md#L1226
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.57-AUTHENTICATION-ERRORS-SURFACE-IMMEDIATELY-RETRY-SESSION
spec: coding-agent-loop-spec.md#L1227
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.58-CONTEXT-WINDOW-OVERFLOW-EMIT-WARNING-EVENT
spec: coding-agent-loop-spec.md#L1228
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: CAL-DOD-9.59-GRACEFUL-SHUTDOWN-ABORT-SIGNAL-CANCEL-LLM
spec: coding-agent-loop-spec.md#L1229
impl: lib/coding_agent_loop/main.tcl, lib/coding_agent_loop/tools/core.tcl, lib/coding_agent_loop/profiles/openai.tcl, lib/coding_agent_loop/profiles/anthropic.tcl, lib/coding_agent_loop/profiles/gemini.tcl
tests: tests/unit/coding_agent_loop.test, tests/integration/coding_agent_loop_integration.test
verify: `tclsh tests/all.tcl -match *coding_agent_loop*`
---
id: ULLM-REQ-LAYER-1-PROVIDER-SPECIFICATION-DEFINES-CONTRACT
spec: unified-llm-spec.md#L68
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-STREAMING-MIDDLEWARE-MIDDLEWARE-MUST-ALSO-APPLY
spec: unified-llm-spec.md#L141
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-EVERY-PROVIDER-MUST-IMPLEMENT-INTERFACE
spec: unified-llm-spec.md#L161
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-THESE-METHODS-RECOMMENDED-BUT-REQUIRED
spec: unified-llm-spec.md#L180
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-MULTIPLE-CONCURRENT-REQUESTS-DIFFERENT-PROVIDERS-SAME
spec: unified-llm-spec.md#L208
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-EACH-PROVIDER-ADAPTER-MUST-USE-PROVIDER
spec: unified-llm-spec.md#L212
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-PROVIDERS-FREQUENTLY-GATE-NEW-FEATURES-BEHIND
spec: unified-llm-spec.md#L224
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-THESE-MUST-PASSED-HTTP-HEADERS-REQUEST
spec: unified-llm-spec.md#L232
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-IMPLEMENTATIONS-SHOULD-DEFAULT-LATEST-AVAILABLE-MODELS
spec: unified-llm-spec.md#L281
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-WHY-CATALOG-MATTERS-CODING-AGENTS-AI
spec: unified-llm-spec.md#L326
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-PROMPT-CACHING-ALLOWS-PROVIDERS-REUSE-COMPUTATION
spec: unified-llm-spec.md#L332
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-ANTHROPIC-ONLY-PROVIDER-SDK-MUST-DO
spec: unified-llm-spec.md#L340
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-ALL-THREE-PROVIDERS-REPORT-CACHE-STATISTICS
spec: unified-llm-spec.md#L342
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-EXACTLY-ONE-MUST-PROVIDED-ADAPTER-BASE64
spec: unified-llm-spec.md#L475
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-IMAGE-UPLOAD-CRITICAL-MULTIMODAL-CAPABILITIES-MANY
spec: unified-llm-spec.md#L477
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-FIELD-ASSIGNED-PROVIDER-REQUIRED-LINKING-TOOL
spec: unified-llm-spec.md#L519
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-THINKING-BLOCKS-ANTHROPIC-S-EXTENDED-THINKING
spec: unified-llm-spec.md#L543
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-USAGE-OBJECTS-MUST-SUPPORT-ADDITION-AGGREGATING
spec: unified-llm-spec.md#L664
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-THE-RESPONSES-API-IS-REQUIRED-FOR
spec: unified-llm-spec.md#L688
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-THINKING-BLOCKS-CARRY-A-FIELD-THAT
spec: unified-llm-spec.md#L696
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-WHY-MATTERS-SWITCHING-BETWEEN-PROVIDERS-REASONING
spec: unified-llm-spec.md#L703
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-MUST-BE-CONSUMED-OR-EXPLICITLY-CLOSED
spec: unified-llm-spec.md#L841
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-TOOL-NAME-CONSTRAINTS-NAMES-MUST-VALID
spec: unified-llm-spec.md#L1062
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-PARAMETER-SCHEMA-PARAMETERS-MUST-DEFINED-JSON
spec: unified-llm-spec.md#L1064
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-NOTE-ANTHROPIC-MODE-ANTHROPIC-DOES-SUPPORT
spec: unified-llm-spec.md#L1144
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-MODEL-RETURNS-MULTIPLE-TOOL-CALLS-SINGLE
spec: unified-llm-spec.md#L1222
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-2-WAIT-ALL-RESULTS-BEFORE-CONTINUING
spec: unified-llm-spec.md#L1225
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-EACH-ADAPTER-MUST-IMPLEMENT
spec: unified-llm-spec.md#L1475
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-ADAPTER-MUST-TRANSLATE-UNIFIED-PROVIDER-S
spec: unified-llm-spec.md#L1495
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-STRICT-ALTERNATION-ANTHROPIC-REQUIRES-ALTERNATING-USER
spec: unified-llm-spec.md#L1560
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-THINKING-BLOCK-ROUND-TRIPPING-THINKING-AND
spec: unified-llm-spec.md#L1562
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-MAX-TOKENS-IS-REQUIRED-ANTHROPIC-ALWAYS
spec: unified-llm-spec.md#L1563
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-TOOL-CALL-IDS-GEMINI-DOES-NOT
spec: unified-llm-spec.md#L1585
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-ADAPTER-MUST-PARSE-PROVIDER-S-RESPONSE
spec: unified-llm-spec.md#L1600
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-ADAPTER-MUST-TRANSLATE-HTTP-ERRORS-ERROR
spec: unified-llm-spec.md#L1610
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-MOST-PROVIDERS-USE-SERVER-SENT-EVENTS
spec: unified-llm-spec.md#L1644
impl: lib/attractor_core/core.tcl, lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl
tests: tests/unit/attractor_core.test, tests/unit/unified_llm_streaming.test
verify: `tclsh tests/all.tcl -match *attractor_core-sse*`
---
id: ULLM-REQ-RESPONSES-API-STREAMING-FORMAT-PROVIDES-REASONING
spec: unified-llm-spec.md#L1675
impl: lib/unified_llm/adapters/openai.tcl, tests/fixtures/unified_llm_streaming/openai/openai-text.sse
tests: tests/unit/unified_llm_streaming.test
verify: `tclsh tests/all.tcl -match *unified_llm-openai-stream-translation-text*`
---
id: ULLM-REQ-SUMMARY-PROVIDER-SPECIFIC-BEHAVIORS-ADAPTERS-MUST
spec: unified-llm-spec.md#L1730
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-REQ-CONTINUING-CONVERSATION-INCLUDES-THINKING-BLOCKS-THINKING
spec: unified-llm-spec.md#L1847
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.1-CAN-CONSTRUCTED-ENVIRONMENT-VARIABLES
spec: unified-llm-spec.md#L1973
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.2-CAN-CONSTRUCTED-PROGRAMMATICALLY-EXPLICIT-ADAPTER-INSTANCES
spec: unified-llm-spec.md#L1974
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.3-PROVIDER-ROUTING-REQUESTS-DISPATCHED-CORRECT-ADAPTER
spec: unified-llm-spec.md#L1975
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.4-DEFAULT-PROVIDER-USED-OMITTED-REQUEST
spec: unified-llm-spec.md#L1976
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.5-RAISED-PROVIDER-CONFIGURED-DEFAULT-SET
spec: unified-llm-spec.md#L1977
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.6-MIDDLEWARE-CHAIN-EXECUTES-CORRECT-ORDER-REQUEST
spec: unified-llm-spec.md#L1978
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.7-MODULE-LEVEL-DEFAULT-CLIENT-IMPLICIT-LAZY
spec: unified-llm-spec.md#L1979
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.8-MODEL-CATALOG-POPULATED-CURRENT-MODELS-RETURN
spec: unified-llm-spec.md#L1980
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.9-ADAPTER-USES-PROVIDER-S-NATIVE-API
spec: unified-llm-spec.md#L1986
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.10-AUTHENTICATION-API-KEY-ENV-VAR-EXPLICIT
spec: unified-llm-spec.md#L1987
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.11-SENDS-REQUEST-RETURNS-CORRECTLY-POPULATED
spec: unified-llm-spec.md#L1988
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.12-RETURNS-ASYNC-ITERATOR-CORRECTLY-TYPED-OBJECTS
spec: unified-llm-spec.md#L1989
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.13-SYSTEM-MESSAGES-EXTRACTED-HANDLED-PER-PROVIDER
spec: unified-llm-spec.md#L1990
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.14-ALL-5-ROLES-SYSTEM-USER-ASSISTANT
spec: unified-llm-spec.md#L1991
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.15-ESCAPE-HATCH-PASSES-THROUGH-PROVIDER-SPECIFIC
spec: unified-llm-spec.md#L1992
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.16-BETA-HEADERS-SUPPORTED-ESPECIALLY-ANTHROPIC-S
spec: unified-llm-spec.md#L1993
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.17-HTTP-ERRORS-TRANSLATED-CORRECT-ERROR-HIERARCHY
spec: unified-llm-spec.md#L1994
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.18-HEADERS-PARSED-SET-ERROR-OBJECT
spec: unified-llm-spec.md#L1995
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.19-MESSAGES-TEXT-ONLY-CONTENT-ACROSS-ALL
spec: unified-llm-spec.md#L1999
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.20-IMAGE-INPUT-IMAGES-SENT-URL-BASE64
spec: unified-llm-spec.md#L2000
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.21-AUDIO-DOCUMENT-CONTENT-PARTS-HANDLED-GRACEFULLY
spec: unified-llm-spec.md#L2001
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.22-TOOL-CALL-CONTENT-PARTS-ROUND-TRIP
spec: unified-llm-spec.md#L2002
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.23-THINKING-BLOCKS-ANTHROPIC-PRESERVED-ROUND-TRIPPED
spec: unified-llm-spec.md#L2003
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.24-REDACTED-THINKING-BLOCKS-PASSED-THROUGH-VERBATIM
spec: unified-llm-spec.md#L2004
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.25-MULTIMODAL-MESSAGES-TEXT-IMAGES-SAME-MESSAGE
spec: unified-llm-spec.md#L2005
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.26-SIMPLE-TEXT
spec: unified-llm-spec.md#L2009
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.27-FULL-LIST
spec: unified-llm-spec.md#L2010
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.28-REJECTS-BOTH-PROVIDED
spec: unified-llm-spec.md#L2011
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.29-YIELDS-EVENTS-CONCATENATE-FULL-RESPONSE-TEXT
spec: unified-llm-spec.md#L2012
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, tests/fixtures/unified_llm_streaming/openai/openai-text.sse
tests: tests/unit/unified_llm_streaming.test
verify: `tclsh tests/all.tcl -match *unified_llm-stream-events-concatenate*`
---
id: ULLM-DOD-8.30-YIELDS-EVENTS-CORRECT-METADATA
spec: unified-llm-spec.md#L2013
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl
tests: tests/unit/unified_llm_streaming.test
verify: `tclsh tests/all.tcl -match *unified_llm-openai-stream-translation-text*`
---
id: ULLM-DOD-8.31-STREAMING-FOLLOWS-START-DELTA-END-PATTERN
spec: unified-llm-spec.md#L2014
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl
tests: tests/unit/unified_llm.test, tests/unit/unified_llm_streaming.test
verify: `tclsh tests/all.tcl -match *unified_llm-stream-event-model*`
---
id: ULLM-DOD-8.32-RETURNS-PARSED-VALIDATED-STRUCTURED-OUTPUT
spec: unified-llm-spec.md#L2015
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.33-RAISES-PARSE-VALIDATION-FAILURE
spec: unified-llm-spec.md#L2016
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.34-CANCELLATION-VIA-ABORT-SIGNAL-BOTH
spec: unified-llm-spec.md#L2017
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.35-TIMEOUTS-TOTAL-TIMEOUT-PER-STEP-TIMEOUT
spec: unified-llm-spec.md#L2018
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.36-OPENAI-REASONING-MODELS-GPT-5-2
spec: unified-llm-spec.md#L2022
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.37-PARAMETER-PASSED-THROUGH-CORRECTLY-OPENAI-REASONING
spec: unified-llm-spec.md#L2023
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.38-ANTHROPIC-EXTENDED-THINKING-BLOCKS-RETURNED-CONTENT
spec: unified-llm-spec.md#L2024
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.39-THINKING-BLOCK-FIELD-PRESERVED-ROUND-TRIPPING
spec: unified-llm-spec.md#L2025
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.40-GEMINI-THINKING-TOKENS-MAPPED
spec: unified-llm-spec.md#L2026
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.41-CORRECTLY-REPORTS-DISTINCT
spec: unified-llm-spec.md#L2027
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.42-OPENAI-CACHING-AUTOMATICALLY-VIA-RESPONSES-API
spec: unified-llm-spec.md#L2031
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.43-OPENAI-POPULATED
spec: unified-llm-spec.md#L2032
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.44-ANTHROPIC-ADAPTER-AUTOMATICALLY-INJECTS-BREAKPOINTS-SYSTEM
spec: unified-llm-spec.md#L2033
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.45-ANTHROPIC-BETA-HEADER-INCLUDED-AUTOMATICALLY-CACHECONTROL
spec: unified-llm-spec.md#L2034
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.46-ANTHROPIC-POPULATED-CORRECTLY
spec: unified-llm-spec.md#L2035
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.47-ANTHROPIC-AUTOMATIC-CACHING-CAN-DISABLED-VIA
spec: unified-llm-spec.md#L2036
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.48-GEMINI-AUTOMATIC-PREFIX-CACHING-CLIENT-SIDE
spec: unified-llm-spec.md#L2037
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.49-GEMINI-POPULATED
spec: unified-llm-spec.md#L2038
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.50-MULTI-TURN-AGENTIC-SESSION-VERIFY-TURN
spec: unified-llm-spec.md#L2039
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.51-TOOLS-HANDLERS-ACTIVE-TOOLS-TRIGGER-AUTOMATIC
spec: unified-llm-spec.md#L2043
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.52-TOOLS-WITHOUT-HANDLERS-PASSIVE-TOOLS-RETURN
spec: unified-llm-spec.md#L2044
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.53-RESPECTED-LOOP-STOPS-AFTER-CONFIGURED-NUMBER
spec: unified-llm-spec.md#L2045
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.54-DISABLES-AUTOMATIC-EXECUTION-ENTIRELY
spec: unified-llm-spec.md#L2046
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.55-PARALLEL-TOOL-CALLS-MODEL-RETURNS-N
spec: unified-llm-spec.md#L2047
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.56-PARALLEL-TOOL-RESULTS-ALL-N-RESULTS
spec: unified-llm-spec.md#L2048
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.57-TOOL-EXECUTION-ERRORS-SENT-MODEL-ERROR
spec: unified-llm-spec.md#L2049
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.58-UNKNOWN-TOOL-CALLS-MODEL-CALLS-TOOL
spec: unified-llm-spec.md#L2050
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.59-MODES-AUTO-NONE-REQUIRED-NAMED-TRANSLATED
spec: unified-llm-spec.md#L2051
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.60-TOOL-CALL-ARGUMENT-JSON-PARSED-VALIDATED
spec: unified-llm-spec.md#L2052
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.61-OBJECTS-TRACK-EACH-STEP-S-TOOL
spec: unified-llm-spec.md#L2053
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.62-ALL-ERRORS-HIERARCHY-RAISED-CORRECT-HTTP
spec: unified-llm-spec.md#L2057
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.63-FLAG-SET-CORRECTLY-EACH-ERROR-TYPE
spec: unified-llm-spec.md#L2058
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.64-EXPONENTIAL-BACKOFF-JITTER-DELAYS-INCREASE-CORRECTLY
spec: unified-llm-spec.md#L2059
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.65-HEADER-OVERRIDES-CALCULATED-BACKOFF-PRESENT-WITHIN
spec: unified-llm-spec.md#L2060
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.66-DISABLES-AUTOMATIC-RETRIES
spec: unified-llm-spec.md#L2061
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.67-RATE-LIMIT-ERRORS-429-RETRIED-TRANSPARENTLY
spec: unified-llm-spec.md#L2062
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.68-NON-RETRYABLE-ERRORS-401-403-404
spec: unified-llm-spec.md#L2063
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.69-RETRIES-APPLY-PER-STEP-ENTIRE-MULTI
spec: unified-llm-spec.md#L2064
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, lib/unified_llm/adapters/anthropic.tcl, lib/unified_llm/adapters/gemini.tcl, lib/unified_llm/models.json
tests: tests/unit/unified_llm.test, tests/integration/unified_llm_parity.test
verify: `tclsh tests/all.tcl -match *unified*`
---
id: ULLM-DOD-8.70-STREAMING-DOES-RETRY-AFTER-PARTIAL-DATA
spec: unified-llm-spec.md#L2065
impl: lib/unified_llm/main.tcl, lib/unified_llm/adapters/openai.tcl, tests/fixtures/unified_llm_streaming/malformed/openai-invalid-json-after-partial.sse
tests: tests/unit/unified_llm_streaming.test
verify: `tclsh tests/all.tcl -match *unified_llm-stream-no-retry-after-partial*`
