(& opam env --switch Z:\source\dkml-install-api --set-switch) -split '\r?\n' | ForEach-Object { Invoke-Expression $_ }

with-dkml date

with-dkml opam pin dkml-base-compiler                   https://github.com/diskuv/dkml-compiler.git#main --no-action --yes
with-dkml opam pin ocaml                                https://github.com/diskuv/dkml-compiler.git#main --no-action --yes
with-dkml opam pin ocaml-config                         https://github.com/diskuv/dkml-compiler.git#main --no-action --yes
with-dkml opam pin conf-dkml-cross-toolchain            https://github.com/diskuv/conf-dkml-cross-toolchain.git#main --no-action --yes

with-dkml opam pin dkml-component-network-ocamlcompiler git+file://Z:/source/dkml-component-ocamlcompiler#main --no-action --yes
with-dkml opam pin dkml-component-staging-ocamlrun      git+file://Z:/source/dkml-component-ocamlcompiler#main --no-action --yes
with-dkml opam pin dkml-install                         git+file://Z:/source/dkml-install-api#main --no-action --yes
with-dkml opam pin dkml-install-runner                  git+file://Z:/source/dkml-install-api#main --no-action --yes
with-dkml opam pin dkml-package-console                 git+file://Z:/source/dkml-install-api#main --no-action --yes
with-dkml opam pin dkml-component-staging-curl          git+file://Z:/source/dkml-component-curl#main --no-action --yes
with-dkml opam pin dkml-installer-network-ocaml         git+file://Z:/source/dkml-installer-ocaml#main --no-action --yes
with-dkml opam pin dkml-component-staging-unixutils     git+file://Z:/source/dkml-component-unixutils#main --no-action --yes
with-dkml opam pin dkml-component-network-unixutils     git+file://Z:/source/dkml-component-unixutils#main --no-action --yes
with-dkml opam pin diskuvbox                            git+file://Z:/source/diskuvbox#main --no-action --yes

with-dkml opam pin -k version curly 0.2.1-windows-env --no-action --yes
with-dkml opam pin -k version dune-action-plugin    2.9.3 --no-action --yes
with-dkml opam pin -k version dune-glob             2.9.3 --no-action --yes
with-dkml opam pin -k version dune-private-libs     2.9.3 --no-action --yes
Write-Output "not in 2.9.3 - with-dkml opam pin -k version dune-rpc-lwt          2.9.3 --no-action --yes"
Write-Output "not in 2.9.3 - with-dkml opam pin -k version dune-rpc              2.9.3 --no-action --yes"
with-dkml opam pin -k version dune-site             2.9.3 --no-action --yes

with-dkml opam pin -k version uuidm                 0.9.7 --no-action --yes
with-dkml opam pin -k version mdx                   2.0.0 --no-action --yes

with-dkml date

with-dkml time opam upgrade `
    dkml-base-compiler ocaml ocaml-config `
    dkml-install dkml-install-runner dkml-package-console `
    dkml-component-network-ocamlcompiler dkml-component-staging-ocamlrun `
    dkml-component-staging-curl `
    dkml-component-staging-unixutils dkml-component-network-unixutils `
    dkml-installer-network-ocaml `
    --yes
