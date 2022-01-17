#!/bin/bash
set -euf

PARENTDIR=$(dirname "$0")
PARENTDIR=$(cd "$0" && cd .. && pwd)

# Really only needed for MSYS2 if we are calling from a MSYS2/usr/bin/make.exe rather than a full shell
export PATH="/usr/local/bin:/usr/bin:/bin:/mingw64/bin:$PATH"

# ------------------
# BEGIN Command line processing

usage() {
    echo "Usage:" >&2
    echo "    release.sh -h  Display this help message." >&2
    echo "    release.sh -p  Create a prerelease." >&2
    echo "    release.sh     Create a release." >&2
}

PRERELEASE=OFF
while getopts ":hp" opt; do
    case ${opt} in
        h )
            usage
            exit 0
        ;;
        p )
            PRERELEASE=ON
        ;;
        \? )
            echo "This is not an option: -$OPTARG" >&2
            usage
            exit 1
        ;;
    esac
done
shift $((OPTIND -1))

# END Command line processing
# ------------------

# Git, especially through bump2version, needs HOME set for Windows
if which pacman >/dev/null 2>&1 && which cygpath >/dev/null 2>&1; then HOME="$USERPROFILE"; fi

# Capture which version will be the release version when the prereleases are finished
TARGET_VERSION=$(awk '$1=="current_version"{print $NF; exit 0}' .bumpversion.prerelease.cfg | sed 's/[-+].*//')

if [ "$PRERELEASE" = ON ]; then
    # Increment the prerelease
    bump2version prerelease \
        --config-file .bumpversion.prerelease.cfg \
        --message 'Prerelease v{new_version}' \
        --verbose
else
    # We are doing a target release, not a prerelease ...

    # 1. There are a couple files that should have a "stable" link that only change when the release is
    # finished rather than every prerelease. We change those here.
    bump2version major \
        --config-file .bumpversion.release.cfg \
        --new-version "$TARGET_VERSION" \
        --verbose
    git add -A # the prior bump2version checked if the Git working directory was clean, so this is safe

    # 2. Assemble the change log
    RELEASEDATE=$(date +%Y-%m-%d)
    sed "s/@@YYYYMMDD@@/$RELEASEDATE/" "contributors/changes/v$TARGET_VERSION.md" > /tmp/v.md
    mv /tmp/v.md "contributors/changes/v$TARGET_VERSION.md"
    cp CHANGES.md /tmp/
    cp "contributors/changes/v$TARGET_VERSION.md" CHANGES.md
	echo >> CHANGES.md
    cat /tmp/CHANGES.md >> CHANGES.md
    git add CHANGES.md "contributors/changes/v$TARGET_VERSION.md"

    # 3. Make a release commit
	git commit -m "Finish v$TARGET_VERSION release (1 of 2)"

    # Increment the change which will clear the _prerelease_ state
	bump2version change \
        --config-file .bumpversion.prerelease.cfg \
        --new-version "$TARGET_VERSION" \
        --message 'Finish v{new_version} release (2 of 2)' \
        --tag-name 'v{new_version}' \
        --verbose
fi

# Safety check version for a release
NEW_VERSION=$(awk '$1=="current_version"{print $NF; exit 0}' .bumpversion.prerelease.cfg)
if [ "$PRERELEASE" = OFF ]; then
    if [ ! "$NEW_VERSION" = "$TARGET_VERSION" ]; then
        echo "The target version $TARGET_VERSION and the new version $NEW_VERSION did not match" >&2
        exit 1
    fi
    NEW_VERSION="$TARGET_VERSION"
fi

# Define which files and directories go into the assets archive
# TODO: For now we are just packaging up the lib/ directory; that is useless.
# TODO: Eventually tools needed by plugins should make it in here.
ARCHIVE_MEMBERS=(LICENSE README.md lib)

# Make _build/assets.zip
FILE="$PARENTDIR/contributors/_build/assets.zip"
rm -f "$FILE"
install -d contributors/_build/release-zip
rm -rf contributors/_build/release-zip
install -d contributors/_build/release-zip
zip -r "$FILE" "${ARCHIVE_MEMBERS[@]}"
pushd contributors/_build/release-zip
install -d dkml-install-api
cd dkml-install-api
unzip "$FILE"
cd ..
rm -f "$FILE"
zip -r "$FILE" dkml-install-api
popd

# Make _build/assets.tar.gz
FILE="$PARENTDIR/contributors/_build/assets.tar.gz"
install -d contributors/_build
rm -f "$FILE"
if tar -cf contributors/_build/probe.tar --no-xattrs --owner root /dev/null >/dev/null 2>/dev/null; then GNUTAR=ON; fi # test to see if GNU tar
if [ "${GNUTAR:-}" = ON ]; then
    # GNU tar
    tar cvfz "$FILE" --owner root --group root --exclude _build --transform 's,^,dkml-install-api/,' --no-xattrs "${ARCHIVE_MEMBERS[@]}"
else
    # BSD tar
    tar cvfz "$FILE" -s ',^,dkml-install-api/,' --uname root --gname root --exclude _build --no-xattrs "${ARCHIVE_MEMBERS[@]}"
fi

# Push
git push
git push --tags
# `git push --atomic origin main "v$NEW_VERSION"` is similar but try it out with GitHub Actions.

# TODO: Use GitHub CLI to release the package
