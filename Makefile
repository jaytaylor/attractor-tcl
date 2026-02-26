.PHONY: precommit build test

precommit:
	@tclsh tools/build_check.tcl

build: precommit
	@tclsh tools/build_check.tcl

test: precommit
	@tclsh tests/all.tcl
