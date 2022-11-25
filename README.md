# Tz-Proxy

Tz-Proxy is a reverse proxy specificly for Tezos Nodes written entirely in OCaml.

## Features

- [x] Rate limit on Requests
- [x] Blocklist for IPs
- [x] Blocklist for endpoints routes

## Setup 

Run the nix command:

```bash
nix develop -L -c $SHELL
```

Build the codebase with:

```
dune build
```

Run test:

```
dune build @runtest --force --no-buffer
```

