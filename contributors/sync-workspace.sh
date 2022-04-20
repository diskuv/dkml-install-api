#!/bin/sh
set -euf

SKIP_UPGRADE=0
if [ "$#" -gt 0 ] && [ "$1" = "no-upgrade" ]; then
    SKIP_UPGRADE=1
fi

# .../source/dkml-install-api/contributors/sync-workspace.sh
# .../source/dkml-component-ocamlcompiler/...
# .../source/dkml-component-unixutils/...
# .../source/dkml-component-curl/...
# .../source/diskuvbox/...
HERE=$(dirname "$0")
HERE=$(cd "$HERE" && pwd)
PROJROOT=$(cd "$HERE/.." && pwd)
SOURCEROOT=$(cd "$HERE/../.." && pwd)
if [ -x /usr/bin/cygpath ]; then
    SOURCEMIXED=$(/usr/bin/cygpath -am "$SOURCEROOT")
else
    SOURCEMIXED=$SOURCEROOT
fi

date

eval "$(opam env --switch "$PROJROOT" --set-switch)"

set -x

opam repository add diskuv "git+https://github.com/diskuv/diskuv-opam-repository.git#main" --yes

opam pin dkml-base-compiler                   https://github.com/diskuv/dkml-compiler.git#main --no-action --yes
opam pin ocaml                                https://github.com/diskuv/dkml-compiler.git#main --no-action --yes
opam pin ocaml-config                         https://github.com/diskuv/dkml-compiler.git#main --no-action --yes
opam pin conf-dkml-cross-toolchain            https://github.com/diskuv/conf-dkml-cross-toolchain.git#main --no-action --yes

opam pin dkml-component-network-ocamlcompiler git+file://"$SOURCEMIXED"/dkml-component-ocamlcompiler#main --no-action --yes
opam pin dkml-component-staging-ocamlrun      git+file://"$SOURCEMIXED"/dkml-component-ocamlcompiler#main --no-action --yes
opam pin dkml-install                         git+file://"$SOURCEMIXED"/dkml-install-api#main --no-action --yes
opam pin dkml-install-runner                  git+file://"$SOURCEMIXED"/dkml-install-api#main --no-action --yes
opam pin dkml-package-console                 git+file://"$SOURCEMIXED"/dkml-install-api#main --no-action --yes
opam pin dkml-component-staging-curl          git+file://"$SOURCEMIXED"/dkml-component-curl#main --no-action --yes
opam pin dkml-installer-network-ocaml         git+file://"$SOURCEMIXED"/dkml-installer-ocaml#main --no-action --yes
opam pin dkml-component-staging-unixutils     git+file://"$SOURCEMIXED"/dkml-component-unixutils#main --no-action --yes
opam pin dkml-component-network-unixutils     git+file://"$SOURCEMIXED"/dkml-component-unixutils#main --no-action --yes
opam pin diskuvbox                            git+file://"$SOURCEMIXED"/diskuvbox#main --no-action --yes

opam pin curly                                https://github.com/jonahbeckford/curly.git#windows-env --no-action --yes
opam pin crunch                               https://github.com/jonahbeckford/ocaml-crunch.git#feature-windowsopen --no-action --yes

opam pin -k version curly 0.2.1-windows-env_r2 --no-action --yes
opam pin -k version dune-action-plugin    2.9.3 --no-action --yes
opam pin -k version dune-glob             2.9.3 --no-action --yes
opam pin -k version dune-private-libs     2.9.3 --no-action --yes
echo "not in 2.9.3 - opam pin -k version dune-rpc-lwt          2.9.3 --no-action --yes"
echo "not in 2.9.3 - opam pin -k version dune-rpc              2.9.3 --no-action --yes"
echo "dune-site is being removed - opam pin -k version dune-site             2.9.3 --no-action --yes"

opam pin -k version uuidm                 0.9.7 --no-action --yes
opam pin -k version mdx                   2.0.0 --no-action --yes

date

if [ "$SKIP_UPGRADE" = 0 ]; then
    time opam upgrade \
        dkml-base-compiler ocaml ocaml-config conf-dkml-cross-toolchain \
        dkml-install dkml-install-runner dkml-package-console \
        dkml-component-network-ocamlcompiler dkml-component-staging-ocamlrun \
        dkml-component-staging-curl \
        dkml-component-staging-unixutils dkml-component-network-unixutils \
        dkml-installer-network-ocaml \
        --yes
fi