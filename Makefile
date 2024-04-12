.PHONY: build
build:
	dune build

.PHONY: test
test:
	dune runtest

.PHONY: setup-dev
setup-dev:
	opam switch create . 5.1.1 --no-install
	opam install . --deps-only --with-test

.PHONY: clean-dev
clean-dev:
	opam switch remove $(shell pwd)
