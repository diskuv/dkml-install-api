Usage for Component Authors
===========================

As a Component author you should **only create bytecode executables**
in your OPAM_BUILD phase. Build them with 32-bit compilers on Windows for
maximum portability.

You can have :ref:`StandardComponents` available to you in the USER_INSTALL
phase so you can run any bytecode executables you have placed in
``<share>/staging-files/``, or compile new native executables on the end-users
machine. Just declare a dependency on them using the instructions in their
documentation.

.. _StandardComponents:

Standard Components
-------------------

ocamlrun
~~~~~~~~

In the USER_INSTALL phase you can use the ``dkml-component-ocamlrun.opam``
provided ``ocamlrun`` by doing the following:

1. Declare an Opam dependency on ``dkml-component-ocamlrun-api``
2. Declare a Dune ``(libraries ...)`` dependency on ``dkml-component-ocamlrun-api``
3. Declare a component ``let components = [...])`` dependency on
   ``dkml-component-ocamlrun``. *Do not declare the component dependency on the API!*
4. Use the XXX function (TODO: provide link to odoc documentation) which will handle
   all the details of spawning ocamlrun on the **bytecode executable** you installed
   into ``<share>/work-files/``, especially the handling of the relocation of Stdlib.

compiler
~~~~~~~~

In the USER_INSTALL phase you can use the ``dkml-component-compiler.opam``
provided ``ocamlopt.opt`` by doing the following:

1. Declare an Opam dependency on ``dkml-component-compiler-api``
2. Declare a Dune ``(libraries ...)`` dependency on ``dkml-component-compiler-api``
3. Declare a component ``let components = [...])`` dependency on
   ``dkml-component-compiler``. *Do not declare the component dependency on the API!*
4. Use the XXX function (TODO: provide link to odoc documentation) which will handle
   all the details of spawning ocamlc on the **OCaml source code** you installed
   into ``<share>/work-files/``.
