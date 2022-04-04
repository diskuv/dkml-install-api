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
  $ ./test_windows_create_installers.exe --program-name test_windows --program-version 0.1.0 --opam-context=_opam/ --target-dir=target/ --work-dir=work/ --verbose
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

Postcheck all the directories
  $ ls target
  $ ls work
  archive
  $ tree _opam work
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
  work
  `-- archive
      |-- android_arm32v7a
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- android_arm64v8a
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- android_x86
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- android_x86_64
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- darwin_arm64
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       |-- darwin_arm64
      |   |       |   `-- libpng.dylib
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- darwin_x86_64
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       |-- darwin_x86_64
      |   |       |   `-- libpng.dylib
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- generic
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- linux_arm32v6
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- linux_arm32v7
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- linux_arm64
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- linux_x86
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- linux_x86_64
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- windows_arm32
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- windows_arm64
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      |-- windows_x86
      |   |-- bin
      |   |   |-- dkml-install-admin-runner.exe
      |   |   `-- dkml-install-user-runner.exe
      |   |-- lib
      |   |   |-- dkml-component-offline-test1
      |   |   |   |-- META
      |   |   |   `-- test1.cma
      |   |   |-- dkml-component-staging-ocamlrun
      |   |   |   |-- META
      |   |   |   `-- test2.cma
      |   |   `-- dkml-install-runner
      |   |       `-- plugins
      |   |           |-- dkml-plugin-offline-test1
      |   |           |   `-- META
      |   |           `-- dkml-plugin-staging-ocamlrun
      |   |               `-- META
      |   |-- staging
      |   |   `-- offline-test1
      |   |       `-- generic
      |   |           `-- install-offline-test1.bc
      |   `-- static
      |       `-- offline-test1
      |           |-- README.txt
      |           `-- icon.png
      `-- windows_x86_64
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
          |-- staging
          |   |-- offline-test1
          |   |   `-- generic
          |   |       `-- install-offline-test1.bc
          |   `-- staging-ocamlrun
          |       `-- windows_x86_64
          |           |-- bin
          |           |   `-- ocamlrun.exe
          |           `-- lib
          |               `-- ocaml
          |                   `-- stublibs
          |                       `-- dllthreads.dll
          `-- static
              `-- offline-test1
                  |-- README.txt
                  `-- icon.png
  
  255 directories, 195 files
