.PHONY: build
build:
	dune build

.PHONY: test
test:
	dune runtest

.PHONY: setup-dev
setup-dev:
	opam install . --deps-only --with-test --with-dev-setup

.PHONY: fmt
fmt:
	dune fmt

.PHONY: list-dependencies
list-dependencies:
	nix derivation show | jq -r '.. | .inputDrvs? // empty | keys | .[]' | cut -d'-' -f 2- | sort -u
