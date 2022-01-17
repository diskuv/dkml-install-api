# DKML Install API 0.1.0

All DKML installation components implement the interfaces exposed in this API.

## Building

On Windows with Diskuv OCaml:

```powershell
with-dkml opam install . --with-test --with-doc --deps-only
with-dkml dune build
```

On Unix:

```bash
opam install .--with-test --with-doc --deps-only
dune build
```

## Contributing

See [the Contributors section](contributors/README.md).
