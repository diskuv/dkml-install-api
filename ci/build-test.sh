#!/bin/sh
set -euf

# Set project directory
if [ -n "${CI_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$CI_PROJECT_DIR"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$PC_PROJECT_DIR"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
    PROJECT_DIR="$GITHUB_WORKSPACE"
else
    PROJECT_DIR="$PWD"
fi
if [ -x /usr/bin/cygpath ]; then
    PROJECT_DIR=$(/usr/bin/cygpath -au "$PROJECT_DIR")
fi

# PATH. Add opamrun
export PATH="$PROJECT_DIR/.ci/sd4/opamrun:$PATH"

# Initial Diagnostics (optional but useful)
opamrun switch
opamrun list
opamrun var
opamrun config report
opamrun option
opamrun exec -- ocamlc -config

# Update
opamrun update

# Make your own build logic! It may look like ...
opamrun install . --deps-only --with-test
opamrun exec -- dune runtest
