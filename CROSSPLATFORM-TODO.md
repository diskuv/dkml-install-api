# Cross-platform TODO

## setup.exe

* create_installers.exe skips over the 7zip-based `Installer_sfx.generate`
  on non-Windows build machines because 7zr.exe only runs on Windows. If we
  resurrect <https://github.com/XVilka/ocaml-lzma_7z> then any platform could
  generate setup.exe.

procmon is showing that setup.exe has hardcoded
_opam/lib/dkml-install-runner/plugins/
