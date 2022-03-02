### Developing

> At the moment this is little more than a scratchpad. Once enough is here it
> will be re-organized for public consumption.

```powershell
Z:\source\dkml-install-api> (& opam env --switch Z:\source\dkml-install-api --set-switch) -split '\r?\n' | ForEach-Object { Invoke-Expression $_ }
Z:\source\dkml-install-api> with-dkml opam install ./dkml-install.opam 
Z:\source\dkml-install-api> with-dkml ALCOTEST_VERBOSE=1 dune runtest

Z:\source\...kernel> (& opam env --switch Z:\source\dkml-install-api --set-switch) -split '\r?\n' | ForEach-Object { Invoke-Expression $_ }
Z:\source\...kernel> with-dkml opam install ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-ocamlcompiler.opam ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-ocamlrun.opam


Z:\source\...kernel> with-dkml opam install  ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-ocamlcompiler.opam ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-ocamlrun.opam ..\..\..\dkml-install-api\dkml-install.opam  ..\..\..\dkml-install-api\dkml-install-runner.opam

Z:\source\...kernel> with-dkml time opam install  ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-enduser-ocamlcompiler.opam ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-staging-ocamlrun.opam ..\..\..\dkml-install-api\dkml-install.opam  ..\..\..\dkml-install-api\dkml-install-runner.opam ..\..\..\dkml-component-enduser-unixutils\dkml-component-enduser-unixutils.opam  ..\..\..\dkml-component-staging-curl\dkml-component-staging-curl.opam

Z:\source\dkml-install-api\_opam\bin\dkml-install-admin-runner.exe
Z:\source\dkml-install-api\_opam\bin\dkml-install-user-runner.exe
Z:\source\dkml-install-api\_opam\bin\dkml-install-setup.exe
Z:\source\dkml-install-api\_opam\bin\dkml-install-uninstaller.exe

with-dkml env OCAMLRUNPARAM=b Z:\source\dkml-install-api\_opam\bin\dkml-install-setup.exe --name test123 --prefix Z:\temp\prefix --opam-context -v
with-dkml env OCAMLRUNPARAM=b Z:\source\dkml-install-api\_opam\bin\dkml-install-uninstall.exe --name test123 --prefix Z:\temp\prefix --opam-context -v

Z:\source\...kernel> with-dkml dune build vendor/diskuv-ocaml/vendor/dkml-component-ocamlcompiler/install/ocamlcompiler/dkml_component_ocamlcompiler.cmxa

Z:\source\dkml-install-api> with-dkml dune build
Z:\source\dkml-install-api> with-dkml ALCOTEST_VERBOSE=1 dune runtest

```
