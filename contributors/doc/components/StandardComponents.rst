.. _StandardComponents:

Standard Components
-------------------

staging-ocamlrun
~~~~~~~~~~~~~~~~

In the USER_INSTALL phase you can use the ``dkml-component-ocamlrun.opam``
provided ``ocamlrun`` by doing the following:

1. (TODO) Declare an Opam dependency on ``dkml-component-ocamlrun-api``
2. (TODO) Declare a Dune ``(libraries ...)`` dependency on ``dkml-component-ocamlrun-api``
3. Declare a component ``let depends_on = [...])`` dependency on
   ``ocamlrun``. *Do not declare the component dependency on the API!*
4. Use the XXX function (TODO: provide link to odoc documentation) which will handle
   all the details of spawning ocamlrun on the **bytecode executable** you installed
   into ``<share>/work-files/``, especially the handling of the relocation of Stdlib.

enduser-ocamlcompiler
~~~~~~~~~~~~~~~~~~~~~

In the USER_INSTALL phase you can use the ``dkml-component-ocamlcompiler.opam``
provided ``ocamlopt.opt`` by doing the following:

1. (TODO) Declare an Opam dependency on ``dkml-component-ocamlcompiler-api``
2. (TODO) Declare a Dune ``(libraries ...)`` dependency on ``dkml-component-ocamlcompiler-api``
3. Declare a component ``let depends_on = [...])`` dependency on
   ``ocamlcompiler``. *Do not declare the component dependency on the API!*
4. Use the XXX function (TODO: provide link to odoc documentation) which will handle
   all the details of spawning ocamlc on the **OCaml source code** you installed
   into ``<share>/work-files/``.

staging-curl
~~~~~~~~~~~~

Full documentation is at
`staging-curl <https://github.com/diskuv/dkml-component-staging-curl>`.
Provides ``curl`` which will be available even on a Windows end-user machine:

``%{staging-curl:share}%/bin/curl``
   There is an Opam package `Curly <https://v3.ocaml.org/p/curly>`_ that
   will handle spawning ``curl`` or ``curl.exe`` for you.

   On Unix it is a symlink to the curl provided by the system since
   ``curl`` is installed on almost all Unix systems, including macOS.

   On Windows a standalone ``curl.exe`` is provided. Even though Windows 10
   Build 17063 bundles ``C:\Windows\System32\curl.exe``,
   for maximum portability it is better to use the curl provided by unixutils.


enduser-unixutils
~~~~~~~~~~~~~~~~~

Full documentation is at
`enduser-unixutils <https://github.com/diskuv/dkml-component-enduser-unixutils>`.
Provides the following Unix standard utilities; they work even on a
Windows end-user machine:

``%{prefix}%/tools/unixutils/bin/sh``
   A POSIX-compatible Bourne shell. On Windows this is provided by MSYS2
   which is a large and time-consuming installation. Prefer OCaml interpreted
   scripts which usually make more sense than using the Bourne shell.

All of the above utilities are available in the USER_INSTALL phase.
Use it in your project as follows:

1. (TODO) Declare a Dune ``(libraries ...)`` dependency on ``dkml-component-unixutils``
2. Declare a component ``let depends_on = [...])`` dependency on
   ``unixutils``.
3. Use the ``log_spawn_onerror_exit`` function
   (TODO: provide link to odoc documentation) which will handle
   all the details of spawning ocamlc on the **OCaml source code** you installed
   into ``<share>/work-files/``.

