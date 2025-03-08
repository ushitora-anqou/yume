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
