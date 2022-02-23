.. _WritingComponents:

Writing Components
==================

Every installation uses a ``dkml-install-runner.exe`` executable customized
to an installer. The component you write will be linked into
``dkml-install-runner.exe`` at installation time.

A component has a :ref:`ConfigurationModule` that configures values and methods
used in the installation lifecycle and in the installer generators.

For example, when the following configuration values are defined:

.. code:: ocaml
    open Cmdliner

    let component_name = "something"

    let execute_install ctx =
        Format.printf
          "Here is where we would install using bytecode run with: %s@\n"
          (ctx#path_eval "%{ocamlrun:share}/bin/ocamlrun.exe")

    let install_user_subcommand ~component_name ~subcommand_name =
        let doc = "Install a component called " ^ component_name in
        let cmd =
            ( Term.(const execute_install $ ctx_t), Term.info subcommand_name ~doc )
        in
        Result.ok cmd

the ``dkml-install-runner.exe`` executable will be generated so that
the following can occur:

.. code:: session
    $ dkml-install-runner.exe something
    Installing ... okay, it is done!

    $ dkml-install-runner.exe --help

A component can also have :ref:`StagingFiles`
that will be available during installation (but not after), and can also have
:ref:`StaticFiles` that will be installed directly to the final end-user
installation folder.

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

.. _StagingFiles:

Staging Files
-------------

As a Component author you should **only create bytecode executables**
in your OPAM_BUILD phase. Build them with 32-bit compilers on Windows for
maximum portability.

.. _StaticFiles:

Static Files
------------

