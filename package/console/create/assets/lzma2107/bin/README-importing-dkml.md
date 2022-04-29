# Importing lzma2107

License: Public Domain; see https://www.7-zip.org/sdk.html

This license is different from 7z2017, which is LGPL.

## Downloading

Confer: https://documentation.help/7-Zip-18.0/sfx.htm

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

There is no `7zS.sfx` which is described as `7zSD.sfx` with the MSVCRT.dll
dependency (the statically linked version). `7zSD.sfx` is ok.

## Update #1

There is also `bin/7zS2con.sfx` which, among other things, does not support
configuration files (it autoruns setup.exe or the first .exe it finds) and
it uses the console. So we'll use that.
