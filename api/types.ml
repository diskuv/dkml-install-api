(** Component configuration values that can be supplied with defaults *)
module type Component_config_defaultable = sig
  val depends_on : string list
  (** [depends_on] are the components, if any, that this component depends on.

      Dependencies will be installed in order and uninstalled in reverse
      order. *)

  val install_user_subcommand :
    component_name:string ->
    subcommand_name:string ->
    setup_t:unit Cmdliner.Term.t ->
    (unit Cmdliner.Term.t * Cmdliner.Term.info, string) Result.t
  (** [install_user_subcommand ~component_name ~subcommand_name ~setup_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will install the component with non-privileged
      user permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["install-user-" ^ component_name].

      [~setup_t]: Sets up logging and any other common options. You must include
      the setup term in your returned [Term.t * Term.info], as in:

      [[
        let execute_install () = () in
        Term.(const execute_install $ setup_t, Term.info component_name)
      ]]*)

  val uninstall_user_subcommand :
    component_name:string ->
    subcommand_name:string ->
    setup_t:unit Cmdliner.Term.t ->
    (unit Cmdliner.Term.t * Cmdliner.Term.info, string) Result.t
  (** [uninstall_user_subcommand ~component_name ~setup_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will uninstall the component with non-privileged
      user permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["uninstall-user-" ^ component_name].

      [~setup_t]: Sets up logging and any other common options. You must include
      the setup term in your returned [Term.t * Term.info], as in:

      [[
        let execute_uninstall () = () in
        Term.(const execute_uninstall $ setup_t, Term.info component_name)
      ]]*)

  val needs_install_admin : unit -> bool
  (** [needs_install_admin] should inspect the environment and say [true] if and only
      if the [install_admin_subcommand] is necessary *)

  val needs_uninstall_admin : unit -> bool
  (** [needs_uninstall_admin] should inspect the environment and say [true] if and only
      if the [install_admin_subcommand] is necessary *)

  val install_admin_subcommand :
    component_name:string ->
    subcommand_name:string ->
    setup_t:unit Cmdliner.Term.t ->
    (unit Cmdliner.Term.t * Cmdliner.Term.info, string) Result.t
  (** [install_admin_subcommand ~component_name ~subcommand_name ~setup_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will install the component with privileged
      administrator (`root` or `sudo` on Unix) permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["install-admin-" ^ component_name].

      [~setup_t]: Sets up logging and any other common options. You must include
      the setup term in your returned [Term.t * Term.info], as in:

      [[
        let execute_install () = () in
        Term.(const execute_install $ setup_t, Term.info component_name)
      ]]*)

  val uninstall_admin_subcommand :
    component_name:string ->
    subcommand_name:string ->
    setup_t:unit Cmdliner.Term.t ->
    (unit Cmdliner.Term.t * Cmdliner.Term.info, string) Result.t
  (** [uninstall_admin_subcommand ~component_name ~setup_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will uninstall the component with privileged
      administrator (`root` or `sudo` on Unix) permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["uninstall-" ^ component_name].

      [~setup_t]: Sets up logging and any other common options. You must include
      the setup term in your returned [Term.t * Term.info], as in:

      [[
        let execute_uninstall () = () in
        Term.(const execute_uninstall $ setup_t, Term.info component_name)
      ]]*)

  val test : unit -> unit
  (** [test ()] is reserved for unit testing; it should do nothing in
      real code *)
end

module type Component_config = sig
  include Component_config_defaultable

  val component_name : string
  (** [component_name] is the name of the component. It must be lowercase
      alphanumeric; dashes (-) are allowed. *)
end
