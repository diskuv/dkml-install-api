(**

{2 Component Configuration}

You are responsible for creating a module of type {!Component_config}
to describe your component. A do-nothing implementation for most of the module
is available as {!Default_component_config}.

dkml_install_api will use the {!Component_config} to create four (4) command
line applications that will be wrapped into a single executable binary
["dkml-install-runner.exe"]. Each application is responsible for one of:
+ User installation
+ User uninstallation
+ Administrator installation
+ Administrator uninstallation

The four (4) command line applications have limited access to the OCaml runtime.
The expectation is that all installation logic is embedded in bytecode executables
which have the complete set of package dependencies you need to run your logic.
You will see in the later Context Objects section how to run these bytecode
executables.

Each of the command line applications are "subcommands" in the language of the
OCaml {!Cmdliner} package. You will not need to understand Cmdliner to define
your own component, although you may visit the
{{:https://erratique.ch/software/cmdliner} Cmdliner documentation} if you
want more information.

A [~ctx_t] Cmdliner term will be given by the
{!Component_config.install_user_subcommand} and the three (3) other subcommands.

Evaluating [~ctx_t] leads to the context record {!Context.t}.
*)

(** [Context] is a module providing a record type for the context. *)
module Context : sig
  include module type of Types.Context [@@inline]
end

include Dkml_install_api_intf.Intf [@@inline]
