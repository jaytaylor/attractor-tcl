# Requirement ID Scheme

The requirement catalog uses explicit `req_id` annotations in spec markdown lines.

## Formats
- DoD requirement: `<FAMILY>-DOD-<section>.<item>-<SLUG>`
- Normative requirement: `<FAMILY>-REQ-<SLUG>`

## Families
- `ULLM` for `unified-llm-spec.md`
- `CAL` for `coding-agent-loop-spec.md`
- `ATR` for `attractor-spec.md`

## Rules
- IDs are uppercase and use `-` separators.
- IDs must be unique across all specs.
- Every DoD checkbox line under each spec's `Definition of Done` section must include a `req_id`.
- Every normative statement containing `MUST`, `MUST NOT`, or `REQUIRED` (case-insensitive, outside code fences) must include a `req_id`.

## Annotation Syntax
Append an HTML comment to the relevant source line:

```markdown
- [ ] Example DoD checkbox <!-- req_id: ULLM-DOD-8.1-EXAMPLE-CHECKBOX -->
```

```markdown
Each adapter MUST use the native API. <!-- req_id: ULLM-REQ-EACH-ADAPTER-MUST-USE-NATIVE-API -->
```

## Validation
`tools/requirements_catalog.tcl --check-ids` enforces:
- required `req_id` coverage for DoD + normative scope
- ID format correctness
- cross-spec uniqueness
