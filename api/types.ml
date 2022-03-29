module Context = struct
  (** ABI V2 is the version 2 of the supported list of ABIs *)
  module Abi_v2 = struct
    type t =
      | Android_arm64v8a
      | Android_arm32v7a
      | Android_x86
      | Android_x86_64
      | Darwin_arm64
      | Darwin_x86_64
      | Linux_arm64
      | Linux_arm32v6
      | Linux_arm32v7
      | Linux_x86_64
      | Linux_x86
      | Windows_x86_64
      | Windows_x86
      | Windows_arm64
      | Windows_arm32
    [@@deriving show, eq, ord]

    let of_string = function
      | "Android_arm64v8a" -> Result.ok Android_arm64v8a
      | "Android_arm32v7a" -> Result.ok Android_arm32v7a
      | "Android_x86" -> Result.ok Android_x86
      | "Android_x86_64" -> Result.ok Android_x86_64
      | "Darwin_arm64" -> Result.ok Darwin_arm64
      | "Darwin_x86_64" -> Result.ok Darwin_x86_64
      | "Linux_arm64" -> Result.ok Linux_arm64
      | "Linux_arm32v6" -> Result.ok Linux_arm32v6
      | "Linux_arm32v7" -> Result.ok Linux_arm32v7
      | "Linux_x86_64" -> Result.ok Linux_x86_64
      | "Linux_x86" -> Result.ok Linux_x86
      | "Windows_x86_64" -> Result.ok Windows_x86_64
      | "Windows_x86" -> Result.ok Windows_x86
      | "Windows_arm64" -> Result.ok Windows_arm64
      | "Windows_arm32" -> Result.ok Windows_arm32
      | s -> Result.error ("Unknown v2 ABI: " ^ s)

    (** [to_canonical_string abi] will give the canonical representation of
        the ABI to DKML tools and APIs. *)
    let to_canonical_string = function
      | Android_arm64v8a -> "android_arm64v8a"
      | Android_arm32v7a -> "android_arm32v7a"
      | Android_x86 -> "android_x86"
      | Android_x86_64 -> "android_x86_64"
      | Darwin_arm64 -> "darwin_arm64"
      | Darwin_x86_64 -> "darwin_x86_64"
      | Linux_arm64 -> "linux_arm64"
      | Linux_arm32v6 -> "linux_arm32v6"
      | Linux_arm32v7 -> "linux_arm32v7"
      | Linux_x86_64 -> "linux_x86_64"
      | Linux_x86 -> "linux_x86"
      | Windows_x86_64 -> "windows_x86_64"
      | Windows_x86 -> "windows_x86"
      | Windows_arm64 -> "windows_arm64"
      | Windows_arm32 -> "windows_arm32"
  end

  type t = {
    path_eval : string -> Fpath.t;
    eval : string -> string;
    host_abi_v2 : Abi_v2.t;
    log_config : Log_config.t;
  }
  (** [t] is the record type for the context.

{1 Context Fields}

The following fields are available from the context:

{ul
  {- [ctx.path_eval "/some/path/expression"]

  Evaluates the given path expression, resolving any templates embedded in the
  expression. You may use slashes ("/") even on Windows; the evaluation of the
  expression will convert the path into native Windows (ex. C:\Program Files)
  or Unix format (ex. /usr/local/share).

  An example expression is ["%{ocamlrun:share}/generic/bin/ocamlrun"]
  which would be the location of ocamlrun.exe within the staging files directory.

  Templates:

  - ["%{prefix}"] is the absolute path of the final installation directory. If you
  are following {{:https://www.gnu.org/prep/standards/html_node/Directory-Variables.html} GNU directory standards},
  you should populate ["%{prefix}"] with subdirectories "bin/", "share/", etc.
  - ["%{tmp}"] is the absolute path to a temporary directory unique to the
  component that is currently being installed. No other component will use the
  same temporary directory.
  - ["%{_:share}"] is the absolute path within the staging directory of the
  component currently being installed.

  More templates available to all [ctx] except [needs_admin ctx]:

  - ["%{COMPONENT_NAME:share}"] is the absolute path within
    the staging directory of the named component, respectively.
    Usually the staging files include a bytecode executable to run a component's
    installation logic.
    {e {b Only COMPONENT_NAMEs that are transitive dependencies
    of the currently-being-installed component will be resolved.}}

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

  - ["%{name}"] is the name of the component currently being installed
  - ["%{components:all}"] is the space separated names of the components that are
  or will be installed
  }

  {- [ctx.host_abi_v2]

  The ABI for the host machine from the list of V2 ABIs. You cannot rely on
  inspecting the OCaml bytecode interpreter since the interpreter is often
  compiled to 32-bit for maximum portability. When more host ABIs are
  supported they will go into a future [ctx.host_abi_v3] or later;
  for type-safety [ctx.host_abi_v2] will give a [Result.Error] for those
  new host ABIs.

  Values for the V2 ABI include:

  * Android_arm64v8a
  * Android_arm32v7a
  * Android_x86
  * Android_x86_64
  * Darwin_arm64
  * Darwin_x86_64
  * Linux_arm64
  * Linux_arm32v6
  * Linux_arm32v7
  * Linux_x86_64
  * Linux_x86
  * Windows_x86_64
  * Windows_x86
  }

  {- [ctx.log_config]
  
  The logging configuration. See the Logging section of {!Dkml_install_api}
  for how to use it.
  }
}
*)
end
