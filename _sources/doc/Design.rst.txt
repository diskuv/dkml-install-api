Design
======

Goals
-----

1. Re-use existing installation software when it is available.
2. Avoid lock-in to any existing installation software.
3. Use OCaml as much as possible.

Terms
-----

Packaging
    The procedure for taking source code, doing some compiling and other
    translations, and ending up with an installable package (ex. setup.exe on
    Windows)

Component
    A logical piece of software that can be selected or deselected during
    installation. Components can depend on other components.

    Each component has a concrete instantation as an Opam package
    ``dkml-component-<COMPONENTNAME>``.

Installer
    A single-file executable (ex. ``setup.exe``) or a single-file installation
    bundle (ex. ``package-name.msi``, ``package-name.rpm``, etc.) that, when
    used by the end-user, will install all selected components.

    Each installer has a concreate instantation as an Opam package
    ``dkml-installer-<INSTALLERNAME>``.

Installer Generator
    A program that can create a customized installer that you can configure
    with your own installation instructions or an installation manifest.
    Examples include `0install`_ and `cpack`_.

Component API
    A collection of OCaml modules and module types that Component authors
    use to register their component.

Installer API
    A collection of OCaml modules and module types that that provide low-level
    boilerplate to create an installer for Installer authors.

Component OPAM_BUILD Phase
    When Opam runs the `build: [instructions ...] <https://opam.ocaml.org/doc/Manual.html#opamfield-build>`_
    for a component, we'll be calling that the OPAM_BUILD phase

Component OPAM_INSTALL Phase
    When Opam runs the `install: [instructions ...] <https://opam.ocaml.org/doc/Manual.html#opamfield-install>`_
    for a component, we'll be calling that the OPAM_INSTALL Phase

Packaging Flow
--------------

Creating the installer package
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The installer can be generated directly using:

.. code:: bash

    opam switch create installer-$INSTALLERNAME --empty
    opam install --switch installer-$INSTALLERNAME ./dkml-installer-$INSTALLERNAME.opam

The generated installer will be available in the Opam switch's
``$OPAM_SWITCH_PREFIX/share/$INSTALLERNAME/dist/`` folder.

.. note::
    There is an GitHub Actions workflow ``package`` that is run for
    ``dkml-installer-<INSTALLERNAME>``
    whenever a commit or a tag is pushed. It does the same
    ``opam switch create`` and ``opam install`` as above.

From now on we'll just say installer ``$INSTALLERNAME`` is ``I``.
Here is what the ``opam install ...`` step does in detail:

1.  Opam builds and install the Opam dependencies. Specifically Opam does the
    equivalent of:

    1. Each component ``C`` listed in ``I``'s ``dkml-installer-<INSTALLERNAME>.opam``
       dependencies will go through its OPAM_BUILD and OPAM_INSTALL phases using the
       instructions in ``C``'s ``dkml-component-<C>.opam``.

       A component may choose to expose an ``dkml-component-<C>-api.opam``
       if there are any OCaml types, constants and functions which
       need to be shared with the consumers of that component.

       The OPAM_INSTALL phase of ``dkml-component-<C>.opam`` is responsible for:

       * Placing files in ``<share>/static-files/`` where
         `<share> <https://opam.ocaml.org/doc/Manual.html#installfield-share>`_
         is ``<opamswitch>/share/dkml-component-<C>/``. These files will be used
         in the USER_DEPLOY_INITIAL phase.

       * Placing executables and files in ``<share>/staging-files/``. These
         files will be used in the USER_INSTALL phase

       .. important:: Relocatable requirements

           Anything inside ``<share>/static-files/`` and ``<share>/staging-files/``
           must be **relocatable**
           to a different location on the end-user's hard drive. As of January
           2022, many executables like ``ocamlc`` and ``ocamlbuild`` are *not*
           relocatable.

           Instead the only native executable should be
           ``ocamlrun`` (provided by ``dkml-component-ocamlrun.opam``).

2. **Merges** together the
   ``<share>/static-files/`` directories. It does the equivalent of
   the following for all components ``C``:

   .. code:: bash

       rsync -a $OPAM_SWITCH_PREFIX/share/$C/static-files/ \
            $OPAM_SWITCH_PREFIX/share/$I/static-files/

3. **Side-by-side copies** all the
   ``<share>/staging-files/`` directories. It does the equivalent of
   the following for all components ``C``:

   .. code:: bash

       rsync -a $OPAM_SWITCH_PREFIX/share/$C/staging-files/ \
            $OPAM_SWITCH_PREFIX/share/$I/staging-files/$C/

4. Create
   `dune_site plugin loader <https://dune.readthedocs.io/en/stable/sites.html#plugins-and-dynamic-loading-of-packages>`_-based executables named ``dkml-install-setup.exe``,
   ``dkml-install-user-runner.exe`` and
   ``dkml-install-admin-runner.exe`` that will perform the steps in
   :ref:`UserPhases`

5. The last step depends on what type of installer
   generator has been configured. *As of Jan 2022 only the CLI Archive
   installer generator is available, and no configuration is needed. But
   regardless of which installer generator is available, the Component packages
   should not change.*

   CLI Archive Installer Generator
        This installer will produce a ``$OPAM_SWITCH_PREFIX/share/$I/dist/$I.zip``
        file or a ``$OPAM_SWITCH_PREFIX/share/$I/dist/$I.tar.gz`` file.

        All of the ``$OPAM_SWITCH_PREFIX/share/$I/static-files/`` will go
        into the root of the ``$I.zip`` archive.

        All of the ``$OPAM_SWITCH_PREFIX/share/$I/staging-files/`` will go
        into the ``_staging`` top-level folder of the ``$I.zip`` archive.

        The ``dkml-install-user-runner.exe`` and
        ``dkml-install-admin-runner.exe``
        executables will be placed in the root of the
        ``$I.zip`` archive.

   Future Possibility: 0install
        If no component needs administrative permission then
        `0install`_ would be a good
        choice for a cross-platform installer.

   Future Possibility: cpack
        `cpack`_ would
        be a good choice for generating a variety of installers across many
        platforms (``.rpm``, ``.msi``, etc.), although it is much harder to
        configure than 0install.

.. _UserPhases:

User runs the installer
~~~~~~~~~~~~~~~~~~~~~~~

1. [``dkml-install-setup.exe``] Load all the components with
   `dune_site's <https://dune.readthedocs.io/en/stable/sites.html#plugins-and-dynamic-loading-of-packages>`_
   ``Sites.Plugins.Plugins.load_all ()``:

   * When a component (plugin) ``C`` is loaded, it will register itself
     with the ``dkml-install-api`` registry.
2. [``dkml-install-setup.exe``] After all the components are registered, the
   components are topologically sorted based on their dependencies.
3. [``dkml-install-setup.exe``] Ask end-user which components to install.
   Some components may have
   configuration that lets them display text (ex. license) or ask more
   questions.
4. [``dkml-install-setup.exe``] Formulate command line options for
   ``dkml-install-user-runner.exe`` and  ``dkml-install-admin-runner.exe``
   that correspond to the end-user selections. The same command line options
   will be used in both executables.

   .. note::

     This is a underspecified spot in the design. There needs to be a
     "selections" file created by the CLI Archive Installer or GUI installer
     to describe the end-user choices. And there needs to be some mapping
     from that "selections" file into command line options for
     ``dkml-install-user-runner.exe`` and  ``dkml-install-admin-runner.exe``.
     And each component should be able to influence how that selections file
     is created.

     Early versions of the installer will simply have no choices.

5. [``dkml-install-setup.exe``] Check if there are any components that
   needs administrative/root privileges. The check will be like:

   .. code:: ocaml

         Component.needs_admin "<end_user_installation_prefix>"

6. [``dkml-install-setup.exe``] **ADMIN_INSTALL phase** If there are any
   components that needs administrative/root privileges, then:

   1. [``dkml-install-setup.exe``] Copy the ``_staging`` folder into a
      temporary folder.

      .. note::
          We'll do this again in non-administrator mode. The design reason
          for doing it twice is that file permission conflicts won't be an
          issue, and
          because we want the User Account Control popup on Windows or
          sudo password prompt on Unix to be shown to the end-user as early
          as possible. We don't want the end-user to have to wait a minute
          for the staging files to be copied ... and only then get prompted
          for a password because they may have left their computer to finish
          the installation. The User Account Control popup only lasts a few
          minutes, and if the popup is not pressed the installation fails.
   2. [``dkml-install-setup.exe``] Spawn the ``dkml-install-admin-runner.exe``
      executable as an elevated Unix process:

      .. code:: bash

         sudo dkml-install-admin-runner

      or with a
      `Windows User Account Control Application Manifest <https://docs.microsoft.com/en-us/windows/security/identity-protection/user-account-control/how-user-account-control-works#request-execution-levels>`_.

      An alternative for Windows is to use PowerShell to ask for Administrative privileges:

      .. code:: powershell

         Start-Process powershell -ArgumentList '& dkml-install-admin-runner.exe' -verb RunAs

      The options given to ``dkml-install-admin-runner.exe`` were formulated
      in an earlier step, plus an extra option is added for the location of
      the staging folder.
   3. [``dkml-install-admin-runner.exe``] In topological order call each
      component:

      .. code:: ocaml

         Component.run_as_admin "<end_user_installation_prefix>"

7. [``dkml-install-setup.exe``] **USER_DEPLOY_INITIAL phase**: Copy
   everything from the archive to the
   <end_user_installation_prefix> except the ``_staging`` folder.
8. [``dkml-install-setup.exe``] **USER_INSTALL phase**:

   1. [``dkml-install-setup.exe``] Copy the ``_staging`` folder into a
      temporary folder
   2. [``dkml-install-setup.exe``] Spawn ``dkml-install-user-runner.exe``
      with the options formulated
      in an earlier step, plus an option for the location of the staging folder.
   3. [``dkml-install-user-runner.exe``] Copy the non-staging files (especially
      the static files) from the archive to the <end_user_installation_prefix>.
   4. [``dkml-install-user-runner.exe``] In topological order call each
      component like:

      .. code:: ocaml

          Component.run_as_user "<end_user_installation_prefix>"

.. _0install: https://opam.ocaml.org/packages/0install
.. _cpack: https://cmake.org/cmake/help/latest/module/CPack.html
