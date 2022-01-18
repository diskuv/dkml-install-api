# Contributors

> This is a placeholder for now.

## Prerequisities

### Windows: Diskuv OCaml

Make sure you have installed Diskuv OCaml.

### Python / Conda

Our instructions assume you have installed Sphinx using [Anaconda](https://www.anaconda.com/products/individual)
or [Miniconda](https://docs.conda.io/en/latest/miniconda.html). Anaconda and Miniconda
are available for Windows, macOS or Linux.

Install a local Conda environment with the following:

```bash
cd contributors/ # if you are not already in this directory
conda env create -p envs -f environment.yml
```

## Building Documentation

On Linux or macOS you can run:

```bash
cd contributors/ # if you are not already in this directory
conda activate ./envs
make html
```

and on Windows you can run:

```powershell
cd contributors/ # if you are not already in this directory
conda activate ./envs
with-dkml make html
explorer .\_build\html\index.html
```

## Release Lifecycle

Start the new release with `release-start-patch`, `release-start-minor`
or `release-start-major`:

```powershell
with-dkml make release-start-minor
```

> Remove the `with-dkml` if you are running `make` on Unix.

Commit anything that needs changing or fixing, and document your changes/fixes in
the `contributors/changes/vMAJOR.MINOR.PATCH.md` file the previous command created
for you. Do not change the placeholder `@@YYYYMMDD@@` in it though.

When you think you are done, you need to test. Publish a prerelease:

```powershell
with-dkml make release-prerelease
```

Test it, and repeat until all problems are fixed.

Finally, after you have *at least one* prerelease:

```powershell
with-dkml make release-complete
```

## Rapid Development

In Visual Studio Code the following is a good template for your
``.vscode/settings.json`` file:

```json
{
    "restructuredtext.confPath": "${workspaceFolder}/contributors",
    "python.pythonPath": "${workspaceFolder}/contributors/envs"
}
```

You may have more rapid development if you continually run the tests and the
documentation; run the following in a background terminal in Windows PowerShell:

```powershell
with-dkml sh -c 'X=$(cygpath -au "$DiskuvOCamlHome"); PATH="$X/tools/apps:$PATH"; while true; do ALCOTEST_VERBOSE=1 dune build @runtest @doc --watch;  done'
```

or in Unix:

```bash
ALCOTEST_VERBOSE=1 dune build @runtest @doc --watch
```

## Writing Code

The guidelines are:

* Use Result.Error and Result.Ok rather than throwing exceptions
* Any error messages should start with a 8-character random identifier
  from `uuidgen | cut -c1-8`. Example: `[8b756634] Something happened`.
  This makes unit testing easy (just search for the error code) and
  errors are easy to track back at runtime.
