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
  uninstaller_print_bye.exe
  uninstaller_print_bye.ml
[initial_conditions_checkdir]

--------------------------------------------------------------------------------
Generating the installer starts with an Opam switch
--------------------------------------------------------------------------------

We'll just mimic an Opam switch by creating a directory structure and some
files.

We want to model an Opam "installer" package that has two components:
* dkml-component-offline-test-a
* dkml-component-offline-test-b

The files will just be empty files.

[opam_switch_mimic]
  $ install -d _opam/bin
  $ install -d _opam/lib/dkml-component-offline-test-a
  $ install -d _opam/lib/dkml-component-offline-test-b
  $ install -d _opam/lib/dkml-component-staging-ocamlrun
  $ install -d _opam/share/dkml-component-offline-test-a/static-files
  $ install -d _opam/share/dkml-component-offline-test-b/staging-files/generic
  $ install -d _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/bin
  $ install -d _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/lib/ocaml/stublibs
  $ install -d _opam/share/dkml-component-offline-test-b/staging-files/darwin_arm64
  $ install -d _opam/share/dkml-component-offline-test-b/staging-files/darwin_x86_64
  $ diskuvbox touch _opam/bin/example-admin-runner.exe
  $ diskuvbox touch _opam/bin/example-user-runner.exe
  $ diskuvbox touch _opam/share/dkml-component-offline-test-a/static-files/README.txt
  $ diskuvbox touch _opam/share/dkml-component-offline-test-a/static-files/icon.png
  $ diskuvbox touch _opam/share/dkml-component-offline-test-b/staging-files/generic/somecode-offline-test-b.bc
  $ diskuvbox touch _opam/share/dkml-component-offline-test-b/staging-files/darwin_arm64/libpng.dylib
  $ diskuvbox touch _opam/share/dkml-component-offline-test-b/staging-files/darwin_x86_64/libpng.dylib
  $ diskuvbox touch _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/bin/ocamlrun.exe
  $ diskuvbox touch _opam/share/dkml-component-staging-ocamlrun/staging-files/windows_x86_64/lib/ocaml/stublibs/dllthreads.dll
  $ diskuvbox tree --encoding UTF-8 -d 5 _opam
  _opam
  ├── bin/
  │   ├── example-admin-runner.exe
  │   └── example-user-runner.exe
  ├── lib/
  │   ├── dkml-component-offline-test-a/
  │   ├── dkml-component-offline-test-b/
  │   └── dkml-component-staging-ocamlrun/
  └── share/
      ├── dkml-component-offline-test-a/
      │   └── static-files/
      │       ├── README.txt
      │       └── icon.png
      ├── dkml-component-offline-test-b/
      │   └── staging-files/
      │       ├── darwin_arm64/
      │       │   └── libpng.dylib
      │       ├── darwin_x86_64/
      │       │   └── libpng.dylib
      │       └── generic/
      │           └── somecode-offline-test-b.bc
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
* `offline-test-a`
* `offline-test-b`

and we will also use a library to generate an executable
called `create_installers.exe`:

[what_are_components]
  $ cat test_windows_create_installers.ml
  module Term = Cmdliner.Term
  
  (* Create some demonstration components that are immediately registered *)
  
  let () =
    let reg = Dkml_install_register.Component_registry.get () in
    Dkml_install_register.Component_registry.add_component ~raise_on_error:true
      reg
      (module struct
        include Dkml_install_api.Default_component_config
  
        let component_name = "offline-test-a"
  
        (* During installation test-a needs ocamlrun.exe. staging-ocamlrun
           is a pre-existing component that gives you ocamlrun.exe. *)
        let install_depends_on = [ "staging-ocamlrun" ]
  
        (* During uninstallation test-a doesn't need ocamlrun.exe.
  
           Often uninstallers just need to delete a directory and other
           small tasks that can be done directly using the install API
           and/or the install API's standard libraries (ex. Bos).
  
           Currently the console installer and console uninstaller always force a
           dependency on staging-ocamlrun; this may change and other types of
           uninstallers may not have the same behavior.
        *)
        let uninstall_depends_on = []
      end);
    Dkml_install_register.Component_registry.add_component ~raise_on_error:true
      reg
      (module struct
        include Dkml_install_api.Default_component_config
  
        let component_name = "offline-test-b"
  
        (* During installation test-b needs test-a *)
        let install_depends_on = [ "staging-ocamlrun"; "offline-test-a" ]
        let uninstall_depends_on = []
      end)
  
  (* Let's also create an entry point for `create_installers.exe` *)
  let () =
    exit
      (Dkml_package_console_create.create_installers
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
         }
         {
           url_info_about_opt = None;
           url_update_info_opt = None;
           help_link_opt = None;
           estimated_byte_size_opt = None;
           windows_language_code_id_opt = None;
           embeds_32bit_uninstaller = true;
           embeds_64bit_uninstaller = true;
         })
[what_are_components]

You can see a real "curl" component at
https://github.com/diskuv/dkml-component-curl/tree/40a6484a3fe3636d02b3c1ead41ad8c6d97dc449

In particular:

* ``dkml-component-staging-curl.opam`` will download a ``curl`` executable for
Windows and stage it for installation on the end-user machine.
* ``src/buildtime_installer/dkml_component_staging_curl.ml`` defines the
component. It tells DkML Install API that it needs to run code during
installation for Unix machines only.
* ``src/installtime_enduser/unix/unix_install.ml`` is code that runs on the
end-user machine during installation, if and only if it is Unix. It creates
a symlink in a well-known location pointing to whichever ``curl`` is found in
the PATH during installation.

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

Run the create_installers.exe executable that includes the offline-test-b
component.

Side note:
| If this were not a demonstration, you would be doing the same steps in your
| installer .opam file with something like:
|   [
|     "%{bin}%/dkml-install-create-installers.exe"
|     "--program-version"
|     version
|     "--component"
|     "offline-test-b"
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
  $ ./test_windows_create_installers.exe --program-version 0.1.0 --component=offline-test-b --opam-context=_opam/ --target-dir=target/ --work-dir=work/ --abi=linux_x86_64 --abi=windows_x86_64 --packager-install-exe ./entry_print_salut.exe --packager-uninstall-exe ./entry_print_salut.exe --packager-setup-bytecode ./setup_print_hello.exe --packager-uninstaller-bytecode ./uninstaller_print_bye.exe --runner-admin-exe ./runner_admin_print_hi.exe --runner-user-exe ./runner_user_print_zoo.exe --verbose
  test_windows_create_installers.exe: [INFO] Installers will be created that include the components:
                                             [offline-test-a; offline-test-b;
                                              staging-ocamlrun; xx-console]
  test_windows_create_installers.exe: [INFO] Uninstallers will be created that include the components:
                                             [offline-test-b; staging-ocamlrun;
                                              xx-console]
  test_windows_create_installers.exe: [INFO] Installers and uninstallers will be created for the ABIs:
                                             [generic; linux_x86_64;
                                              windows_x86_64]
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-full-name-generic-u.sh that can produce full-name-generic-u-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-full-name-generic-i.sh that can produce full-name-generic-i-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-full-name-linux_x86_64-u.sh that can produce full-name-linux_x86_64-u-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-full-name-linux_x86_64-i.sh that can produce full-name-linux_x86_64-i-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating target\unsigned-full-name-windows_x86_64-u-0.1.0.exe
  Parsing of manifest successful.
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-full-name-windows_x86_64-u.sh that can produce full-name-windows_x86_64-u-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Generating target\unsigned-full-name-windows_x86_64-i-0.1.0.exe
  Parsing of manifest successful.
  test_windows_create_installers.exe: [INFO] Generating script target\bundle-full-name-windows_x86_64-i.sh that can produce full-name-windows_x86_64-i-0.1.0.tar.gz (etc.) archives
  test_windows_create_installers.exe: [INFO] Installers and uninstallers created successfully.
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

Each archive tree also contains the packager executable (the setup and
uninstall bytecode) named "bin/dkml-package.bc".

The "bin/dkml-package-entry.exe" is the launcher for the installation or
uninstallation. The "bin/dkml-package-entry.exe" is not self-contained; it
requires an archive tree which we'll describe later.

The "bin/dkml-package-uninstall.exe" is a fully self-contained uninstaller.
For Windows it is the self-extracting, self-executing archive that will
delegate to "bin/dkml-package-entry.exe" after the archive is extracted
into a temporary archive tree.

[create_installers_work]
  $ diskuvbox tree --encoding UTF-8 -d 6 work
  work
  ├── a/
  │   ├── i/
  │   │   ├── generic/
  │   │   │   ├── sg/
  │   │   │   │   └── offline-test-b/
  │   │   │   │       └── generic/
  │   │   │   └── st/
  │   │   │       └── offline-test-a/
  │   │   │           ├── README.txt
  │   │   │           └── icon.png
  │   │   ├── linux_x86_64/
  │   │   │   ├── bin/
  │   │   │   │   ├── dkml-install-admin-runner.exe
  │   │   │   │   ├── dkml-install-user-runner.exe
  │   │   │   │   ├── dkml-package-entry.exe
  │   │   │   │   └── dkml-package.bc
  │   │   │   ├── sg/
  │   │   │   │   └── offline-test-b/
  │   │   │   │       └── generic/
  │   │   │   └── st/
  │   │   │       └── offline-test-a/
  │   │   │           ├── README.txt
  │   │   │           └── icon.png
  │   │   └── windows_x86_64/
  │   │       ├── bin/
  │   │       │   ├── dkml-install-admin-runner.exe
  │   │       │   ├── dkml-install-user-runner.exe
  │   │       │   ├── dkml-package-entry.exe
  │   │       │   ├── dkml-package-uninstall.exe
  │   │       │   └── dkml-package.bc
  │   │       ├── sg/
  │   │       │   ├── offline-test-b/
  │   │       │   │   └── generic/
  │   │       │   └── staging-ocamlrun/
  │   │       │       └── windows_x86_64/
  │   │       └── st/
  │   │           └── offline-test-a/
  │   │               ├── README.txt
  │   │               └── icon.png
  │   └── u/
  │       ├── generic/
  │       │   └── sg/
  │       │       └── offline-test-b/
  │       │           └── generic/
  │       ├── linux_x86_64/
  │       │   ├── bin/
  │       │   │   ├── dkml-install-admin-runner.exe
  │       │   │   ├── dkml-install-user-runner.exe
  │       │   │   ├── dkml-package-entry.exe
  │       │   │   └── dkml-package.bc
  │       │   └── sg/
  │       │       └── offline-test-b/
  │       │           └── generic/
  │       └── windows_x86_64/
  │           ├── bin/
  │           │   ├── dkml-install-admin-runner.exe
  │           │   ├── dkml-install-user-runner.exe
  │           │   ├── dkml-package-entry.exe
  │           │   └── dkml-package.bc
  │           └── sg/
  │               ├── offline-test-b/
  │               │   └── generic/
  │               └── staging-ocamlrun/
  │                   └── windows_x86_64/
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
  $ diskuvbox tree --encoding UTF-8 -d 6 work
  work
  ├── a/
  │   ├── i/
  │   │   ├── generic/
  │   │   │   ├── sg/
  │   │   │   │   └── offline-test-b/
  │   │   │   │       └── generic/
  │   │   │   └── st/
  │   │   │       └── offline-test-a/
  │   │   │           ├── README.txt
  │   │   │           └── icon.png
  │   │   ├── linux_x86_64/
  │   │   │   ├── bin/
  │   │   │   │   ├── dkml-install-admin-runner.exe
  │   │   │   │   ├── dkml-install-user-runner.exe
  │   │   │   │   ├── dkml-package-entry.exe
  │   │   │   │   └── dkml-package.bc
  │   │   │   ├── sg/
  │   │   │   │   └── offline-test-b/
  │   │   │   │       └── generic/
  │   │   │   └── st/
  │   │   │       └── offline-test-a/
  │   │   │           ├── README.txt
  │   │   │           └── icon.png
  │   │   └── windows_x86_64/
  │   │       ├── bin/
  │   │       │   ├── dkml-install-admin-runner.exe
  │   │       │   ├── dkml-install-user-runner.exe
  │   │       │   ├── dkml-package-entry.exe
  │   │       │   ├── dkml-package-uninstall.exe
  │   │       │   └── dkml-package.bc
  │   │       ├── sg/
  │   │       │   ├── offline-test-b/
  │   │       │   │   └── generic/
  │   │       │   └── staging-ocamlrun/
  │   │       │       └── windows_x86_64/
  │   │       └── st/
  │   │           └── offline-test-a/
  │   │               ├── README.txt
  │   │               └── icon.png
  │   └── u/
  │       ├── generic/
  │       │   └── sg/
  │       │       └── offline-test-b/
  │       │           └── generic/
  │       ├── linux_x86_64/
  │       │   ├── bin/
  │       │   │   ├── dkml-install-admin-runner.exe
  │       │   │   ├── dkml-install-user-runner.exe
  │       │   │   ├── dkml-package-entry.exe
  │       │   │   └── dkml-package.bc
  │       │   └── sg/
  │       │       └── offline-test-b/
  │       │           └── generic/
  │       └── windows_x86_64/
  │           ├── bin/
  │           │   ├── dkml-install-admin-runner.exe
  │           │   ├── dkml-install-user-runner.exe
  │           │   ├── dkml-package-entry.exe
  │           │   └── dkml-package.bc
  │           └── sg/
  │               ├── offline-test-b/
  │               │   └── generic/
  │               └── staging-ocamlrun/
  │                   └── windows_x86_64/
  ├── setup.exe.manifest
  └── sfx/
      └── 7zr.exe

  $ diskuvbox tree --encoding UTF-8 -d 2 target
  target
  ├── bundle-full-name-generic-i.sh
  ├── bundle-full-name-generic-u.sh
  ├── bundle-full-name-linux_x86_64-i.sh
  ├── bundle-full-name-linux_x86_64-u.sh
  ├── bundle-full-name-windows_x86_64-i.sh
  ├── bundle-full-name-windows_x86_64-u.sh
  ├── full-name-windows_x86_64-i-0.1.0.7z
  ├── full-name-windows_x86_64-i-0.1.0.sfx
  ├── full-name-windows_x86_64-u-0.1.0.7z
  ├── full-name-windows_x86_64-u-0.1.0.sfx
  ├── unsigned-full-name-windows_x86_64-i-0.1.0.exe
  └── unsigned-full-name-windows_x86_64-u-0.1.0.exe

  $ target/bundle-full-name-linux_x86_64-i.sh -o target/i tar
  $ tar tvf target/i/full-name-linux_x86_64-i-0.1.0.tar | head -n5 | awk '{print $NF}' | sort
  ./
  full-name-linux_x86_64-i-0.1.0/.archivetree
  full-name-linux_x86_64-i-0.1.0/bin/
  full-name-linux_x86_64-i-0.1.0/bin/dkml-install-admin-runner.exe
  full-name-linux_x86_64-i-0.1.0/bin/dkml-install-user-runner.exe

  $ target/bundle-full-name-linux_x86_64-i.sh -o target/i -e .tar.gz tar --gzip
  $ tar tvfz target/i/full-name-linux_x86_64-i-0.1.0.tar.gz | tail -n5 | awk '{print $NF}' | sort
  full-name-linux_x86_64-i-0.1.0/sg/offline-test-b/generic/somecode-offline-test-b.bc
  full-name-linux_x86_64-i-0.1.0/st/
  full-name-linux_x86_64-i-0.1.0/st/offline-test-a/
  full-name-linux_x86_64-i-0.1.0/st/offline-test-a/README.txt
  full-name-linux_x86_64-i-0.1.0/st/offline-test-a/icon.png
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
  $ ../assets/lzma2107/bin/7zr.exe l target/full-name-windows_x86_64-i-0.1.0.7z | awk '$1=="Date"{mode=1} mode==1{print $NF}'
  Name
  ------------------------
  bin
  sg
  sg\offline-test-b
  sg\offline-test-b\generic
  sg\staging-ocamlrun
  sg\staging-ocamlrun\windows_x86_64
  sg\staging-ocamlrun\windows_x86_64\bin
  sg\staging-ocamlrun\windows_x86_64\lib
  sg\staging-ocamlrun\windows_x86_64\lib\ocaml
  sg\staging-ocamlrun\windows_x86_64\lib\ocaml\stublibs
  st
  st\offline-test-a
  .archivetree
  sg\offline-test-b\generic\somecode-offline-test-b.bc
  sg\staging-ocamlrun\windows_x86_64\bin\ocamlrun.exe
  sg\staging-ocamlrun\windows_x86_64\lib\ocaml\stublibs\dllthreads.dll
  st\offline-test-a\icon.png
  st\offline-test-a\README.txt
  bin\dkml-package.bc
  bin\dkml-install-admin-runner.exe
  bin\dkml-install-user-runner.exe
  setup.exe
  bin\dkml-package-uninstall.exe
  vcruntime140.dll
  vcruntime140_1.dll
  vc_redist.dkml-target-abi.exe
  ------------------------
  folders

  $ ../assets/lzma2107/bin/7zr.exe l target/full-name-windows_x86_64-u-0.1.0.7z | awk '$1=="Date"{mode=1} mode==1{print $NF}'
  Name
  ------------------------
  bin
  sg
  sg\offline-test-b
  sg\offline-test-b\generic
  sg\staging-ocamlrun
  sg\staging-ocamlrun\windows_x86_64
  sg\staging-ocamlrun\windows_x86_64\bin
  sg\staging-ocamlrun\windows_x86_64\lib
  sg\staging-ocamlrun\windows_x86_64\lib\ocaml
  sg\staging-ocamlrun\windows_x86_64\lib\ocaml\stublibs
  .archivetree
  sg\offline-test-b\generic\somecode-offline-test-b.bc
  sg\staging-ocamlrun\windows_x86_64\bin\ocamlrun.exe
  sg\staging-ocamlrun\windows_x86_64\lib\ocaml\stublibs\dllthreads.dll
  bin\dkml-package.bc
  bin\dkml-install-admin-runner.exe
  bin\dkml-install-user-runner.exe
  uninstall.exe
  vcruntime140.dll
  vcruntime140_1.dll
  vc_redist.dkml-target-abi.exe
  ------------------------
  folders
[setup_exe_list_7z]

We would see the same thing if we looked inside the *installer*
`unsigned-NAME-VER.exe` (which is just the SFX module and the .7z archive above):

[setup_exe_list_exe]
  $ ../assets/lzma2107/bin/7zr.exe l target/unsigned-full-name-windows_x86_64-i-0.1.0.exe | awk '$1=="Date"{mode=1} mode==1{print $NF}' | head -n10
  Name
  ------------------------
  bin
  sg
  sg\offline-test-b
  sg\offline-test-b\generic
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
  $ target/unsigned-full-name-windows_x86_64-i-0.1.0.exe
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
