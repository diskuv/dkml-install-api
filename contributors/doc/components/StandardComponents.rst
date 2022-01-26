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

ocamlcompiler
~~~~~~~~~~~~~

In the USER_INSTALL phase you can use the ``dkml-component-ocamlcompiler.opam``
provided ``ocamlopt.opt`` by doing the following:

1. Declare an Opam dependency on ``dkml-component-ocamlcompiler-api``
2. Declare a Dune ``(libraries ...)`` dependency on ``dkml-component-ocamlcompiler-api``
3. Declare a component ``let components = [...])`` dependency on
   ``dkml-component-ocamlcompiler``. *Do not declare the component dependency on the API!*
4. Use the XXX function (TODO: provide link to odoc documentation) which will handle
   all the details of spawning ocamlc on the **OCaml source code** you installed
   into ``<share>/work-files/``.
