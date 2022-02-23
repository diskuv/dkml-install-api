### Developing

> At the moment this is little more than a scratchpad. Once enough is here it
> will be re-organized for public consumption.

```powershell
Z:\source\dkml-install-api> (& opam env --switch Z:\source\dkml-install-api --set-switch) -split '\r?\n' | ForEach-Object { Invoke-Expression $_ }
Z:\source\dkml-install-api> with-dkml opam install ./dkml-install.opam 

Z:\source\...kernel> (& opam env --switch Z:\source\dkml-install-api --set-switch) -split '\r?\n' | ForEach-Object { Invoke-Expression $_ }
Z:\source\...kernel> with-dkml opam install ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-ocamlcompiler.opam ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-ocamlrun.opam


Z:\source\...kernel> with-dkml opam install  ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-ocamlcompiler.opam ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-ocamlrun.opam ..\..\..\dkml-install-api\dkml-install.opam  ..\..\..\dkml-install-api\dkml-install-runner.opam

Z:\source\dkml-install-api\_opam\bin\dkml-install-runner.exe
Z:\source\...kernel> with-dkml dune build vendor/diskuv-ocaml/vendor/dkml-component-ocamlcompiler/install/ocamlcompiler/dkml_component_ocamlcompiler.cmxa
```
