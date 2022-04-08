The goal of this CRAM test is to demonstrate, document and test how
self-extracting archives work on Windows.

Documentation:

* The main documentation tool for Diskuv projects is Sphinx, and sections of this
CRAM test can be directly included into Sphinx documentation using
the `literalinclude` directive and the `start-after/start-at/end-before/end-at`
attributes:
https://www.sphinx-doc.org/en/master/usage/restructuredtext/directives.html#directive-literalinclude
* The README.md can also be generated from reStructuredText to markdown with
`pandoc`, perhaps as part of a `dune runtest --auto-promote` workflow.

==> This file is the authoritative source of code examples for Windows.

--------------------------------------------------------------------------------
Initial Conditions
--------------------------------------------------------------------------------

Check what is present in this directory
[initial_conditions_checkdir]
  $ ls
  setup_print_hello.exe
  setup_print_hello.ml
  test_windows_create_installers.exe
  test_windows_create_installers.ml
  test_windows_create_installers.t
  uninstaller_print_bye.exe
[initial_conditions_checkdir]

--------------------------------------------------------------------------------
Generating the installer starts with an Opam switch
--------------------------------------------------------------------------------

We'll just mimic an Opam switch by creating a directory structure and some
files.

We want to model an Opam "installer" package that has two components:
* dkml-component-staging-ocamlrun
* dkml-component-offline-test1

The files will just be empty files, except for two important files:
* dkml-install-setup.exe will print "Hello"
* dkml-install-uninstaller.exe will print "Bye"

If this were not a demonstration, we would let the dkml-install-api framework
generate those two files for us.

Sidenote:
| dkml-install-setup.exe is implicitly native code produced by Dune.
| That means the build machine (the machine generating the Opam directory tree)
| must be the same ABI as the end-user machine (the machine where the installer
| runs). That is a sucky sucky limitation!
| So ... we could either download prebuilt ABI-specific dkml-install-setup.exe
| and dkml-install-uninstaller.exe, or we could distribute those two files
| as OCaml bytecode.

[opam_switch_mimic]
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
  $ diskuvbox tree --encoding UTF-8 -d 5 _opam
  _opam
  ├── bin/
  │   ├── dkml-install-admin-runner.exe
  │   ├── dkml-install-setup.exe
  │   ├── dkml-install-uninstaller.exe
  │   └── dkml-install-user-runner.exe
  ├── lib/
  │   ├── dkml-component-offline-test1/
  │   │   ├── META
  │   │   └── test1.cma
  │   ├── dkml-component-staging-ocamlrun/
  │   │   ├── META
  │   │   └── test2.cma
  │   └── dkml-install-runner/
  │       └── plugins/
  │           ├── dkml-plugin-offline-test1/
  │           │   └── META
  │           └── dkml-plugin-staging-ocamlrun/
  │               └── META
  └── share/
      ├── dkml-component-offline-test1/
      │   ├── staging-files/
      │   │   ├── darwin_arm64/
      │   │   │   └── libpng.dylib
      │   │   ├── darwin_x86_64/
      │   │   │   └── libpng.dylib
      │   │   └── generic/
      │   │       └── install-offline-test1.bc
      │   └── static-files/
      │       ├── README.txt
      │       └── icon.png
      └── dkml-component-staging-ocamlrun/
          └── staging-files/
              └── windows_x86_64/
                  ├── bin/
                  └── lib/
[opam_switch_mimic]

--------------------------------------------------------------------------------
Section: What are these components?
--------------------------------------------------------------------------------

In a typical graphical desktop installer, you are able to select which pieces of
an application are installed on your machine. For example, a Git installer
could ask whether you wanted to install the "Git LFS" extension for large
file support. These pieces of an application are called components.

For now, we'll define two do-nothing test components:
`staging-ocamlrun` and `offline-test1`

and we will also use a library to generate an executable
called `create_installers.exe`:

[what_are_components]
  $ cat test_windows_create_installers.ml
  open Cmdliner
  
  (* Create some demonstration components that are immediately registered *)
  
  let () =
    let reg = Dkml_install_register.Component_registry.get () in
    Dkml_install_register.Component_registry.add_component reg
      (module struct
        include Dkml_install_api.Default_component_config
  
        let component_name = "offline-test1"
      end);
    Dkml_install_register.Component_registry.add_component reg
      (module struct
        include Dkml_install_api.Default_component_config
  
        let component_name = "staging-ocamlrun"
      end)
  
  (* Let's also create an entry point for `create_installers.exe` *)
  let () = Term.(exit @@ Dkml_package_console_setup.create_installers ())
[what_are_components]

If this were not a demonstration, all your components would be dynamically
probed from your Opam directory structure using the Dune Site plugin:
https://dune.readthedocs.io/en/latest/sites.html#plugins-and-dynamic-loading-of-packages

You can see a real component at:
https://github.com/diskuv/dkml-component-curl/blob/1cbecbaf7252e1fbe2ee5f56805fcf03e34fb4b6/src/buildtime_installer/dkml_component_staging_curl.ml

  $ echo
  

--------------------------------------------------------------------------------
Section: Use the generated `create_installers.exe`
--------------------------------------------------------------------------------

Important:
| `create_installers.exe` will create installers for you based on the components
| you registered earlier.

Create the temporary work directory and the target installer directory:
[create_installers_dirs]
  $ install -d work
  $ install -d target
[create_installers_dirs]

Run the create_installers.exe executable.

Side note:
| If this were not a demonstration, you would be doing this in your
| installer .opam file with something like:
|   [
|     "%{bin}%/dkml-install-generate.exe"
|     "--program-name"
|     name
|     "--program-version"
|     version
|     "--work-dir"
|     "_build/iw"
|     "--target-dir"
|     "%{_:share}%"
|   ]

[create_installers_run]
  $ ./test_windows_create_installers.exe --program-name testme --program-version 0.1.0 --opam-context=_opam/ --target-dir=target/ --work-dir=work/ --abi=linux_x86_64 --abi=windows_x86_64 --verbose
  test_windows_create_installers.exe: [INFO] Installers will be created that include the components: 
                                             [staging-ocamlrun; offline-test1]
  test_windows_create_installers.exe: [INFO] Installers will be created for the ABIs: 
                                             [generic; linux_x86_64;
                                              windows_x86_64]
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-generic.sh that can produce testme-generic-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-linux_x86_64.sh that can produce testme-linux_x86_64-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating setup-testme-windows_x86_64-0.1.0.exe
  test_windows_create_installers.exe: [INFO] Creating 7z archive with: 
                                             work\sfx\7zr.exe a -bso0 -mx9 -y
                                               target\testme-windows_x86_64-0.1.0.7z
                                               .\work\a\windows_x86_64\*
  test_windows_create_installers.exe: [INFO] Renaming within a 7z archive with: 
                                             work\sfx\7zr.exe rn -bso0 -mx9 -y
                                               target\testme-windows_x86_64-0.1.0.7z
                                               bin/dkml-install-setup.exe
                                               setup.exe
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-testme-windows_x86_64.sh that can produce testme-windows_x86_64-0.1.0.tar.gz (etc.) archives
[create_installers_run]

The --work-dir will have ABI-specific archive trees in its "a" folder.

The archive tree is the content that is packed into the installer file
(ex. setup.exe, .msi, .rpm, etc.) and which gets unpacked on the
end-user's machine.

Each archive tree contains a "sg" folder for the staging files ... these
are files that are used during the installation but disappear when the
installation is finished.

Each archive tree also contains a "st" folder for the static files ... these
are files that are directly copied to the end-user's installation directory.

[create_installers_work]
  $ diskuvbox tree --encoding UTF-8 -d 5 work
  work
  ├── a/
  │   ├── generic/
  │   │   ├── bin/
  │   │   │   ├── dkml-install-admin-runner.exe
  │   │   │   ├── dkml-install-setup.exe
  │   │   │   ├── dkml-install-uninstaller.exe
  │   │   │   └── dkml-install-user-runner.exe
  │   │   ├── lib/
  │   │   │   ├── dkml-component-offline-test1/
  │   │   │   │   ├── META
  │   │   │   │   └── test1.cma
  │   │   │   ├── dkml-component-staging-ocamlrun/
  │   │   │   │   ├── META
  │   │   │   │   └── test2.cma
  │   │   │   └── dkml-install-runner/
  │   │   │       └── plugins/
  │   │   ├── sg/
  │   │   │   └── offline-test1/
  │   │   │       └── generic/
  │   │   └── st/
  │   │       └── offline-test1/
  │   │           ├── README.txt
  │   │           └── icon.png
  │   ├── linux_x86_64/
  │   │   ├── bin/
  │   │   │   ├── dkml-install-admin-runner.exe
  │   │   │   ├── dkml-install-setup.exe
  │   │   │   ├── dkml-install-uninstaller.exe
  │   │   │   └── dkml-install-user-runner.exe
  │   │   ├── lib/
  │   │   │   ├── dkml-component-offline-test1/
  │   │   │   │   ├── META
  │   │   │   │   └── test1.cma
  │   │   │   ├── dkml-component-staging-ocamlrun/
  │   │   │   │   ├── META
  │   │   │   │   └── test2.cma
  │   │   │   └── dkml-install-runner/
  │   │   │       └── plugins/
  │   │   ├── sg/
  │   │   │   └── offline-test1/
  │   │   │       └── generic/
  │   │   └── st/
  │   │       └── offline-test1/
  │   │           ├── README.txt
  │   │           └── icon.png
  │   └── windows_x86_64/
  │       ├── bin/
  │       │   ├── dkml-install-admin-runner.exe
  │       │   ├── dkml-install-setup.exe
  │       │   ├── dkml-install-uninstaller.exe
  │       │   └── dkml-install-user-runner.exe
  │       ├── lib/
  │       │   ├── dkml-component-offline-test1/
  │       │   │   ├── META
  │       │   │   └── test1.cma
  │       │   ├── dkml-component-staging-ocamlrun/
  │       │   │   ├── META
  │       │   │   └── test2.cma
  │       │   └── dkml-install-runner/
  │       │       └── plugins/
  │       ├── sg/
  │       │   ├── offline-test1/
  │       │   │   └── generic/
  │       │   └── staging-ocamlrun/
  │       │       └── windows_x86_64/
  │       └── st/
  │           └── offline-test1/
  │               ├── README.txt
  │               └── icon.png
  └── sfx/
      └── 7zr.exe
[create_installers_work]

--------------------------------------------------------------------------------
Section: Bring-your-own-archiver archives
--------------------------------------------------------------------------------

Currently there is only one "supported" archiver: tar.

You could use your own tar archiver so you can distribute software for
*nix machines like Linux and macOS in the common .tar.gz or .tar.bz2 formats.

There could be others:
* a zip archiver so you can use builtin zip file support on modern Windows
machines. (But the setup.exe installers are probably better; see the next
section)
* a RPM/APK/DEB packager on Linux

We create "bundle" scripts that let you generate 'tar' archives specific
to the target operating systems. You can add tar options like '--gzip'
to the end of the bundle script to customize the archive.

Sidenote:
| The reason we use scripts rather than create the archives directly is
| to lessen the OCaml dependencies of dkml-install-api. You usually can
| install or use an archiver (ex. tar.exe + gzip.exe) on a build system,
| which will be more performant, maintainable and customizable than doing
| tar (or RPM, etc.) inside of OCaml.

[archiver_session]
  $ diskuvbox tree --encoding UTF-8 -d 5 work
  work
  ├── a/
  │   ├── generic/
  │   │   ├── bin/
  │   │   │   ├── dkml-install-admin-runner.exe
  │   │   │   ├── dkml-install-setup.exe
  │   │   │   ├── dkml-install-uninstaller.exe
  │   │   │   └── dkml-install-user-runner.exe
  │   │   ├── lib/
  │   │   │   ├── dkml-component-offline-test1/
  │   │   │   │   ├── META
  │   │   │   │   └── test1.cma
  │   │   │   ├── dkml-component-staging-ocamlrun/
  │   │   │   │   ├── META
  │   │   │   │   └── test2.cma
  │   │   │   └── dkml-install-runner/
  │   │   │       └── plugins/
  │   │   ├── sg/
  │   │   │   └── offline-test1/
  │   │   │       └── generic/
  │   │   └── st/
  │   │       └── offline-test1/
  │   │           ├── README.txt
  │   │           └── icon.png
  │   ├── linux_x86_64/
  │   │   ├── bin/
  │   │   │   ├── dkml-install-admin-runner.exe
  │   │   │   ├── dkml-install-setup.exe
  │   │   │   ├── dkml-install-uninstaller.exe
  │   │   │   └── dkml-install-user-runner.exe
  │   │   ├── lib/
  │   │   │   ├── dkml-component-offline-test1/
  │   │   │   │   ├── META
  │   │   │   │   └── test1.cma
  │   │   │   ├── dkml-component-staging-ocamlrun/
  │   │   │   │   ├── META
  │   │   │   │   └── test2.cma
  │   │   │   └── dkml-install-runner/
  │   │   │       └── plugins/
  │   │   ├── sg/
  │   │   │   └── offline-test1/
  │   │   │       └── generic/
  │   │   └── st/
  │   │       └── offline-test1/
  │   │           ├── README.txt
  │   │           └── icon.png
  │   └── windows_x86_64/
  │       ├── bin/
  │       │   ├── dkml-install-admin-runner.exe
  │       │   ├── dkml-install-setup.exe
  │       │   ├── dkml-install-uninstaller.exe
  │       │   └── dkml-install-user-runner.exe
  │       ├── lib/
  │       │   ├── dkml-component-offline-test1/
  │       │   │   ├── META
  │       │   │   └── test1.cma
  │       │   ├── dkml-component-staging-ocamlrun/
  │       │   │   ├── META
  │       │   │   └── test2.cma
  │       │   └── dkml-install-runner/
  │       │       └── plugins/
  │       ├── sg/
  │       │   ├── offline-test1/
  │       │   │   └── generic/
  │       │   └── staging-ocamlrun/
  │       │       └── windows_x86_64/
  │       └── st/
  │           └── offline-test1/
  │               ├── README.txt
  │               └── icon.png
  └── sfx/
      └── 7zr.exe

  $ diskuvbox tree --encoding UTF-8 -d 5 target
  target
  ├── bundle-testme-generic.sh
  ├── bundle-testme-linux_x86_64.sh
  ├── bundle-testme-windows_x86_64.sh
  ├── setup-testme-windows_x86_64-0.1.0.exe
  └── testme-windows_x86_64-0.1.0.7z

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
[archiver_session]

--------------------------------------------------------------------------------
Section: setup.exe installers
--------------------------------------------------------------------------------

There are also fully built setup.exe installers available.
The setup.exe is just a special version of the decompressor 7z.exe called an
"SFX" module, with a 7zip archive appended.

Let's start with the 7zip archive that we generate.  You will see that its
contents is exactly the same as the archive tree, except that
`bin\dkml-install-setup.exe` has been renamed to `setup.exe`.

[setup_exe_list_7z]
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
[setup_exe_list_7z]

We would see the same thing if we looked inside the generated
`setup-NAME-VER.exe` (which is just the SFX module and the .7z archive above):

[setup_exe_list_exe]
  $ ../assets/lzma2107/bin/7zr.exe l target/setup-testme-windows_x86_64-0.1.0.exe | awk '$1=="Date"{mode=1} mode==1{print $NF}' | head -n10
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
[setup_exe_list_exe]

When setup.exe is run, the SFX module knows how to find the 7zip archive stored
at the end of setup.exe (which you see above), decompress it to a temporary
directory, and then run an executable inside the temporary directory.

To make keep things confusing, the temporary executable that 7zip runs is
the member "setup.exe" found in the .7z root directory.

If we were to run the `bin\dkml-install-setup.exe` from the original archive
tree we would just get a "Hello" printed.

Here is the code for that:
[setup_exe_setup_ml]
  $ cat ./setup_print_hello.ml
  let () = print_endline "Hello"
[setup_exe_setup_ml]

Since the generated `setup-NAME-VER.exe` will decompress the .7z archive and run
the `setup.exe` it found in the .7z root directory, we expect to see "Hello"
printed. Which is what we see:
[setup_exe_run]
  $ target/setup-testme-windows_x86_64-0.1.0.exe
  Hello
[setup_exe_run]

To recap:
1. Opam directory structure is used to build a directory structure for the
archive tree.
2. You can create .tar.gz or .tar.bz2 binary distributions from the archive
tree.
3. You can also use the setup-NAME-VER.exe which has been designed to
automatically run `bin\dkml-install-setup.exe`.

Whether manually uncompressing a .tar.gz binary distribution, or letting
setup-NAME-VER.exe do it automatically, the original
`bin\dkml-install-setup.exe` will have full access to the archive tree.

That's it for how archives and setup.exe work!

--------------------------------------------------------------------------------

TODO: Use another cram test to show what a the real `bin\dkml-install-setup.exe`
does, using one or more real component. Perhaps place the cram test in
dkml-installer-network-ocaml (or a demonstration Opam package that depends on
dkml-installer-network-ocaml).
