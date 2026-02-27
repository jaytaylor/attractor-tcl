.PHONY: precommit build test test-e2e

precommit:
	@tclsh tools/build_check.tcl

build: precommit
	@tclsh tools/build_check.tcl

test: precommit
	@tclsh tests/all.tcl

test-e2e: precommit
	@tclsh tests/e2e_live.tcl
