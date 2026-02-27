# Spec Coverage Workflow

This directory contains spec-derived requirement artifacts and traceability mappings.

## Files
- `requirements_id_scheme.md`: canonical `req_id` format and validation rules.
- `requirements.json`: generated machine-readable requirement catalog.
- `requirements.md`: generated human-readable summary.
- `traceability.md`: requirement-to-implementation/test mapping blocks.

## Update Workflow
1. Edit spec docs (`unified-llm-spec.md`, `coding-agent-loop-spec.md`, `attractor-spec.md`).
2. Add or update `req_id` comments on:
- every checkbox in each spec's `Definition of Done` section
- every normative statement containing `MUST`, `MUST NOT`, or `REQUIRED` (outside code fences).
3. Validate IDs:
- `tclsh tools/requirements_catalog.tcl --check-ids`
4. Regenerate catalog artifacts:
- `tclsh tools/requirements_catalog.tcl`
5. Update traceability mappings:
- `tclsh .scratch/generate_traceability_from_catalog.tcl`
- Manually refine `impl/tests/verify` mappings where needed.
6. Validate coverage completeness and mapping quality:
- `tclsh tools/spec_coverage.tcl`
7. Run focused tests:
- `tclsh tests/all.tcl -match requirements_catalog-*`
- `tclsh tests/all.tcl -match integration-spec-coverage-tool-*`
- `tclsh tests/all.tcl -match integration-verify-sanity-*`
8. Run full build + test before merging:
- `make build`
- `make test`

## Common Failures
- `MISSING_REQ_ID`: spec line matched required scope but lacks `req_id` comment.
- `BAD_REQ_ID_FORMAT`: ID does not match scheme.
- `MISSING_REQUIREMENT`: catalog contains ID missing from traceability.
- `UNKNOWN_REQUIREMENT`: traceability contains ID not present in catalog.
- `BAD_VERIFY_PATTERN`: verify command pattern does not match any real test name.
