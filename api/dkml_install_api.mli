(**

{2 Component Configuration}

You are responsible for creating a module of type {!Component_config}
to describe your component. A do-nothing implementation for most of the module
is available as {!Default_component_config}.

[Dkml_install_api] will use the {!Component_config} to create four (4) command
line applications.

Each of the command line applications are "subcommands" in the language of the
OCaml {!Cmdliner} package. You will not need to understand Cmdliner to define
your own component, although you may visit the
{{:https://erratique.ch/software/cmdliner} Cmdliner documentation} if you
want more information.

The four (4) command line applications have limited access to the OCaml runtime.
The expectation is that all installation logic is embedded in bytecode executables
which have the complete set of package dependencies you need to run your logic.
Through {!Component_config} [Dkml_install_api] will have given you a [~ctx_t]
Cmdliner term that, when evaluated, leads to the context record {!Context.t}.
The context record has the information needed to run your bytecode executables.

On Windows it is {{:https://docs.microsoft.com/en-us/windows/security/identity-protection/user-account-control/how-user-account-control-works} recommended security practice}
to separate functionality that requires administrative privileges from
functionality that does not require non-administrative privileges.
[Dkml_install_api] follows the same recommendations:
- There will be a {e single} executable ["dkml-install-admin-runner.exe"] that is
  responsible for the following functionality for {e all} components:
  + Administrator installation defined by {!Component_config.install_admin_subcommand}
  + Administrator uninstallation defined by {!Component_config.uninstall_admin_subcommand}
- There will be a {e single} executable ["dkml-install-user-runner.exe"] that is
  responsible for the following functionality for {e all} components:
  + User installation defined by {!Component_config.install_user_subcommand}
  + User uninstallation defined by {!Component_config.uninstall_user_subcommand}
*)

(** [Context] is a module providing a record type for the context. *)
module Context : sig
  include module type of Types.Context [@@inline]
end

include Dkml_install_api_intf.Intf [@@inline]
