.. _WritingComponents:

Writing Components
==================

Introduction
------------

You first decision will be how to break your installation into one or more
components.

A component is an optional set of logic in the form of bytecode executables,
and an optional set of "staging" files used by the bytecode logic, and an
optional set of "static" files that will be installed as-is on the end-user
machine.

Each "feature" component should deliver a single set of functionality
to the end-user. Your decision is simple: each feature component should
correspond to one "feature" selectable by the end-user at installation time.
If, for example, you are creating an installer for a text editor, then you
could have one feature be the text editor, while you have multiple features for
the multiple language packs your editor supports.

Each "support" component should deliver a single set of functionality that is
shared between components. For example, almost all components will need the
the [ocamlrun] support component so each feature component can run their
bytecode executables.

Every installation uses a ``dkml-install-runner.exe`` executable customized
to an installer. The component you write will be linked into
``dkml-install-runner.exe`` at installation time.

A properly configured component is an opam package that has:
* A required :ref:`ConfigurationModule` which configures values and methods
used in the installation lifecycle and in the installer generators.
* A :ref:`META` file with required fields
* optional :ref:`StagingFiles`
* optional :ref:`StaticFiles`

For example, when the following :ref:`ConfigurationModule` values are defined:

.. code:: ocaml

    module Term = Cmdliner.Term

    let component_name = "something"

    let execute_install ctx =
        Format.printf
          "Here is where we would install using bytecode run with: %s@\n"
          (ctx.path_eval "%{ocamlrun:share-abi}/bin/ocamlrun")

    let install_user_subcommand ~component_name ~subcommand_name =
        let doc = "Install a component called " ^ component_name in
        let cmd =
            ( Term.(const execute_install $ ctx_t), Term.info subcommand_name ~doc )
        in
        Ok cmd

the ``dkml-install-runner.exe`` executable will be generated so that
the following can occur:

.. code:: console

    $ dkml-install-runner.exe something
    Installing ... okay, it is done!

    $ dkml-install-runner.exe --help

If a component has :ref:`StagingFiles` they will be available during
installation (but not after).

If a component has :ref:`StaticFiles` they will be installed directly to the
final end-user installation folder.

As a component author you will need to write a :ref:`ConfigurationModule`
with methods like ``install_user_subcommand`` that will ``execute`` at
installation time. 

Copy Scenario
    You may want to simply copy some files from your component's build directories
    into your end-user's installation folder without modification.

    In your ``dune`` file you would use:

    .. code:: lisp

        (install (TODO StaticFiles))

    Your ``execute`` should do nothing (ex. ``let execute () = () in``).

Transform Scenario
    You may want to copy *and transform* files from your component's build
    directories into your end-user's installation folder. For example, you
    may want to replace all ``@@INSTALL_PLACEHOLDER_EXAMPLE@@`` placeholders
    in all files with the end-user installation directory.

    In your ``dune`` files you would copy the original files into staging:

    .. code:: lisp

        (install (TODO StagingFiles))

    Then in your ``execute`` you would use the ``bos`` package to copy
    from staging into static with something like the following:

    .. code:: ocaml

        let execute () = (* TODO copy from staging to static *)
        in

Compute Scenario
    You may want to compute or generate files into your end-user's installation
    folder. For example, you may want to compile a native code binary at
    installation time and place it in your end-users' installation folder.

    In your ``dune`` files you would copy the raw materials (if any) into
    staging, and generate a bytecode executable that can do the computations.
    For compilation the raw materials are the source code you will compile on
    the end-user's machine, and the bytecode executable will invoke the
    compiler on the end-user's machine.

    .. code:: lisp

        (executable (TODO bytecode))
        (install (TODO StagingFiles))

    Then in your ``execute`` you would use the ``dkml-component-ocamlrun-api``
    package to invoke your bytecode executable:

    .. code:: ocaml

        let execute () = (* TODO invoke ocamlrun using api *)
        in

    You would also add a dependency in your ``.opam`` file to include
    ``dkml-component-ocamlrun``.

    .. important::
        Most of the heavy work should be done in your bytecode executables.

        You may think that you can run OCaml code directly in your configuration
        functions like ``install_user_subcommand``, but configuration functions
        have only limited access to external OCaml libraries. See
        :ref:`ConfigurationModule` for more details.

.. _ConfigurationModule:

Configuration Module
--------------------

Configuration functions can only access:
* the OCaml Stdlib
* the other conventional OCaml libraries like ``unix``, ``str`` and ``bigarray``
* the ``dkml-install-api`` package
* the ``bos`` (Basic Operating System) package, version ``0.2.1``

Any call to a library outside of the above list will result in a
``Dynlink.Unavailable_unit`` error. Instead just generate a bytecode executable
and place it in the :ref:`StagingFiles`. You will be able to use Dune to
bundle as many libraries as you need into the single bytecode executable file.
You also have no restrictions on what versions of the libraries you bundle.

You can have :ref:`StandardComponents` available to you in the USER_INSTALL
phase so you can run any bytecode executables you have placed in
``<share>/staging-files/``, or compile new native executables on the end-users
machine. Just declare a dependency on them using the instructions in their
documentation.

.. _META:

META
----

Dune and other OCaml build tools automatically create ``META`` files that get
installed during ``opam install``. DkML Install API needs three (3) fields
that can be seen at the bottom of the following ``META`` file:

.. code-block:: text

  version = "2.0.2"
  description = ""
  requires =
  "bos
   dkml-component-common-desktop
   dkml-component-staging-ocamlrun.api
   dkml-install.register
   logs"
  archive(byte) = "dkml_component_offline_desktop_full.cma"
  archive(native) = "dkml_component_offline_desktop_full.cmxa"
  plugin(byte) = "dkml_component_offline_desktop_full.cma"
  plugin(native) = "dkml_component_offline_desktop_full.cmxs"
  dkml_install = "component"
  install_depends_on = "staging-ocamlrun staging-desktop-full staging-withdkml"
  uninstall_depends_on = "staging-ocamlrun"

The ``dkml_install`` field must be ``component``.

The ``install_depends_on`` and ``uninstall_depends_on`` field must duplicate
the same fields in the :ref:`ConfigurationModule`. The duplication is technical
debt.

See https://dune.readthedocs.io/en/stable/reference/findlib.html#how-dune-generates-meta-files
for how to add these three (3) fields to your Dune project.

.. _StagingFiles:

Staging Files
-------------

As a Component author you should
**only create bytecode executables with no C stubs**
in your OPAM_BUILD phase.

Bytecode executables ensure portability, and not depending on C stubs ensures
that the end-user's machine does not need specific versions of
specific shared libraries pre-installed.

On Windows and Linux you should build bytecode executables built from a 32-bit
OCaml compiler. 32-bit bytecode works on 64-bit machines, but not all
64-bit bytecode will work on 32-bit machines.

The structure of the staging files directory is:

.. code:: text

    staging-files/

        generic/ - Files that will be bundled in all installers

        windows_x86/ - Files that will
            be bundled in all Windows 32-bit installers.

        windows_x86_64/ - Files that will
            be bundled in all Windows 64-bit installers.

The goal is simplicity even though it will lead to duplication. For example the
Windows ``curl.exe`` binary is available from its official download site as a
``PE32 executable (console) Intel 80386 (stripped to external PDB), for MS Windows``
executable, as reported by the Unix/MSYS2/Cygwin tool ``/usr/bin/file``.
That is, it works on any 32-bit or 64-bit Windows machines. So a copy of the
32-bit ``curl.exe`` would be in both ``windows_x86/`` and ``windows_x86_64/``.

A common way to populate the Staging Files is to use Opam. Using the same
``curl.exe`` example, the following ``dkml-component-staging-curl.opam`` snippet
demonstrates how ``curl.exe`` and all its native files (DLLs) can be placed in
the appropriate Staging Files folders:

.. code:: ocaml

    install: [
        ["install" "-d"
            "%{_:share}%/staging-files/windows_x86/bin"
            "%{_:share}%/staging-files/windows_x86_64/bin"]
        [
            "unzip"
            "-o"
            "-d"
            "%{_:share}%/staging-files"
            "curl-7.81.0_1-win32-mingw.zip"
            "curl-7.81.0-win32-mingw/bin/curl.exe"
            "curl-7.81.0-win32-mingw/bin/curl-ca-bundle.crt"
            "curl-7.81.0-win32-mingw/bin/libcurl.def"
            "curl-7.81.0-win32-mingw/bin/libcurl.dll"
        ]
        [
            "sh"
            "-euc"
            """
            install \\
                '%{_:share}%'/staging-files/curl-7.81.0-win32-mingw/bin/* \\
                '%{_:share}%'/staging-files/windows_x86/bin/
            install \\
                '%{_:share}%'/staging-files/curl-7.81.0-win32-mingw/bin/* \\
                '%{_:share}%'/staging-files/windows_x86_64/bin/
            rm -rf '%{_:share}%'/staging-files/curl-7.81.0-win32-mingw
            """
        ]
    ]

    extra-source "curl-7.81.0_1-win32-mingw.zip" {
        src: "https://curl.se/windows/dl-7.81.0_1/curl-7.81.0_1-win32-mingw.zip"
        checksum: [
            "sha256=4e810ae4d8d1195d0ab06e8be97e5629561497f5de2f9a497867a5b02540b576"
        ]
    }

Since there are no Opam operating system selectors (ex. ``{os = "win32"}``), the
Windows staging-files/ directories are populated even if the build machine is
not Windows. In fact, using ``{os = "win32"}`` would have been incorrect:

.. code:: ocaml

    install: [
        ["install" "-d" "%{_:share}%/staging-files/windows/bin"] {os = "win32"}
    ...

The use of a Opam operating system selector like ``{os = "win32"}`` means
that Linux or macOS build machines cannot cross-compile to Windows. Instead,
have your build machines compile into as many architectures as it supports.

.. _StaticFiles:

Static Files
------------

Any static file will go straight into the end-user installation directory.

