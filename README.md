# DKML Install API 0.1.0

The DKML Install API lets you take the tools you know (OCaml and Opam) and
well-known¹ installer generators, to generate a installer for your OCaml
project.

> ¹ *Well-known* is an aspiration. Currently only a simple CLI installer
> generator is available, but other well-known installer generators like
> 0install or cpack could be added in the future.

Specifically the DKML Install API lets you take a) pre-designed packages from
Opam and b) installation instructions written in OCaml source code, and
assembles binary artifacts that act as the primary materials to installer
generators.

The full documentation is available at https://diskuv.github.io/dkml-install-api/index.html

The OCaml module documentation is available at https://diskuv.github.io/dkml-install-api/odoc/index.html

## Installing

Make sure you have Opam installed and then run:

```bash
opam install dkml-install-api
```

## Building from Source

On Windows with Diskuv OCaml:

```powershell
with-dkml opam install . --with-test --with-doc --deps-only
with-dkml dune build
with-dkml dune build `@doc
```

On Unix:

```bash
opam install .--with-test --with-doc --deps-only
dune build
dune build @doc
```

## Contributing

See [the Contributors section](contributors/README.md).
