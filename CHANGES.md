## 0.3.0

Breaking change:

* Program version is set in `Private_common`

Bug fixes:
* Delete 7z archive at the start of each `opam install` so adding to archive
  does not duplicate entries.

## 0.2.0

* Breaking change: The `depends_on` component value has been split into
  `install_depends_on` and `uninstall_depends_on`

## 0.1.1

* Change Opam `available:` to only `win32`, `macos` and `linux` operating systems to reflect conditions in
  https://github.com/diskuv/dkml-install-api/blob/5cfd7b57c79d990c76a9bdc8f8f0fa9f6fd5346f/runner/src/host_abi.ml

## 0.1.0

* Initial version
