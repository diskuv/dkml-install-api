#!/bin/sh
set -euf

usage() {
  printf "usage: create.sh [options] ARCHIVER [extra archiver options]\n" >&2
  printf "Archivers:\n" >&2
  printf "  tar: Creates a tar archiver using the 'tar' program from the PATH\n" >&2
  printf "       or from the -a option. The default options are 'cCf', and\n" >&2
  printf "       the default extension is '.tar'. It is best to use the -t\n" >&2
  printf "       option.\n" >&2
  printf "Options:\n" >&2
  printf " -a EXECUTABLE: Full path to the archiver\n" >&2
  printf " -o DIR: Output directory\n" >&2
  printf " -e EXTENSION: Extension on the file, like .tar.gz\n" >&2
  printf " -t gnu|bsd: If ARCHIVER is 'tar' which type of tar to use.\n" >&2
  printf "    Defaults to bsd on macOS. Otherwise gnu\n" >&2
}

ARCHIVER_EXE=
ARCHIVE_EXTENSION=
TAR_TYPE=
OUTPUT_DIR=$PWD
while getopts ":a:e:t:o:h" opt; do
  case ${opt} in
      h )
          usage
          exit 0
      ;;
      a ) ARCHIVER_EXE=$OPTARG ;;
      e ) ARCHIVE_EXTENSION=$OPTARG ;;
      t ) TAR_TYPE=$OPTARG ;;
      o ) OUTPUT_DIR=$OPTARG ;;
      \? )
          echo "This is not an option: -$OPTARG" >&2
          usage
          exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ "$#" -eq 0 ]; then
  usage
  printf "Missing ARCHIVER\n" >&2
  exit 1
fi

archivetype=$1
shift

if [ -z "$TAR_TYPE" ]; then
  # shellcheck disable=SC2194
  case "__PLACEHOLDER_BUILDHOST_ABI__" in
    darwin_*) TAR_TYPE=bsd ;;
    *) TAR_TYPE=gnu
  esac
fi

install -d "$OUTPUT_DIR"

case "$archivetype" in
  tar)
    if [ -z "$ARCHIVER_EXE" ]; then ARCHIVER_EXE=tar; fi
    if [ -z "$ARCHIVE_EXTENSION" ]; then ARCHIVE_EXTENSION=.tar; fi
    if [ "$TAR_TYPE" = "bsd" ]; then
      OPT_TRANSFORM1="-s"
      OPT_TRANSFORM2=",^./,__PLACEHOLDER_BASENAME__/,"
    else
      OPT_TRANSFORM1="--transform"
      OPT_TRANSFORM2="s,^./,__PLACEHOLDER_BASENAME__/,"
    fi
    archive() {
      exec "$ARCHIVER_EXE" \
        cCf '__PLACEHOLDER_ARCHIVE_DIR__' "$OUTPUT_DIR/__PLACEHOLDER_BASENAME__$ARCHIVE_EXTENSION" \
        "$OPT_TRANSFORM1" "$OPT_TRANSFORM2" \
        "$@" \
        .
    }
  ;;
  *)
    usage
    exit 2
esac

archive "$@"
