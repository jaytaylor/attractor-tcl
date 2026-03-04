.PHONY: precommit build test test-e2e dev

TCLSH ?= tclsh
WEB_BIND ?= 127.0.0.1
WEB_PORT ?= 7070
WEB_RUNS_ROOT ?= .scratch/runs/attractor-web

precommit:
	@$(TCLSH) tools/build_check.tcl

build: precommit
	@$(TCLSH) tools/build_check.tcl

test: precommit
	@$(TCLSH) tests/all.tcl

test-e2e: precommit
	@$(TCLSH) tests/e2e_live.tcl

dev: precommit
	@bin/attractor serve --bind $(WEB_BIND) --web-port $(WEB_PORT) --runs-root $(WEB_RUNS_ROOT)
