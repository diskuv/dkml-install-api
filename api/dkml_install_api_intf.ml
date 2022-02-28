module type Component_config_defaultable = sig
  val depends_on : string list
  (** [depends_on] are the components, if any, that this component depends on.

      Dependencies will be installed in order and uninstalled in reverse
      order. *)

  val install_user_subcommand :
    component_name:string ->
    subcommand_name:string ->
    ctx_t:Types.Context.t Cmdliner.Term.t ->
    (unit Cmdliner.Term.t * Cmdliner.Term.info, string) Result.t
  (** [install_user_subcommand ~component_name ~subcommand_name ~ctx_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will install the component with non-privileged
      user permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["install-user-" ^ component_name].

      [~ctx_t]: A Cmdliner term that sets up common options and delivers a
      context record. The common options include options for logging. The
      context record is described at {!Dkml_install_api}.

      You must include the [ctx_t] term in your returned [Term.t * Term.info],
      as in:

      {[
        let execute_install ctx =
          Format.printf
            "We can run bytecode using: %s@\n"
            (ctx.Dkml_install_api.Context.path_eval "%{ocamlrun:share}/bin/ocamlrun.exe")

        let install_user_subcommand ~component_name ~subcommand_name ~ctx_t =
          let doc = "Install the pieces that don't require Administrative rights" in
          Result.ok @@ Cmdliner.Term.(const execute_install $ ctx_t, info subcommand_name ~doc)
      ]}

      Your [Term.t] function ([install_user_subcommand ctx]) should raise
      {!Installation_error} for any terminal failures. *)

  val uninstall_user_subcommand :
    component_name:string ->
    subcommand_name:string ->
    ctx_t:Types.Context.t Cmdliner.Term.t ->
    (unit Cmdliner.Term.t * Cmdliner.Term.info, string) Result.t
  (** [uninstall_user_subcommand ~component_name ~ctx_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will uninstall the component with non-privileged
      user permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["uninstall-user-" ^ component_name].

      [~ctx_t]: A Cmdliner term that sets up common options and delivers a
      context record. The common options include options for logging. The
      context record is described at {!Dkml_install_api}.

      You must include the [ctx_t] term in your returned [Term.t * Term.info],
      as in:

      {[
        let execute_uninstall ctx =
          Format.printf
          "We can run bytecode using: %s@\n"
          (ctx.Dkml_install_api.Context.path_eval "%{ocamlrun:share}/bin/ocamlrun.exe")

      let uninstall_user_subcommand ~component_name ~subcommand_name ~ctx_t =
          let doc = "Uninstall the pieces that don't require Administrative rights" in
        Result.ok @@ Cmdliner.Term.(const execute_uninstall $ ctx_t, info subcommand_name ~doc)
      ]}

      Your [Term.t] function ([uninstall_user_subcommand ctx]) should raise
      {!Installation_error} for any terminal failures. *)

  val needs_install_admin : unit -> bool
  (** [needs_install_admin] should inspect the environment and say [true] if and only
      if the [install_admin_subcommand] is necessary *)

  val needs_uninstall_admin : unit -> bool
  (** [needs_uninstall_admin] should inspect the environment and say [true] if and only
      if the [install_admin_subcommand] is necessary *)

  val install_admin_subcommand :
    component_name:string ->
    subcommand_name:string ->
    ctx_t:Types.Context.t Cmdliner.Term.t ->
    (unit Cmdliner.Term.t * Cmdliner.Term.info, string) Result.t
  (** [install_admin_subcommand ~component_name ~subcommand_name ~ctx_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will install the component with privileged
      administrator (`root` or `sudo` on Unix) permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["install-admin-" ^ component_name].

      [~ctx_t]: A Cmdliner term that sets up common options and delivers a
      context record. The common options include options for logging. The
      context record is described at {!Dkml_install_api}.

      You must include the [ctx_t] term in your returned [Term.t * Term.info],
      as in:

      {[
        let execute_install_admin ctx =
          Format.printf
          "We can run bytecode using: %s@\n"
          (ctx.Dkml_install_api.Context.path_eval "%{ocamlrun:share}/bin/ocamlrun.exe")

        let install_admin_subcommand ~component_name ~subcommand_name ~ctx_t =
          let doc = "Install the pieces requiring Administrative rights" in
          Result.ok @@ Cmdliner.Term.(const execute_install_admin $ ctx_t, info subcommand_name ~doc)
      ]}

      Your [Term.t] function ([execute_install_admin ctx]) should raise
      {!Installation_error} for any terminal failures. *)

  val uninstall_admin_subcommand :
    component_name:string ->
    subcommand_name:string ->
    ctx_t:Types.Context.t Cmdliner.Term.t ->
    (unit Cmdliner.Term.t * Cmdliner.Term.info, string) Result.t
  (** [uninstall_admin_subcommand ~component_name ~ctx_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will uninstall the component with privileged
      administrator (`root` or `sudo` on Unix) permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["uninstall-" ^ component_name].

      [~ctx_t]: A Cmdliner term that sets up common options and delivers a
      context record. The common options include options for logging. The
      context record is described at {!Dkml_install_api}.

      You must include the [ctx_t] term in your returned [Term.t * Term.info],
      as in:

      {[
        let execute_uninstall_admin ctx =
          Format.printf
          "We can run bytecode using: %s@\n"
          (ctx.Dkml_install_api.Context.path_eval "%{ocamlrun:share}/bin/ocamlrun.exe")

        let uninstall_admin_subcommand ~component_name ~subcommand_name ~ctx_t =
          let doc = "Install the pieces requiring Administrative rights" in
          Result.ok @@ Cmdliner.Term.(const execute_uninstall_admin $ ctx_t, info subcommand_name ~doc)
      ]}

      Your [Term.t] function ([execute_uninstall_admin ctx]) should raise
      {!Installation_error} for any terminal failures. *)

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

module type Intf = sig
  module type Component_config_defaultable = Component_config_defaultable
  [@@inline]
  (** Component configuration values that can be supplied with defaults. *)

  module type Component_config = Component_config
  [@@inline]
  (** Each component must define a configuration module *)

  (**
    You {e should} [include Default_component_config] in any of your
    components so that your component can be future-proof against
    changes in the {!Component_config} signature.
  *)

  (** Default values for a subset of the module type {!Component_config}. *)
  module Default_component_config : sig
    include Component_config_defaultable
    (** @inline *)
  end

  (* {3 Exceptions} *)

  exception Installation_error of string
  (** Raise [Installation_error message] when your component has a terminal
    failure  *)
end
