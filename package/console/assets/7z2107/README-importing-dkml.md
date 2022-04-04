# Importing 7zip

* https://www.7-zip.org/a/7z2107.exe
* sha256=71e94e6038f4d42ed8f0f38c0e6c3846f21d13527139efa9ef8b8f6312ab6c90

7z2017.exe contains a 7zip archive. Use the following to extract its contents
into a `un7z` directory:

```bash
7z e -oun7z /location/of/7z2017.exe
```

```console
$ file un7z/7zCon.sfx
un7z/7zCon.sfx: PE32 executable (console) Intel 80386, for MS Windows
```

We only need the license file and `7zCon.sfx`. There is a separate
download [`lzma2107.7z`](https://www.7-zip.org/a/lzma2107.7z) that has
`bin/7zS2con.sfx` which, among other things, does not support configuration
files. So just use `7zCon.sfx`.
