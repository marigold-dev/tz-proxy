# tz-proxy

## Setup

### Opam

First, create a switch like so:

```bash
opam switch create . 5.0.0~alpha1 --no-install
```

Then you can run:

```
opam install ocamlformat
opam install ocaml-lsp-server
opam install . --deps-only --with-test
```

## Build and Test

Build the codebase with:

```
dune build
```

Run test:

```
dune build @runtest --force --no-buffer
```

