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

Z:\source\...kernel> with-dkml time opam install  ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-network-ocamlcompiler.opam ./vendor\diskuv-ocaml\vendor\dkml-component-ocamlcompiler\dkml-component-staging-ocamlrun.opam ..\..\..\dkml-install-api\dkml-install.opam  ..\..\..\dkml-install-api\dkml-install-runner.opam ..\..\..\dkml-component-enduser-unixutils\dkml-component-staging-unixutils.opam ..\..\..\dkml-component-enduser-unixutils\dkml-component-network-unixutils.opam ..\..\..\dkml-component-enduser-unixutils\dkml-component-offline-unixutils.opam  ..\..\..\dkml-component-staging-curl\dkml-component-staging-curl.opam

Z:\source\dkml-install-api\_opam\bin\dkml-install-admin-runner.exe
Z:\source\dkml-install-api\_opam\bin\dkml-install-user-runner.exe
Z:\source\dkml-install-api\_opam\bin\dkml-install-setup.exe
Z:\source\dkml-install-api\_opam\bin\dkml-install-uninstaller.exe

with-dkml env OCAMLRUNPARAM=b Z:\source\dkml-install-api\_opam\bin\dkml-install-setup.exe --name test123 --prefix Z:\temp\prefix --opam-context --component network-ocamlcompiler -v
with-dkml env OCAMLRUNPARAM=b Z:\source\dkml-install-api\_opam\bin\dkml-install-uninstall.exe --name test123 --prefix Z:\temp\prefix --opam-context --component network-ocamlcompiler -v

Z:\source\...kernel> with-dkml dune build vendor/diskuv-ocaml/vendor/dkml-component-ocamlcompiler/install/ocamlcompiler/dkml_component_ocamlcompiler.cmxa

Z:\source\dkml-install-api> with-dkml dune build
Z:\source\dkml-install-api> with-dkml ALCOTEST_VERBOSE=1 dune runtest



Z:\source\dkml-component-ocamlcompiler> with-dkml opam pin remove dkml-component-network-ocamlcompiler dkml-component-staging-ocamlrun
Z:\source\dkml-component-ocamlcompiler> with-dkml opam pin add dkml-component-network-ocamlcompiler . --yes
Z:\source\dkml-component-ocamlcompiler> with-dkml opam pin add dkml-component-staging-ocamlrun . --yes
Z:\source\dkml-component-ocamlcompiler> with-dkml opam upgrade dkml-component-network-ocamlcompiler dkml-component-staging-ocamlrun

Z:\source\dkml-install-api> with-dkml opam pin remove dkml-install dkml-install-runner
Z:\source\dkml-install-api> with-dkml opam pin add dkml-install . --yes
Z:\source\dkml-install-api> with-dkml opam pin add dkml-install-runner . --yes
Z:\source\dkml-install-api> with-dkml opam upgrade dkml-install dkml-install-runner

Z:\source\dkml-component-curl> with-dkml opam pin remove dkml-component-staging-curl
Z:\source\dkml-component-curl> with-dkml opam pin add dkml-component-staging-curl . --yes
Z:\source\dkml-component-curl> with-dkml opam upgrade dkml-component-staging-curl

Z:\source\dkml-installer-ocaml> with-dkml opam pin remove dkml-installer-network-ocaml
Z:\source\dkml-installer-ocaml> with-dkml opam pin add dkml-installer-network-ocaml . --yes
Z:\source\dkml-installer-ocaml> with-dkml opam upgrade dkml-installer-network-ocaml

Z:\source\dkml-component-unixutils> with-dkml opam pin remove dkml-component-staging-unixutils dkml-component-network-unixutils
Z:\source\dkml-component-unixutils> with-dkml opam pin add dkml-component-staging-unixutils . --yes
Z:\source\dkml-component-unixutils> with-dkml opam pin add dkml-component-network-unixutils . --yes
Z:\source\dkml-component-unixutils> with-dkml opam upgrade dkml-component-staging-unixutils dkml-component-network-unixutils

with-dkml opam dkml init
(& opam env --switch Z:\source\dkml-install-api --set-switch) -split '\r?\n' | ForEach-Object { Invoke-Expression $_ }
with-dkml opam remove ocaml-system base-unix.base base-threads.base base-bigarray.base --update-invariant
with-dkml opam repository set-url diskuv-0.4.0-prerel14 git+https://github.com/diskuv/diskuv-opam-repository.git#main

with-dkml opam pin dkml-base-compiler                   https://github.com/diskuv/dkml-compiler.git#main --no-action --yes
with-dkml opam pin ocaml                                https://github.com/diskuv/dkml-compiler.git#main --no-action --yes
with-dkml opam pin ocaml-config                         https://github.com/diskuv/dkml-compiler.git#main --no-action --yes

with-dkml opam pin dkml-component-network-ocamlcompiler git+file://Z:/source/dkml-component-ocamlcompiler#main --no-action --yes
with-dkml opam pin dkml-component-staging-ocamlrun      git+file://Z:/source/dkml-component-ocamlcompiler#main --no-action --yes
with-dkml opam pin dkml-install                         git+file://Z:/source/dkml-install-api#main --no-action --yes
with-dkml opam pin dkml-install-runner                  git+file://Z:/source/dkml-install-api#main --no-action --yes
with-dkml opam pin dkml-component-staging-curl          git+file://Z:/source/dkml-component-curl#main --no-action --yes
with-dkml opam pin dkml-installer-network-ocaml         git+file://Z:/source/dkml-installer-ocaml#main --no-action --yes
with-dkml opam pin dkml-component-staging-unixutils     git+file://Z:/source/dkml-component-unixutils#main --no-action --yes
with-dkml opam pin dkml-component-network-unixutils     git+file://Z:/source/dkml-component-unixutils#main --no-action --yes

with-dkml opam pin -k version curly 0.2.1-windows-env --no-action --yes
with-dkml opam pin -k version dune-action-plugin    2.9.3 --no-action --yes
with-dkml opam pin -k version dune-glob             2.9.3 --no-action --yes
with-dkml opam pin -k version dune-private-libs     2.9.3 --no-action --yes
echo not in 2.9.3 - with-dkml opam pin -k version dune-rpc-lwt          2.9.3 --no-action --yes
echo not in 2.9.3 - with-dkml opam pin -k version dune-rpc              2.9.3 --no-action --yes
with-dkml opam pin -k version dune-site             2.9.3 --no-action --yes

with-dkml opam install dkml-installer-network-ocaml

with-dkml opam pin git+file://Z:/source/ #main --no-action --yes
with-dkml opam pin git+file://Z:/source/ #main --no-action --yes
with-dkml opam pin git+file://Z:/source/ #main --no-action --yes


# As admin
Z:\source\dkml-install-api\_opam\bin\dkml-install-admin-runner.exe install-admin-network-ocamlcompiler --opam-context --prefix Z:\temp\prefix -v
```

---

## Removing all local components

Sometimes you have to start from scratch when Opam and Dune can't figure out
that a dependency needs to be updated. You may get stuck with odd errors like:

```
dkml-install-setup.exe: [ERROR] Dynlink.Error (Dynlink.Cannot_open_dll "Dynlink.Error (Dynlink.Cannot_open_dll \"(Failure \\\"Cannot reso        olve camlDkml_install_api__log_spawn_and_raise_417\\\")\")")
                                Raised at Stdlib__string.index_rec in file "string.ml", line 115, characters 19-34
                                Called from Sexplib0__Sexp.Printing.index_of_newline in file "src/sexp.ml", line 113, characters 13-47
```

You can remove all local components on Windows by:

```powershell
with-dkml opam remove dkml-install dkml-install-runner --yes
with-dkml find $(opam var share) -maxdepth 1 -name "dkml-component-\*" | Remove-Item -Recurse -Force
with-dkml find $(join-path $(opam var prefix) .opam-switch/sources) -maxdepth 1 -name "dkml-component-\*" | Remove-Item -Recurse -Force
with-dkml find $(join-path $(opam var prefix) .opam-switch/sources) -maxdepth 1 -name "dkml-install\*" | Remove-Item -Recurse -Force
with-dkml echo $(join-path $(opam var lib) dkml-install-runner/plugins) | Remove-Item -Recurse -Force
```

or on Unix:

```bash
opam remove dkml-install dkml-install-runner --yes
find "$(opam var share)" -maxdepth 1 -name "dkml-component-\*" -exec rm -rf {} \+
find "$(opam var prefix)/.opam-switch/sources" -maxdepth 1 -name "dkml-component-\*" -exec rm -rf {} \+
find "$(opam var prefix)/.opam-switch/sources" -maxdepth 1 -name "dkml-install\*" -exec rm -rf {} \+
rm -rf "$(opam var lib)/dkml-install-runner/plugins"
```

Then check if you have any locally defined packages that say "not resetting unless explicitly selected":

```bash
$ with-dkml opam update --development
[NOTE] dkml-component-network-unixutils.0.1.0 has previously been updated with --working-dir, not resetting unless explicitly selected
```

If you do, either set or remove the pin (`opam pin add` or `opam pin remove`)
and re-update the package with `with-dkml opam update --development dkml-component-network-unixutils.0.1.0`

Finally reinstall all the installer (or individual components) you need. For example:

```bash
with-dkml opam install dkml-installer-network-ocaml
```
