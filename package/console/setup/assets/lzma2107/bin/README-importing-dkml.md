# Importing 7zip

Confer: https://documentation.help/7-Zip/sfx.htm

* https://www.7-zip.org/a/lzma2107.7z
* sha256=833888f03c6628c8a062ce5844bb8012056e7ab7ba294c7ea232e20ddadf0d75

Use the following to extract its contents into a `un7z` directory:

```bash
7z e -oun7z /location/of/lzma2107.7z
```

```console
$ file un7z/bin/7zSD.sfx
un7z/bin/7zSD.sfx: PE32 executable (console) Intel 80386, for MS Windows
```

There is also `bin/7zS2con.sfx` which, among other things, does not support
configuration files. So just use `7zSD.sfx`.

There is no `7zS.sfx` which is described as `7zSD.sfx` with the MSVCRT.dll
dependency (the statically linked version). `7zSD.sfx` is ok.
