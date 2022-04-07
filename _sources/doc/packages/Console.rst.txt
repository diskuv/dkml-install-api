Console Packager
================

The goal of this chapter is to demonstrate how archives are created, and
specifically how self-extracting archives work on Windows.

.. sidebar:: Source Code

    The `test_windows_create_installers.t <https://github.com/diskuv/dkml-install-api/blob/main/package/console/setup/test/test_windows_create_installers.t>`_
    CRAM test script is the source of code examples in this chapter.

--------------------------------------------------------------------------------
Initial Conditions
--------------------------------------------------------------------------------

Check what is present in the directory:

.. literalinclude:: ../../../package/console/setup/test/test_windows_create_installers.t
    :language: shell-session
    :start-after: [initial_conditions_checkdir]
    :end-before:  [initial_conditions_checkdir]

--------------------------------------------------------------------------------
Generating the installer starts with an Opam switch
--------------------------------------------------------------------------------

We'll just mimic an Opam switch by creating a directory structure and some
files.

We want to model an Opam "installer" package that has two components:
* dkml-component-staging-ocamlrun
* dkml-component-offline-test1

The files will just be empty files, except for two important files:
* dkml-install-setup.exe will print "Hello"
* dkml-install-uninstaller.exe will print "Bye"

If this were not a demonstration, we would let the dkml-install-api framework
generate those two files for us.

.. warning::

    dkml-install-setup.exe is implicitly native code produced by Dune.
    That means the build machine (the machine generating the Opam directory tree)
    must be the same ABI as the end-user machine (the machine where the installer
    runs). That is a sucky limitation!

    So ... we could either download prebuilt ABI-specific dkml-install-setup.exe
    and dkml-install-uninstaller.exe, or we could distribute those two files
    as OCaml bytecode.

.. literalinclude:: ../../../package/console/setup/test/test_windows_create_installers.t
    :language: shell-session
    :start-after: [opam_switch_mimic]
    :end-before:  [opam_switch_mimic]

--------------------------------------------------------------------------------
What are these components?
--------------------------------------------------------------------------------

In a typical graphical desktop installer, you are able to select which pieces of
an application are installed on your machine. For example, a Git installer
could ask whether you wanted to install the "Git LFS" extension for large
file support. These pieces of an application are called components.

For now, we'll define two do-nothing test components:
``staging-ocamlrun`` and ``offline-test1``

and we will also use a library to generate an executable
called ``create_installers.exe``:

.. literalinclude:: ../../../package/console/setup/test/test_windows_create_installers.t
    :language: ocaml
    :start-after: [what_are_components]
    :end-before:  [what_are_components]

If this were not a demonstration, all your components would be dynamically
probed from your Opam directory structure using the Dune Site plugin:
https://dune.readthedocs.io/en/latest/sites.html#plugins-and-dynamic-loading-of-packages

You can see a real component at:
https://github.com/diskuv/dkml-component-curl/blob/1cbecbaf7252e1fbe2ee5f56805fcf03e34fb4b6/src/buildtime_installer/dkml_component_staging_curl.ml

--------------------------------------------------------------------------------
Use the generated ``create_installers.exe``
--------------------------------------------------------------------------------

.. important::

    ``create_installers.exe`` will create installers for you based on the components
    you registered earlier.

Create the temporary work directory and the target installer directory:

.. literalinclude:: ../../../package/console/setup/test/test_windows_create_installers.t
    :language: shell-session
    :start-after: [create_installers_dirs]
    :end-before:  [create_installers_dirs]

We'll directly run the create_installers.exe executable. But if this were not a
demonstration, you would be doing this in your installer .opam file with
something like:

.. code-block:: javascript

    [
        "%{bin}%/dkml-install-generate.exe"
        "--program-name"
        name
        "--program-version"
        version
        "--work-dir"
        "_build/iw"
        "--target-dir"
        "%{_:share}%"
    ]

Running the ``create_installers.exe`` gives:

.. literalinclude:: ../../../package/console/setup/test/test_windows_create_installers.t
    :language: shell-session
    :start-after: [create_installers_run]
    :end-before:  [create_installers_run]


The ``--work-dir`` will have ABI-specific archive trees in its "a" folder.

The archive tree is the content that is packed into the installer file
(ex. setup.exe, .msi, .rpm, etc.) and which gets unpacked on the
end-user's machine.

Each archive tree contains a "sg" folder for the staging files ... these
are files that are used during the installation but disappear when the
installation is finished.

Each archive tree also contains a "st" folder for the static files ... these
are files that are directly copied to the end-user's installation directory.

.. literalinclude:: ../../../package/console/setup/test/test_windows_create_installers.t
    :language: shell-session
    :start-after: [create_installers_work]
    :end-before:  [create_installers_work]

--------------------------------------------------------------------------------
Bring-your-own-archiver archives
--------------------------------------------------------------------------------

Currently there is only one "supported" archiver: tar.

You could use your own tar archiver so you can distribute software for
\*nix machines like Linux and macOS in the common .tar.gz or .tar.bz2 formats.

There could be others in the future:

* a zip archiver so you can use builtin zip file support on modern Windows
  machines. (But the setup.exe installers are probably better; see the next
  section)
* a RPM/APK/DEB packager on Linux

We create "bundle" scripts that let you generate 'tar' archives specific
to the target operating systems. You can add tar options like '--gzip'
to the end of the bundle script to customize the archive.

.. note::

    The reason we use scripts rather than create the archives directly is
    to lessen the OCaml dependencies of dkml-install-api. You usually can
    install or use an archiver (ex. tar.exe + gzip.exe) on a build system,
    which will be more performant, maintainable and customizable than doing
    tar (or RPM, etc.) inside of OCaml.

.. literalinclude:: ../../../package/console/setup/test/test_windows_create_installers.t
    :language: shell-session
    :start-after: [archiver_session]
    :end-before:  [archiver_session]

--------------------------------------------------------------------------------
setup.exe installers
--------------------------------------------------------------------------------

There are also fully built setup.exe installers available.
The setup.exe is just a special version of the decompressor 7z.exe called an
"SFX" module, with a 7zip archive appended.

Let's start with the 7zip archive that we generate.  You will see that its
contents is exactly the same as the archive tree, except that
``bin\dkml-install-setup.exe`` has been renamed to ``setup.exe``.

.. literalinclude:: ../../../package/console/setup/test/test_windows_create_installers.t
    :language: shell-session
    :start-after: [setup_exe_list_7z]
    :end-before:  [setup_exe_list_7z]

We would see the same thing if we looked inside the generated
``setup-NAME-VER.exe`` (which is just the SFX module and the .7z archive above):

.. literalinclude:: ../../../package/console/setup/test/test_windows_create_installers.t
    :language: shell-session
    :start-after: [setup_exe_list_exe]
    :end-before:  [setup_exe_list_exe]

When setup.exe is run, the SFX module knows how to find the 7zip archive stored
at the end of setup.exe (which you see above), decompress it to a temporary
directory, and then run an executable inside the temporary directory.

To make keep things confusing, the temporary executable that 7zip runs is
the member "setup.exe" found in the .7z root directory.

If we were to run the ``bin\dkml-install-setup.exe`` from the original archive
tree we would just get a "Hello" printed.

Here is the code for that:

.. literalinclude:: ../../../package/console/setup/test/test_windows_create_installers.t
    :language: ocaml
    :start-after: [setup_exe_setup_ml]
    :end-before:  [setup_exe_setup_ml]

Since the generated ``setup-NAME-VER.exe`` will decompress the .7z archive and run
the ``setup.exe`` it found in the .7z root directory, we expect to see "Hello"
printed. Which is what we see:

.. literalinclude:: ../../../package/console/setup/test/test_windows_create_installers.t
    :language: shell-session
    :start-after: [setup_exe_run]
    :end-before:  [setup_exe_run]

To recap:

1. Opam directory structure is used to build a directory structure for the
   archive tree.
2. You can create .tar.gz or .tar.bz2 binary distributions from the archive
   tree.
3. You can also use the setup-NAME-VER.exe which has been designed to
   automatically run ``bin\dkml-install-setup.exe``.

Whether manually uncompressing a .tar.gz binary distribution, or letting
setup-NAME-VER.exe do it automatically, the original
``bin\dkml-install-setup.exe`` will have full access to the archive tree.

That's it for how archives and setup.exe work!

Go through the remaining documentation to see what the real
``bin\dkml-install-setup.exe`` does, and what goes into a real component.
