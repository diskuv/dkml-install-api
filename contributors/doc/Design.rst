Design
======

Goals
-----

1. Re-use existing installation software when it is available.
2. Avoid lock-in to any existing installation software.
3. Use OCaml as much as possible.

Realizations
------------

We'll use an OCaml embedded DSL that closely follows the
`CPack <https://cmake.org/cmake/help/latest/module/CPack.html>`_ cross-platform
installer generator.
