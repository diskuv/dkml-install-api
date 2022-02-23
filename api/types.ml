module Context = struct
  type t = { path_eval : string -> Fpath.t; eval : string -> string }
  (** [t] is the record type for the context.

{1 Context Methods}

The following fields are available from the context today:

{ul
  {- [ctx.path_eval "/some/path/expression"]

  Evaluates the given path expression, resolving any templates embedded in the
  expression. You may use slashes ("/") even on Windows; the evaluation of the
  expression will convert the path into native Windows (ex. C:\Program Files)
  or Unix format (ex. /usr/local/share).

  An example expression is ["%{ocamlrun:share}/bin/ocamlrun.exe"]
  which would be the location of ocamlrun.exe within the staging files directory.

  Templates:

  - ["%{prefix}"] is the absolute path of the final installation directory. If you
  are following {{:https://www.gnu.org/prep/standards/html_node/Directory-Variables.html} GNU directory standards},
  you should populate ["%{prefix}"] with subdirectories "bin/", "share/", etc.
  - ["%{name}"] is the name of the component currently being installed
  - ["%{tmp}"] is the absolute path to a temporary directory unique to the
  component that is currently being installed. No other component will use the
  same temporary directory.
  - ["%{COMPONENT_NAME:share}"] is the absolute path within the staging directory
  of the named component. Usually the staging files include a bytecode
  executable to run a component's installation logic.

  Variations:

  - {b Staging Files}:    
    When dkml-install-runner.exe is run with the ["--staging-files DIR"] option
    then the staging directory is simply ["<DIR>/<COMPONENT_NAME>"]. During an
    end-user installation the ["--staging-files DIR"] option is automatically
    used.
    When dkml-install-runner.exe is run with the ["--opam-context"] option then
    the staging directory is
    ["$OPAM_SWITCH_PREFIX/share/dkml-component-<COMPONENT_NAME>/staging-files"]. You can use
    the ["--opam-context"] option to test your components in an Opam environment.
  }


  {- [ctx.eval "/some/expression"]

  Evaluates the given expression, resolving any templates embedded in the
  expression.

  An example expression is ["%{components:all}"].

  All templates that are available with [path_eval] are available with [eval].
  However unlike [path_eval] the [eval] function will do no path conversions on
  Windows. In addition [eval] has templates that are not available in
  [path_eval].

  Templates available to [eval] but not in [path_eval]:

  - ["%{components:all}"] is the space separated names of the components that are
  or will be installed
  }
}
*)
end