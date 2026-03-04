.PHONY: precommit build test test-e2e dev

TCLSH ?= $(shell if command -v tclsh9.0 >/dev/null 2>&1; then echo tclsh9.0; else echo tclsh; fi)
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
	@if $(TCLSH) tools/tls_runtime_probe.tcl | grep -q "tls_supported=1"; then \
		$(TCLSH) tests/e2e_live.tcl; \
		node tests/e2e_playwright.mjs; \
	else \
		echo "local tls runtime unsupported; running live e2e in docker (ubuntu:24.04)"; \
		docker run --rm \
			-e OPENAI_API_KEY \
			-e ANTHROPIC_API_KEY \
			-e GEMINI_API_KEY \
			-e E2E_LIVE_PROVIDERS \
			-e OPENAI_MODEL \
			-e ANTHROPIC_MODEL \
			-e GEMINI_MODEL \
			-e OPENAI_BASE_URL \
			-e ANTHROPIC_BASE_URL \
			-e GEMINI_BASE_URL \
			-v "$$PWD":/work \
			-w /work \
			ubuntu:24.04 \
				bash -lc 'apt-get update >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y tcl tcllib tcl-tls make ca-certificates >/dev/null && tclsh tests/e2e_live.tcl'; \
		E2E_PLAYWRIGHT_USE_DOCKER=1 node tests/e2e_playwright.mjs; \
	fi

dev: precommit
	@$(TCLSH) bin/attractor serve --bind $(WEB_BIND) --web-port $(WEB_PORT) --runs-root $(WEB_RUNS_ROOT)
