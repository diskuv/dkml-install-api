Getting Started with the DKML Install API
=========================================

The DKML Install API lets you take the tools you know (OCaml and Opam) and
well-known¹ installer generators, to generate a installer for your OCaml
project.

.. note::
   ¹ *Well-known* is an aspiration. Currently only a simple CLI installer
   generator is available, but other well-known installer generators like
   0install or cpack could be added in the future.

Specifically the DKML Install API lets you take a) pre-designed packages from
Opam and b) installation instructions written in OCaml source code, and
assembles binary artifacts that act as the primary materials to installer
generators.


.. toctree::
   :maxdepth: 2
   :caption: Table of Contents

   self
   doc/Design
   doc/StandardComponents

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
