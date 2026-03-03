.PHONY: precommit build test test-e2e

TCLSH ?= tclsh

precommit:
	@$(TCLSH) tools/build_check.tcl

build: precommit
	@$(TCLSH) tools/build_check.tcl

test: precommit
	@$(TCLSH) tests/all.tcl

test-e2e: precommit
	@$(TCLSH) tests/e2e_live.tcl
