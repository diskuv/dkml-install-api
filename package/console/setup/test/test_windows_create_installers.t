Precheck that nothing unusual is in this test build directory
  $ ls
  test_windows_create_installers.exe
  test_windows_create_installers.t

Create the temporary work directory and the target installer directory
  $ install -d work
  $ install -d target

Create an Opam directory structure
TODO: dkml-install-admin-runner.exe is ABI native code today. They should be
TODO: built and downloaded from ABI asset repository, or built as bytecode.
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
  
  22 directories, 15 files

Run the create_installers.exe executable. Actually, there is one modification
we did to this executable: it has two test components defined.
  $ ./test_windows_create_installers.exe --program-title "Test Me" --program-name testme --program-version 0.1.0 --opam-context=_opam/ --target-dir=target/ --work-dir=work/ --verbose | tr '\\' '/' | grep -v "Archive size"
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
                                             work\sfx\7z.exe a -bb0 -mx9 -y
                                               target\testme-windows_x86_64-0.1.0.7z
                                               .\work\a\windows_x86_64\*
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-windows_x86_64.sh that can produce testme-windows_x86_64-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating setup-testme-windows_x86-0.1.0.exe
  test_windows_create_installers.exe: [INFO] Creating 7z archive with: 
                                             work\sfx\7z.exe a -bb0 -mx9 -y
                                               target\testme-windows_x86-0.1.0.7z
                                               .\work\a\windows_x86\*
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-windows_x86.sh that can produce testme-windows_x86-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating setup-testme-windows_arm64-0.1.0.exe
  test_windows_create_installers.exe: [INFO] Creating 7z archive with: 
                                             work\sfx\7z.exe a -bb0 -mx9 -y
                                               target\testme-windows_arm64-0.1.0.7z
                                               .\work\a\windows_arm64\*
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-windows_arm64.sh that can produce testme-windows_arm64-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating setup-testme-windows_arm32-0.1.0.exe
  test_windows_create_installers.exe: [INFO] Creating 7z archive with: 
                                             work\sfx\7z.exe a -bb0 -mx9 -y
                                               target\testme-windows_arm32-0.1.0.7z
                                               .\work\a\windows_arm32\*
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-windows_arm32.sh that can produce testme-windows_arm32-0.1.0.tar.gz (etc.) archives
  
  7-Zip 21.07 (x86) : Copyright (c) 1999-2021 Igor Pavlov : 2021-12-26
  
  Scanning the drive:
  19 folders, 13 files, 0 bytes
  
  Creating archive: target/testme-windows_x86_64-0.1.0.7z
  
  Add new data to archive: 19 folders, 13 files, 0 bytes
  
  
  Files read from disk: 0
  Everything is Ok
  
  7-Zip 21.07 (x86) : Copyright (c) 1999-2021 Igor Pavlov : 2021-12-26
  
  Scanning the drive:
  13 folders, 11 files, 0 bytes
  
  Creating archive: target/testme-windows_x86-0.1.0.7z
  
  Add new data to archive: 13 folders, 11 files, 0 bytes
  
  
  Files read from disk: 0
  Everything is Ok
  
  7-Zip 21.07 (x86) : Copyright (c) 1999-2021 Igor Pavlov : 2021-12-26
  
  Scanning the drive:
  13 folders, 11 files, 0 bytes
  
  Creating archive: target/testme-windows_arm64-0.1.0.7z
  
  Add new data to archive: 13 folders, 11 files, 0 bytes
  
  
  Files read from disk: 0
  Everything is Ok
  
  7-Zip 21.07 (x86) : Copyright (c) 1999-2021 Igor Pavlov : 2021-12-26
  
  Scanning the drive:
  13 folders, 11 files, 0 bytes
  
  Creating archive: target/testme-windows_arm32-0.1.0.7z
  
  Add new data to archive: 13 folders, 11 files, 0 bytes
  
  
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
      |-- 7z.dll
      `-- 7z.exe
  
  234 directories, 182 files

We create "bundle" scripts that let you generate 'tar' archives specific
to the target operating systems. You can add tar options like '--gzip' to
the end of the bundle script to customize the archive.
  $ tree work
  work
  |-- a
  |   |-- android_arm32v7a
  |   |   |-- bin
  |   |   |   |-- dkml-install-admin-runner.exe
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
      |-- 7z.dll
      `-- 7z.exe
  
  234 directories, 182 files
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
  drwxr-xr-x testme-linux_x86_64-0.1.0/bin/
  -rwxr-xr-x testme-linux_x86_64-0.1.0/bin/dkml-install-admin-runner.exe
  -rwxr-xr-x testme-linux_x86_64-0.1.0/bin/dkml-install-user-runner.exe
  drwxr-xr-x testme-linux_x86_64-0.1.0/lib/

  $ target/bundle-testme-linux_x86_64.sh -o target -e .tar.gz tar --gzip
  $ tar tvfz target/testme-linux_x86_64-0.1.0.tar.gz | tail -n5 | awk '{print $1, $NF}'
  -rw-r--r-- testme-linux_x86_64-0.1.0/sg/offline-test1/generic/install-offline-test1.bc
  drwxr-xr-x testme-linux_x86_64-0.1.0/st/
  drwxr-xr-x testme-linux_x86_64-0.1.0/st/offline-test1/
  -rw-r--r-- testme-linux_x86_64-0.1.0/st/offline-test1/icon.png
  -rw-r--r-- testme-linux_x86_64-0.1.0/st/offline-test1/README.txt

There are also fully built setup.exe installers available.
  $ ../assets/7z2107/7z.exe l target/testme-windows_x86_64-0.1.0.7z | awk '$1=="Date"{mode=1} mode==1{print $NF}'
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
  ------------------------
  folders

  $ target/setup-testme-windows_x86_64-0.1.0.exe -h

  $ install -d enduser
  $ target/setup-testme-windows_x86_64-0.1.0.exe x -oenduser | grep -v setup-testme
  [1]
Everything is Ok
  $ tree enduser
  enduser
  
  0 directories, 0 files
