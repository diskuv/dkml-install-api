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
  entry_print_salut.exe
  runner_admin_print_hi.exe
  runner_user_print_zoo.exe
  setup_print_hello.exe
  setup_print_hello.ml
  test_windows_create_installers.exe
  test_windows_create_installers.ml
  test_windows_create_installers.t
  uninstaller_print_bye.exe
  uninstaller_print_bye.ml
[initial_conditions_checkdir]

--------------------------------------------------------------------------------
Generating the installer starts with an Opam switch
--------------------------------------------------------------------------------

We'll just mimic an Opam switch by creating a directory structure and some
files.

We want to model an Opam "installer" package that has two components:
* dkml-component-staging-ocamlrun
* dkml-component-offline-test1

The files will just be empty files.

[opam_switch_mimic]
  $ install -d _opam/bin
  $ install -d _opam/lib/dkml-component-offline-test1
  $ install -d _opam/lib/dkml-component-staging-ocamlrun
  $ install -d _opam/share/dkml-component-offline-test1/staging-files/generic
  $ install -d _opam/share/dkml-component-offline-test1/static-files
  $ install -d _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/bin
  $ install -d _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/lib/ocaml/stublibs
  $ install -d _opam/share/dkml-component-offline-test1/staging-files/darwin_arm64
  $ install -d _opam/share/dkml-component-offline-test1/staging-files/darwin_x86_64
  $ diskuvbox touch _opam/bin/dkml-install-admin-runner.exe
  $ diskuvbox touch _opam/bin/dkml-install-user-runner.exe
  $ diskuvbox touch _opam/share/dkml-component-offline-test1/staging-files/generic/install-offline-test1.bc
  $ diskuvbox touch _opam/share/dkml-component-offline-test1/staging-files/darwin_arm64/libpng.dylib
  $ diskuvbox touch _opam/share/dkml-component-offline-test1/staging-files/darwin_x86_64/libpng.dylib
  $ diskuvbox touch _opam/share/dkml-component-offline-test1/static-files/README.txt
  $ diskuvbox touch _opam/share/dkml-component-offline-test1/static-files/icon.png
  $ diskuvbox touch _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/bin/ocamlrun.exe
  $ diskuvbox touch _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/lib/ocaml/stublibs/dllthreads.dll
  $ diskuvbox tree --encoding UTF-8 -d 5 _opam
  _opam
  ├── bin/
  │   ├── dkml-install-admin-runner.exe
  │   └── dkml-install-user-runner.exe
  ├── lib/
  │   ├── dkml-component-offline-test1/
  │   └── dkml-component-staging-ocamlrun/
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
  let () =
    Term.(
      exit
      @@ Dkml_package_console_create.create_installers
           {
             legal_name = "Legal Name";
             common_name_full = "Common Name";
             common_name_camel_case_nospaces = "CommonName";
             common_name_kebab_lower_case = "common-name";
           }
           {
             name_full = "Full Name";
             name_camel_case_nospaces = "FullName";
             name_kebab_lower_case = "full-name";
             installation_prefix_camel_case_nospaces_opt = None;
             installation_prefix_kebab_lower_case_opt = None;
           })
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

We will need to supply two important files generated with a "packager". Today
the only packager is the Console packager, which runs
installation/uninstallation on the end-user's machine as a Console program (as
opposed to a GUI program traditional on Windows machines).

If this were not a demonstration focused only on how the installer is made, we
would let the dkml-install-api framework generate those two files for us.
Instead we use two test executables:

Side note:
| dkml-package-setup.bc is implicitly native code produced by Dune.
| That means the build machine (the machine generating the Opam directory tree)
| must be the same ABI as the end-user machine (the machine where the installer
| runs). That is a sucky sucky limitation!
| So ... we could either download prebuilt ABI-specific dkml-package-setup.bc
| and dkml-package-uninstaller.bc, or we could distribute those two files
| as OCaml bytecode.

[create_installers_packagerinput]
  $ cat ./setup_print_hello.ml
  let () = print_endline "Hello"
  $ cat ./uninstaller_print_bye.ml
  let () = print_endline "Bye"
  $ ./setup_print_hello.exe
  Hello
  $ ./uninstaller_print_bye.exe
  Bye
[create_installers_packagerinput]

Run the create_installers.exe executable.

Side note:
| If this were not a demonstration, you would be doing the same steps in your
| installer .opam file with something like:
|   [
|     "%{bin}%/dkml-install-create-installers.exe"
|     "--program-version"
|     version
|     "--work-dir"
|     "%{_:share}%/w"
|     "--target-dir"
|     "%{_:share}%/t"
|     "--packager-setup-bytecode"
|     "%{bin}%/setup.exe"
|     "--packager-uninstaller-bytecode"
|     "%{bin}%/uninstaller.exe"
|   ]

[create_installers_run]
  $ ./test_windows_create_installers.exe --program-version 0.1.0 --opam-context=_opam/ --target-dir=target/ --work-dir=work/ --abi=linux_x86_64 --abi=windows_x86_64 --packager-entry-exe ./entry_print_salut.exe --packager-setup-bytecode ./setup_print_hello.exe --packager-uninstaller-bytecode ./uninstaller_print_bye.exe --runner-admin-exe ./runner_admin_print_hi.exe --runner-user-exe ./runner_user_print_zoo.exe --verbose
  test_windows_create_installers.exe: [INFO] Installers will be created that include the components: 
                                             [staging-ocamlrun; offline-test1]
  test_windows_create_installers.exe: [INFO] Installers will be created for the ABIs: 
                                             [generic; linux_x86_64;
                                              windows_x86_64]
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-full-name-generic.sh that can produce full-name-generic-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-full-name-linux_x86_64.sh that can produce full-name-linux_x86_64-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating unsigned-full-name-windows_x86_64-0.1.0.exe
  Parsing of manifest successful.
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-full-name-windows_x86_64.sh that can produce full-name-windows_x86_64-0.1.0.tar.gz (etc.) archives
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

Each archive tree also contains the packager executables named as
bin/dkml-package-setup.bc and bin/dkml-package-uninstaller.bc

[create_installers_work]
  $ diskuvbox tree --encoding UTF-8 -d 5 work
  work
  ├── a/
  │   ├── generic/
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
  │   │   │   ├── dkml-install-user-runner.exe
  │   │   │   ├── dkml-package-entry.exe
  │   │   │   ├── dkml-package-setup.bc
  │   │   │   └── dkml-package-uninstaller.bc
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
  │       │   ├── dkml-install-user-runner.exe
  │       │   ├── dkml-package-entry.exe
  │       │   ├── dkml-package-setup.bc
  │       │   └── dkml-package-uninstaller.bc
  │       ├── sg/
  │       │   ├── offline-test1/
  │       │   │   └── generic/
  │       │   └── staging-ocamlrun/
  │       │       └── windows_x86_64/
  │       └── st/
  │           └── offline-test1/
  │               ├── README.txt
  │               └── icon.png
  ├── setup.exe.manifest
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
  │   │   │   ├── dkml-install-user-runner.exe
  │   │   │   ├── dkml-package-entry.exe
  │   │   │   ├── dkml-package-setup.bc
  │   │   │   └── dkml-package-uninstaller.bc
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
  │       │   ├── dkml-install-user-runner.exe
  │       │   ├── dkml-package-entry.exe
  │       │   ├── dkml-package-setup.bc
  │       │   └── dkml-package-uninstaller.bc
  │       ├── sg/
  │       │   ├── offline-test1/
  │       │   │   └── generic/
  │       │   └── staging-ocamlrun/
  │       │       └── windows_x86_64/
  │       └── st/
  │           └── offline-test1/
  │               ├── README.txt
  │               └── icon.png
  ├── setup.exe.manifest
  └── sfx/
      └── 7zr.exe

  $ diskuvbox tree --encoding UTF-8 -d 5 target
  target
  ├── bundle-full-name-generic.sh
  ├── bundle-full-name-linux_x86_64.sh
  ├── bundle-full-name-windows_x86_64.sh
  ├── full-name-windows_x86_64-0.1.0.7z
  ├── full-name-windows_x86_64-7zS2.sfx
  └── unsigned-full-name-windows_x86_64-0.1.0.exe

  $ target/bundle-full-name-linux_x86_64.sh -o target tar
  $ tar tvf target/full-name-linux_x86_64-0.1.0.tar | head -n5 | awk '{print $NF}' | sort
  ./
  full-name-linux_x86_64-0.1.0/.archivetree
  full-name-linux_x86_64-0.1.0/bin/
  full-name-linux_x86_64-0.1.0/bin/dkml-install-admin-runner.exe
  full-name-linux_x86_64-0.1.0/bin/dkml-install-user-runner.exe

  $ target/bundle-full-name-linux_x86_64.sh -o target -e .tar.gz tar --gzip
  $ tar tvfz target/full-name-linux_x86_64-0.1.0.tar.gz | tail -n5 | awk '{print $NF}' | sort
  full-name-linux_x86_64-0.1.0/sg/offline-test1/generic/install-offline-test1.bc
  full-name-linux_x86_64-0.1.0/st/
  full-name-linux_x86_64-0.1.0/st/offline-test1/
  full-name-linux_x86_64-0.1.0/st/offline-test1/README.txt
  full-name-linux_x86_64-0.1.0/st/offline-test1/icon.png
[archiver_session]

--------------------------------------------------------------------------------
Section: setup.exe installers
--------------------------------------------------------------------------------

There are also fully built setup.exe installers available.
The setup.exe is just a special version of the decompressor 7z.exe called an
"SFX" module, with a 7zip archive appended.

Let's start with the 7zip archive that we generate.  You will see that its
contents is exactly the same as the archive tree, except that
`bin/dkml-package-entry.exe`
(the *packager entry* setup.exe) has been renamed to
`setup.exe`.

[setup_exe_list_7z]
  $ ../assets/lzma2107/bin/7zr.exe l target/full-name-windows_x86_64-0.1.0.7z | awk '$1=="Date"{mode=1} mode==1{print $NF}'
  Name
  ------------------------
  bin
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
  sg\offline-test1\generic\install-offline-test1.bc
  sg\staging-ocamlrun\windows_x86_64\bin\ocamlrun.exe
  sg\staging-ocamlrun\windows_x86_64\lib\ocaml\stublibs\dllthreads.dll
  st\offline-test1\icon.png
  st\offline-test1\README.txt
  bin\dkml-package-setup.bc
  bin\dkml-package-uninstaller.bc
  bin\dkml-install-admin-runner.exe
  bin\dkml-install-user-runner.exe
  setup.exe
  vcruntime140.dll
  vcruntime140_1.dll
  vc_redist.dkml-target-abi.exe
  ------------------------
  folders
[setup_exe_list_7z]

We would see the same thing if we looked inside the *installer*
`unsigned-NAME-VER.exe` (which is just the SFX module and the .7z archive above):

[setup_exe_list_exe]
  $ ../assets/lzma2107/bin/7zr.exe l target/unsigned-full-name-windows_x86_64-0.1.0.exe | awk '$1=="Date"{mode=1} mode==1{print $NF}' | head -n10
  Name
  ------------------------
  bin
  sg
  sg\offline-test1
  sg\offline-test1\generic
  sg\staging-ocamlrun
  sg\staging-ocamlrun\windows_x86_64
  sg\staging-ocamlrun\windows_x86_64\bin
  sg\staging-ocamlrun\windows_x86_64\lib
[setup_exe_list_exe]

When the *installer* setup.exe is run, the SFX module knows how to find the 7zip
archive stored at the end of *installer* setup.exe (which you see above),
decompress it to a temporary directory, and then run an executable inside the
temporary directory.

To make keep things confusing, the temporary executable that 7zip runs is
the member "setup.exe" (the *packager* setup.exe) found in the .7z root directory.

Since the *installer* `unsigned-NAME-VER.exe` will decompress the .7z archive and
run the *packager entry* `setup.exe` it found in the .7z root directory, we expect to
see "Salut" printed. Which is what we see:
[setup_exe_run]
  $ target/unsigned-full-name-windows_x86_64-0.1.0.exe
  Salut
[setup_exe_run]

To recap:
1. Opam directory structure is used to build a directory structure for the
archive tree.
2. You can create .tar.gz or .tar.bz2 binary distributions from the archive
tree.
3. You can also use the *installer* unsigned-NAME-VER.exe which has been designed to
automatically run the *packager entry* setup.exe.

Whether manually uncompressing a .tar.gz binary distribution, or letting
the *installer* `unsigned-NAME-VER.exe` do it automatically, the *packager entry*
`setup.exe` will have full access to the archive tree.

That's it for how archives and setup.exe work!

--------------------------------------------------------------------------------

TODO: Use another cram test to show what a the real `bin\dkml-package-setup.bc`
does, using one or more real component. Perhaps place the cram test in
dkml-installer-network-ocaml (or a demonstration Opam package that depends on
dkml-installer-network-ocaml).
