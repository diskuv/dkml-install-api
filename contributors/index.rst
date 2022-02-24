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

**Why use it?**

Often you start with the most basic installation logic: copy a directory of
prebuilt binaries and other files into the installation directory.
Later you realize you need to create a configuration file, populate a
database or compile assets at installation time. Now you have several options:

1. You generate the configuration/database/assets when your
   program is first run. You made a trade-off: instead of notifying your user
   of problems early, they don't find out until the program is run for the first
   time. Sometimes that is a perfectly acceptable trade-off.
2. You follow your target platform's recommendation; for example the
   `Fedora Linux Packaging Guidelines <https://docs.fedoraproject.org/en-US/packaging-guidelines/#_scripting_inside_of_specfiles>`_
   suggest using the Lua interpreter embedded in the Fedora/RedHat ``rpm`` package
   manager for any scripting needs. For other target platforms like Windows
   and non-RedHat based package managers, you modify your installer to first
   install the Lua interpreter. You made a trade-off:
   you need to write some of your core logic in a language (Lua) which is
   likely a language unfamiliar to you or your OCaml application developers,
   and at some point you may need to rewrite or duplicate some of your existing
   OCaml logic in Lua.
3. You follow the widespread practice of using portable scripts. On Unix systems
   you write POSIX shell scripts that run with the Bourne shell available on
   almost all Unix machines. On Windows system you write PowerShell scripts
   which can become the basis for Windows package managers like
   `Chocolatey <https://docs.chocolatey.org/en-us/create/create-packages>`_.

By now you can see that you can rapidly accumulate technical debt because your
installation logic gets complex quicker than you expected. The original
author of the DKML Install API followed option #3 when developing a
Windows-friendly installer for OCaml. The installer worked well but other
developers would have difficulty contributing to
`its Unix and Windows portable scripts <https://gitlab.com/diskuv/diskuv-ocaml/-/tree/v0.3.3/installtime>`_.

As OCaml application developers, you already know how to embed complex
logic in OCaml. With the DKML Install API you:

* inform your users of setup problems early during installation rather than
  at runtime (tradeoff for option #1)
* gain the ability to write your installation logic in a language you are
  already familiar with (tradeoff for option #2 and #3)
* gain the ability to test units of your installation logic with
  your normal OCaml test infrastructure (Alcotest, ppx_expect, etc.)

but you will need to accept a learning curve for:

* how to use this DKML Install API
* how to write Opam packages that install artifacts to non-standard locations
* how to use OCaml libraries like `Daniel Bünzli's Bos library <https://erratique.ch/software/bos>`_
  for cross-platform portable file and directory handling and
  `Craig Ferguson's Progress library <https://github.com/CraigFe/progress#readme>`_
  for showing progress bars

.. toctree::
   :maxdepth: 2
   :caption: Table of Contents

   self
   doc/components/index
   doc/Design

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
