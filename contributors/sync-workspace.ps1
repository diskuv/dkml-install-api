[CmdletBinding()]
param (
    [switch]
    $SkipUpgrade
)

$ErrorActionPreference = "Stop"

$PROJROOT=Split-Path -Parent "$PSScriptRoot"

$SOURCEROOT=Split-Path -Parent "$PROJROOT"
$SOURCE_MIXED=& with-dkml cygpath -am "$SOURCEROOT"

(& opam env --switch "$PROJROOT" --set-switch) -split '\r?\n' | ForEach-Object { Invoke-Expression $_ }

Get-date

with-dkml pacman -S mingw-w64-clang-x86_64-pkg-config --noconfirm --needed

with-dkml opam pin dkml-base-compiler                   https://github.com/diskuv/dkml-compiler.git#main --no-action --yes
with-dkml opam pin conf-dkml-cross-toolchain            https://github.com/diskuv/conf-dkml-cross-toolchain.git#main --no-action --yes

with-dkml opam pin dkml-install                         git+file://$SOURCE_MIXED/dkml-install-api#main --no-action --yes
with-dkml opam pin dkml-install-installer               git+file://$SOURCE_MIXED/dkml-install-api#main --no-action --yes
with-dkml opam pin dkml-install-runner                  git+file://$SOURCE_MIXED/dkml-install-api#main --no-action --yes
with-dkml opam pin dkml-package-console                 git+file://$SOURCE_MIXED/dkml-install-api#main --no-action --yes
with-dkml opam pin dkml-installer-network-ocaml         git+file://$SOURCE_MIXED/dkml-installer-ocaml#main --no-action --yes
with-dkml opam pin dkml-option-vcpkg                    git+file://$SOURCE_MIXED/dkml-option-vcpkg#main --no-action --yes
with-dkml opam pin dkml-component-network-ocamlcompiler git+file://$SOURCE_MIXED/dkml-component-ocamlcompiler#main --no-action --yes
with-dkml opam pin dkml-component-network-unixutils     git+file://$SOURCE_MIXED/dkml-component-unixutils#main --no-action --yes
with-dkml opam pin dkml-component-staging-curl          git+file://$SOURCE_MIXED/dkml-component-curl#main --no-action --yes
with-dkml opam pin dkml-component-staging-ocamlrun      git+file://$SOURCE_MIXED/dkml-component-ocamlrun#main --no-action --yes
with-dkml opam pin dkml-component-staging-opam32        git+file://$SOURCE_MIXED/dkml-component-opam#main --no-action --yes
with-dkml opam pin dkml-component-staging-opam64        git+file://$SOURCE_MIXED/dkml-component-opam#main --no-action --yes
with-dkml opam pin dkml-component-staging-unixutils     git+file://$SOURCE_MIXED/dkml-component-unixutils#main --no-action --yes
with-dkml opam pin dkml-component-xx-console            git+file://$SOURCE_MIXED/dkml-install-api#main --no-action --yes
with-dkml opam pin diskuvbox                            git+file://$SOURCE_MIXED/diskuvbox#main --no-action --yes

with-dkml opam pin curly                                https://github.com/jonahbeckford/curly.git#windows-env --no-action --yes
with-dkml opam pin crunch                               https://github.com/jonahbeckford/ocaml-crunch.git#feature-windowsopen --no-action --yes

with-dkml opam pin -k version mtime                 1.4.0 --no-action --yes
with-dkml opam pin -k version curly 0.2.1-windows-env_r2 --no-action --yes
with-dkml opam pin -k version dune-action-plugin    2.9.3 --no-action --yes
with-dkml opam pin -k version dune-glob             2.9.3 --no-action --yes
with-dkml opam pin -k version dune-private-libs     2.9.3 --no-action --yes
#   dune.2.9.3+shim is installed by DKML. Conflicts with other dune-* packages
with-dkml opam pin -k version dune                  2.9.3 --no-action --yes
Write-Output "not in 2.9.3 - with-dkml opam pin -k version dune-rpc-lwt          2.9.3 --no-action --yes"
Write-Output "not in 2.9.3 - with-dkml opam pin -k version dune-rpc              2.9.3 --no-action --yes"
Write-Output "dune-site is being removed - with-dkml opam pin -k version dune-site             2.9.3 --no-action --yes"

with-dkml opam pin -k version uuidm                 0.9.7 --no-action --yes
with-dkml opam pin -k version mdx                   2.0.0 --no-action --yes
with-dkml opam pin -k version ocaml-lsp-server      1.9.0 --no-action --yes
with-dkml opam pin -k version ocamlformat           0.19.0 --no-action --yes
with-dkml opam pin -k version ocamlformat-rpc       0.19.0 --no-action --yes

Get-date

$OCamlPackage=(& opam list --short | Select-String '^ocaml$')

if (-not $SkipUpgrade) {
    $Pkgs = @(
        "dkml-install"; "dkml-install-installer"; "dkml-install-runner"; "dkml-package-console";
        "dkml-component-network-ocamlcompiler"; "dkml-component-staging-ocamlrun";
        "dkml-component-staging-curl";
        "dkml-component-staging-unixutils"; "dkml-component-network-unixutils";
        "dkml-installer-network-ocaml";
        "ocaml-lsp-server"; "ocamlformat-rpc";
        "alcotest"
    )
    if ($OCamlPackage -eq "") {
        # If switch does not have an OCaml compiler, add the DKML base compiler
        $Pkgs += @(
            "dkml-base-compiler"; "ocaml"; "ocaml-config"
        )
    }
    with-dkml time opam upgrade --yes @Pkgs
}
