The goal of this CRAM test is to demonstrate, document and test how
self-extracting archives work on Windows.

The main documentation tool for Diskuv projects is Sphinx, and sections of this
CRAM test can be directly included into Sphinx documentation using
the `literalinclude` directive and the `start-after/start-at/end-before/end-at`
attributes:
https://www.sphinx-doc.org/en/master/usage/restructuredtext/directives.html#directive-literalinclude

--------------------------------------------------------------------------------

Precheck that nothing unusual is in this test build directory
  $ ls
  setup_print_hello.exe
  test_windows_create_installers.exe
  test_windows_create_installers.t
  uninstaller_print_bye.exe

Create the temporary work directory and the target installer directory
  $ install -d work
  $ install -d target

Create an Opam directory structure

The files will just be empty files, except for two important files:
* dkml-install-setup.exe will print "Hello"
* dkml-install-uninstaller.exe will print "Bye"

Ordinarily the dkml-install-api framework will generate those two files for us.
However for this test we'll simplify since we are demonstrating how
self-extracting archives work on Windows.

(TODO) dkml-install-admin-runner.exe is ABI native code today. They should be
built and downloaded from ABI asset repository, or built as bytecode.
  $ install -d _opam/bin
  $ install -d _opam/lib/dkml-install-runner/plugins/dkml-plugin-offline-test1
  $ install -d _opam/lib/dkml-install-runner/plugins/dkml-plugin-staging-ocamlrun
  $ install -d _opam/lib/dkml-component-offline-test1
  $ install -d _opam/lib/dkml-component-staging-ocamlrun
  $ install -d _opam/share/dkml-component-offline-test1/staging-files/generic
  $ install -d _opam/share/dkml-component-offline-test1/static-files
  $ install -d _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/bin
  $ install -d _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/lib/ocaml/stublibs
  $ install -d _opam/share/dkml-component-offline-test1/staging-files/darwin_arm64
  $ install -d _opam/share/dkml-component-offline-test1/staging-files/darwin_x86_64
  $ touch _opam/bin/dkml-install-admin-runner.exe
  $ touch _opam/bin/dkml-install-user-runner.exe
  $ install ./setup_print_hello.exe     _opam/bin/dkml-install-setup.exe
  $ install ./uninstaller_print_bye.exe _opam/bin/dkml-install-uninstaller.exe
  $ touch _opam/lib/dkml-install-runner/plugins/dkml-plugin-offline-test1/META
  $ touch _opam/lib/dkml-install-runner/plugins/dkml-plugin-staging-ocamlrun/META
  $ touch _opam/lib/dkml-component-offline-test1/META
  $ touch _opam/lib/dkml-component-offline-test1/test1.cma
  $ touch _opam/lib/dkml-component-staging-ocamlrun/META
  $ touch _opam/lib/dkml-component-staging-ocamlrun/test2.cma
  $ touch _opam/share/dkml-component-offline-test1/staging-files/generic/install-offline-test1.bc
  $ touch _opam/share/dkml-component-offline-test1/staging-files/darwin_arm64/libpng.dylib
  $ touch _opam/share/dkml-component-offline-test1/staging-files/darwin_x86_64/libpng.dylib
  $ touch _opam/share/dkml-component-offline-test1/static-files/README.txt
  $ touch _opam/share/dkml-component-offline-test1/static-files/icon.png
  $ touch _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/bin/ocamlrun.exe
  $ touch _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/lib/ocaml/stublibs/dllthreads.dll
  $ tree _opam
  _opam
  |-- bin
  |   |-- dkml-install-admin-runner.exe
  |   |-- dkml-install-setup.exe
  |   |-- dkml-install-uninstaller.exe
  |   `-- dkml-install-user-runner.exe
  |-- lib
  |   |-- dkml-component-offline-test1
  |   |   |-- META
  |   |   `-- test1.cma
  |   |-- dkml-component-staging-ocamlrun
  |   |   |-- META
  |   |   `-- test2.cma
  |   `-- dkml-install-runner
  |       `-- plugins
  |           |-- dkml-plugin-offline-test1
  |           |   `-- META
  |           `-- dkml-plugin-staging-ocamlrun
  |               `-- META
  `-- share
      |-- dkml-component-offline-test1
      |   |-- staging-files
      |   |   |-- darwin_arm64
      |   |   |   `-- libpng.dylib
      |   |   |-- darwin_x86_64
      |   |   |   `-- libpng.dylib
      |   |   `-- generic
      |   |       `-- install-offline-test1.bc
      |   `-- static-files
      |       |-- README.txt
      |       `-- icon.png
      `-- dkml-component-staging-ocamlrun
          `-- staging-files
              `-- windows_x86_64
                  |-- bin
                  |   `-- ocamlrun.exe
                  `-- lib
                      `-- ocaml
                          `-- stublibs
                              `-- dllthreads.dll
  
  22 directories, 17 files

Run the create_installers.exe executable. Actually, there is one modification
we did to this executable: it has two test components defined.
  $ ./test_windows_create_installers.exe --program-name testme --program-version 0.1.0 --opam-context=_opam/ --target-dir=target/ --work-dir=work/ --verbose | tr '\\' '/' | grep -v "Archive size"
  test_windows_create_installers.exe: [INFO] Installers will be created that include the components: 
                                             [staging-ocamlrun; offline-test1]
  test_windows_create_installers.exe: [INFO] Installers will be created for the ABIs: 
                                             [generic; android_arm64v8a;
                                              android_arm32v7a; android_x86;
                                              android_x86_64; darwin_arm64;
                                              darwin_x86_64; linux_arm64;
                                              linux_arm32v6; linux_arm32v7;
                                              linux_x86_64; linux_x86;
                                              windows_x86_64; windows_x86;
                                              windows_arm64; windows_arm32]
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-generic.sh that can produce testme-generic-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-android_arm64v8a.sh that can produce testme-android_arm64v8a-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-android_arm32v7a.sh that can produce testme-android_arm32v7a-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-android_x86.sh that can produce testme-android_x86-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-android_x86_64.sh that can produce testme-android_x86_64-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-darwin_arm64.sh that can produce testme-darwin_arm64-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-darwin_x86_64.sh that can produce testme-darwin_x86_64-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-linux_arm64.sh that can produce testme-linux_arm64-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-linux_arm32v6.sh that can produce testme-linux_arm32v6-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-linux_arm32v7.sh that can produce testme-linux_arm32v7-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-linux_x86_64.sh that can produce testme-linux_x86_64-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-linux_x86.sh that can produce testme-linux_x86-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating setup-testme-windows_x86_64-0.1.0.exe
  test_windows_create_installers.exe: [INFO] Creating 7z archive with: 
                                             work\sfx\7zr.exe a -bb0 -mx9 -y
                                               target\testme-windows_x86_64-0.1.0.7z
                                               .\work\a\windows_x86_64\*
  test_windows_create_installers.exe: [INFO] Renaming within a 7z archive with: 
                                             work\sfx\7zr.exe rn -bb0 -mx9 -y
                                               target\testme-windows_x86_64-0.1.0.7z
                                               bin/dkml-install-setup.exe
                                               setup.exe
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-windows_x86_64.sh that can produce testme-windows_x86_64-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating setup-testme-windows_x86-0.1.0.exe
  test_windows_create_installers.exe: [INFO] Creating 7z archive with: 
                                             work\sfx\7zr.exe a -bb0 -mx9 -y
                                               target\testme-windows_x86-0.1.0.7z
                                               .\work\a\windows_x86\*
  test_windows_create_installers.exe: [INFO] Renaming within a 7z archive with: 
                                             work\sfx\7zr.exe rn -bb0 -mx9 -y
                                               target\testme-windows_x86-0.1.0.7z
                                               bin/dkml-install-setup.exe
                                               setup.exe
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-windows_x86.sh that can produce testme-windows_x86-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating setup-testme-windows_arm64-0.1.0.exe
  test_windows_create_installers.exe: [INFO] Creating 7z archive with: 
                                             work\sfx\7zr.exe a -bb0 -mx9 -y
                                               target\testme-windows_arm64-0.1.0.7z
                                               .\work\a\windows_arm64\*
  test_windows_create_installers.exe: [INFO] Renaming within a 7z archive with: 
                                             work\sfx\7zr.exe rn -bb0 -mx9 -y
                                               target\testme-windows_arm64-0.1.0.7z
                                               bin/dkml-install-setup.exe
                                               setup.exe
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-windows_arm64.sh that can produce testme-windows_arm64-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating setup-testme-windows_arm32-0.1.0.exe
  test_windows_create_installers.exe: [INFO] Creating 7z archive with: 
                                             work\sfx\7zr.exe a -bb0 -mx9 -y
                                               target\testme-windows_arm32-0.1.0.7z
                                               .\work\a\windows_arm32\*
  test_windows_create_installers.exe: [INFO] Renaming within a 7z archive with: 
                                             work\sfx\7zr.exe rn -bb0 -mx9 -y
                                               target\testme-windows_arm32-0.1.0.7z
                                               bin/dkml-install-setup.exe
                                               setup.exe
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-windows_arm32.sh that can produce testme-windows_arm32-0.1.0.tar.gz (etc.) archives
  
  7-Zip (r) 21.07 (x86) : Igor Pavlov : Public domain : 2021-12-26
  
  Scanning the drive:
  19 folders, 16 files, 12295168 bytes (12 MiB)
  
  Creating archive: target/testme-windows_x86_64-0.1.0.7z
  
  Add new data to archive: 19 folders, 16 files, 12295168 bytes (12 MiB)
  
  
  Files read from disk: 2
  Everything is Ok
  
  7-Zip (r) 21.07 (x86) : Igor Pavlov : Public domain : 2021-12-26
  
  Open archive: target/testme-windows_x86_64-0.1.0.7z
  --
  Path = target/testme-windows_x86_64-0.1.0.7z
  Type = 7z
  Physical Size = 1604649
  Headers Size = 645
  Method = LZMA2:12m LZMA:20 BCJ2
  Solid = +
  Blocks = 1
  
  Updating archive: target/testme-windows_x86_64-0.1.0.7z
  
  Keep old data in archive: 19 folders, 16 files, 12295168 bytes (12 MiB)
  Add new data to archive: 0 files, 0 bytes
  
  
  Files read from disk: 0
  Everything is Ok
  
  7-Zip (r) 21.07 (x86) : Igor Pavlov : Public domain : 2021-12-26
  
  Scanning the drive:
  13 folders, 14 files, 12295168 bytes (12 MiB)
  
  Creating archive: target/testme-windows_x86-0.1.0.7z
  
  Add new data to archive: 13 folders, 14 files, 12295168 bytes (12 MiB)
  
  
  Files read from disk: 2
  Everything is Ok
  
  7-Zip (r) 21.07 (x86) : Igor Pavlov : Public domain : 2021-12-26
  
  Open archive: target/testme-windows_x86-0.1.0.7z
  --
  Path = target/testme-windows_x86-0.1.0.7z
  Type = 7z
  Physical Size = 1604560
  Headers Size = 556
  Method = LZMA2:12m LZMA:20 BCJ2
  Solid = +
  Blocks = 1
  
  Updating archive: target/testme-windows_x86-0.1.0.7z
  
  Keep old data in archive: 13 folders, 14 files, 12295168 bytes (12 MiB)
  Add new data to archive: 0 files, 0 bytes
  
  
  Files read from disk: 0
  Everything is Ok
  
  7-Zip (r) 21.07 (x86) : Igor Pavlov : Public domain : 2021-12-26
  
  Scanning the drive:
  13 folders, 14 files, 12295168 bytes (12 MiB)
  
  Creating archive: target/testme-windows_arm64-0.1.0.7z
  
  Add new data to archive: 13 folders, 14 files, 12295168 bytes (12 MiB)
  
  
  Files read from disk: 2
  Everything is Ok
  
  7-Zip (r) 21.07 (x86) : Igor Pavlov : Public domain : 2021-12-26
  
  Open archive: target/testme-windows_arm64-0.1.0.7z
  --
  Path = target/testme-windows_arm64-0.1.0.7z
  Type = 7z
  Physical Size = 1604554
  Headers Size = 550
  Method = LZMA2:12m LZMA:20 BCJ2
  Solid = +
  Blocks = 1
  
  Updating archive: target/testme-windows_arm64-0.1.0.7z
  
  Keep old data in archive: 13 folders, 14 files, 12295168 bytes (12 MiB)
  Add new data to archive: 0 files, 0 bytes
  
  
  Files read from disk: 0
  Everything is Ok
  
  7-Zip (r) 21.07 (x86) : Igor Pavlov : Public domain : 2021-12-26
  
  Scanning the drive:
  13 folders, 14 files, 12295168 bytes (12 MiB)
  
  Creating archive: target/testme-windows_arm32-0.1.0.7z
  
  Add new data to archive: 13 folders, 14 files, 12295168 bytes (12 MiB)
  
  
  Files read from disk: 2
  Everything is Ok
  
  7-Zip (r) 21.07 (x86) : Igor Pavlov : Public domain : 2021-12-26
  
  Open archive: target/testme-windows_arm32-0.1.0.7z
  --
  Path = target/testme-windows_arm32-0.1.0.7z
  Type = 7z
  Physical Size = 1604555
  Headers Size = 551
  Method = LZMA2:12m LZMA:20 BCJ2
  Solid = +
  Blocks = 1
  
  Updating archive: target/testme-windows_arm32-0.1.0.7z
  
  Keep old data in archive: 13 folders, 14 files, 12295168 bytes (12 MiB)
  Add new data to archive: 0 files, 0 bytes
  
  
  Files read from disk: 0
  Everything is Ok

The --work-dir will have ABI-specific archive trees in its "a" folder. The
archive tree is what goes directly into the installer file (ex. setup.exe,
.msi, .rpm, etc.). The archive tree will be unpacked on the end-user's
machine.
Each archive tree contains a "sg" folder for the staging files and an "st"
folder for the static files.
  $ tree work
  work
  |-- a
  |   |-- android_arm32v7a
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- android_arm64v8a
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- android_x86
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- android_x86_64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- darwin_arm64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       |-- darwin_arm64
  |   |   |       |   `-- libpng.dylib
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- darwin_x86_64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       |-- darwin_x86_64
  |   |   |       |   `-- libpng.dylib
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- generic
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- linux_arm32v6
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- linux_arm32v7
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- linux_arm64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- linux_x86
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- linux_x86_64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- windows_arm32
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- windows_arm64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- windows_x86
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   `-- windows_x86_64
  |       |-- bin
  |       |   |-- dkml-install-admin-runner.exe
  |       |   |-- dkml-install-setup.exe
  |       |   |-- dkml-install-uninstaller.exe
  |       |   `-- dkml-install-user-runner.exe
  |       |-- lib
  |       |   |-- dkml-component-offline-test1
  |       |   |   |-- META
  |       |   |   `-- test1.cma
  |       |   |-- dkml-component-staging-ocamlrun
  |       |   |   |-- META
  |       |   |   `-- test2.cma
  |       |   `-- dkml-install-runner
  |       |       `-- plugins
  |       |           |-- dkml-plugin-offline-test1
  |       |           |   `-- META
  |       |           `-- dkml-plugin-staging-ocamlrun
  |       |               `-- META
  |       |-- sg
  |       |   |-- offline-test1
  |       |   |   `-- generic
  |       |   |       `-- install-offline-test1.bc
  |       |   `-- staging-ocamlrun
  |       |       `-- windows_x86_64
  |       |           |-- bin
  |       |           |   `-- ocamlrun.exe
  |       |           `-- lib
  |       |               `-- ocaml
  |       |                   `-- stublibs
  |       |                       `-- dllthreads.dll
  |       `-- st
  |           `-- offline-test1
  |               |-- README.txt
  |               `-- icon.png
  `-- sfx
      `-- 7zr.exe
  
  234 directories, 213 files

--------------------------------------------------------------------------------
Section: Bring-your-own-archiver archives
--------------------------------------------------------------------------------

Currently there is only one "supported" archiver: tar.

You could use your own tar archiver so you can distribute software for
*nix machines like Linux and macOS in the common .tar.gz or .tar.bz2 formats.

Eventually there will be:
* a zip archiver so you can use builtin zip file support on modern Windows
machines. (But the setup.exe installers are probably better; see the next section)
* a RPM/APK/DEB packager on Linux

We create "bundle" scripts that let you generate 'tar' archives specific
to the target operating systems. You can add tar options like '--gzip' (or RPM
spec files when we get a RPM packager) to the end of the bundle script to
customize the archive.

  $ tree work
  work
  |-- a
  |   |-- android_arm32v7a
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- android_arm64v8a
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- android_x86
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- android_x86_64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- darwin_arm64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       |-- darwin_arm64
  |   |   |       |   `-- libpng.dylib
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- darwin_x86_64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       |-- darwin_x86_64
  |   |   |       |   `-- libpng.dylib
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- generic
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- linux_arm32v6
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- linux_arm32v7
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- linux_arm64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- linux_x86
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- linux_x86_64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- windows_arm32
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- windows_arm64
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   |-- windows_x86
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
  |   |   |   |-- dkml-install-setup.exe
  |   |   |   |-- dkml-install-uninstaller.exe
  |   |   |   `-- dkml-install-user-runner.exe
  |   |   |-- lib
  |   |   |   |-- dkml-component-offline-test1
  |   |   |   |   |-- META
  |   |   |   |   `-- test1.cma
  |   |   |   |-- dkml-component-staging-ocamlrun
  |   |   |   |   |-- META
  |   |   |   |   `-- test2.cma
  |   |   |   `-- dkml-install-runner
  |   |   |       `-- plugins
  |   |   |           |-- dkml-plugin-offline-test1
  |   |   |           |   `-- META
  |   |   |           `-- dkml-plugin-staging-ocamlrun
  |   |   |               `-- META
  |   |   |-- sg
  |   |   |   `-- offline-test1
  |   |   |       `-- generic
  |   |   |           `-- install-offline-test1.bc
  |   |   `-- st
  |   |       `-- offline-test1
  |   |           |-- README.txt
  |   |           `-- icon.png
  |   `-- windows_x86_64
  |       |-- bin
  |       |   |-- dkml-install-admin-runner.exe
  |       |   |-- dkml-install-setup.exe
  |       |   |-- dkml-install-uninstaller.exe
  |       |   `-- dkml-install-user-runner.exe
  |       |-- lib
  |       |   |-- dkml-component-offline-test1
  |       |   |   |-- META
  |       |   |   `-- test1.cma
  |       |   |-- dkml-component-staging-ocamlrun
  |       |   |   |-- META
  |       |   |   `-- test2.cma
  |       |   `-- dkml-install-runner
  |       |       `-- plugins
  |       |           |-- dkml-plugin-offline-test1
  |       |           |   `-- META
  |       |           `-- dkml-plugin-staging-ocamlrun
  |       |               `-- META
  |       |-- sg
  |       |   |-- offline-test1
  |       |   |   `-- generic
  |       |   |       `-- install-offline-test1.bc
  |       |   `-- staging-ocamlrun
  |       |       `-- windows_x86_64
  |       |           |-- bin
  |       |           |   `-- ocamlrun.exe
  |       |           `-- lib
  |       |               `-- ocaml
  |       |                   `-- stublibs
  |       |                       `-- dllthreads.dll
  |       `-- st
  |           `-- offline-test1
  |               |-- README.txt
  |               `-- icon.png
  `-- sfx
      `-- 7zr.exe
  
  234 directories, 213 files
  $ tree target
  target
  |-- bundle-testme-android_arm32v7a.sh
  |-- bundle-testme-android_arm64v8a.sh
  |-- bundle-testme-android_x86.sh
  |-- bundle-testme-android_x86_64.sh
  |-- bundle-testme-darwin_arm64.sh
  |-- bundle-testme-darwin_x86_64.sh
  |-- bundle-testme-generic.sh
  |-- bundle-testme-linux_arm32v6.sh
  |-- bundle-testme-linux_arm32v7.sh
  |-- bundle-testme-linux_arm64.sh
  |-- bundle-testme-linux_x86.sh
  |-- bundle-testme-linux_x86_64.sh
  |-- bundle-testme-windows_arm32.sh
  |-- bundle-testme-windows_arm64.sh
  |-- bundle-testme-windows_x86.sh
  |-- bundle-testme-windows_x86_64.sh
  |-- setup-testme-windows_arm32-0.1.0.exe
  |-- setup-testme-windows_arm64-0.1.0.exe
  |-- setup-testme-windows_x86-0.1.0.exe
  |-- setup-testme-windows_x86_64-0.1.0.exe
  |-- testme-windows_arm32-0.1.0.7z
  |-- testme-windows_arm64-0.1.0.7z
  |-- testme-windows_x86-0.1.0.7z
  `-- testme-windows_x86_64-0.1.0.7z
  
  0 directories, 24 files

  $ target/bundle-testme-linux_x86_64.sh -o target tar
  $ tar tvf target/testme-linux_x86_64-0.1.0.tar | head -n5 | awk '{print $1, $NF}'
  drwxr-xr-x ./
  -rw-r--r-- testme-linux_x86_64-0.1.0/.archivetree
  drwxr-xr-x testme-linux_x86_64-0.1.0/bin/
  -rwxr-xr-x testme-linux_x86_64-0.1.0/bin/dkml-install-admin-runner.exe
  -rwxr-xr-x testme-linux_x86_64-0.1.0/bin/dkml-install-setup.exe

  $ target/bundle-testme-linux_x86_64.sh -o target -e .tar.gz tar --gzip
  $ tar tvfz target/testme-linux_x86_64-0.1.0.tar.gz | tail -n5 | awk '{print $1, $NF}'
  -rw-r--r-- testme-linux_x86_64-0.1.0/sg/offline-test1/generic/install-offline-test1.bc
  drwxr-xr-x testme-linux_x86_64-0.1.0/st/
  drwxr-xr-x testme-linux_x86_64-0.1.0/st/offline-test1/
  -rw-r--r-- testme-linux_x86_64-0.1.0/st/offline-test1/icon.png
  -rw-r--r-- testme-linux_x86_64-0.1.0/st/offline-test1/README.txt

--------------------------------------------------------------------------------
setup.exe installers
--------------------------------------------------------------------------------

There are also fully built setup.exe installers available.
  $ ../assets/lzma2107/bin/7zr.exe l target/testme-windows_x86_64-0.1.0.7z | awk '$1=="Date"{mode=1} mode==1{print $NF}'
  Name
  ------------------------
  bin
  lib
  lib\dkml-component-offline-test1
  lib\dkml-component-staging-ocamlrun
  lib\dkml-install-runner
  lib\dkml-install-runner\plugins
  lib\dkml-install-runner\plugins\dkml-plugin-offline-test1
  lib\dkml-install-runner\plugins\dkml-plugin-staging-ocamlrun
  sg
  sg\offline-test1
  sg\offline-test1\generic
  sg\staging-ocamlrun
  sg\staging-ocamlrun\windows_x86_64
  sg\staging-ocamlrun\windows_x86_64\bin
  sg\staging-ocamlrun\windows_x86_64\lib
  sg\staging-ocamlrun\windows_x86_64\lib\ocaml
  sg\staging-ocamlrun\windows_x86_64\lib\ocaml\stublibs
  st
  st\offline-test1
  .archivetree
  bin\dkml-install-admin-runner.exe
  bin\dkml-install-user-runner.exe
  lib\dkml-component-offline-test1\META
  lib\dkml-component-offline-test1\test1.cma
  lib\dkml-component-staging-ocamlrun\META
  lib\dkml-component-staging-ocamlrun\test2.cma
  lib\dkml-install-runner\plugins\dkml-plugin-offline-test1\META
  lib\dkml-install-runner\plugins\dkml-plugin-staging-ocamlrun\META
  sg\offline-test1\generic\install-offline-test1.bc
  sg\staging-ocamlrun\windows_x86_64\bin\ocamlrun.exe
  sg\staging-ocamlrun\windows_x86_64\lib\ocaml\stublibs\dllthreads.dll
  st\offline-test1\icon.png
  st\offline-test1\README.txt
  setup.exe
  bin\dkml-install-uninstaller.exe
  ------------------------
  folders

./setup_print_hello.ml
  $ cat ./setup_print_hello.ml
  $ target/setup-testme-windows_x86_64-0.1.0.exe
  Hello
