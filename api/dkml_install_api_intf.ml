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
      {!Installation_error} for any unrecoverable failures. *)

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
      {!Installation_error} for any unrecoverable failures. *)

  val needs_install_admin : ctx:Types.Context.t -> bool
  (** [needs_install_admin ~ctx] should inspect the environment and say [true]
      if and only if the [install_admin_subcommand] is necessary.
        
      [ctx] will be a minimal context that does not have access to other
      components. *)

  val needs_uninstall_admin : ctx:Types.Context.t -> bool
  (** [needs_uninstall_admin] should inspect the environment and say [true]
      if and only if the [install_admin_subcommand] is necessary.
        
      [ctx] will be a minimal context that does not have access to other
      components. *)

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
      {!Installation_error} for any unrecoverable failures. *)

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
      {!Installation_error} for any unrecoverable failures. *)

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
  (** {2 Configuration} *)

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

  (** {2 Error handling} *)

  exception Installation_error of string
  (** Raise [Installation_error message] when your component has a terminal
    failure  *)

  (** {2 Process execution} *)

  val log_spawn_and_raise : Bos.Cmd.t -> unit
  (** [log_spawn_and_raise cmd] logs the command [cmd] and runs it
      synchronously, raising {!Installation_error} if the command exits with a
      non-zero error code.

      The environment variable ["OCAMLRUNPARAM"] will be set to ["b"] so that
      any OCaml bytecode launched by [log_spawn_and_raise] will have
      backtraces. Any exiting environment variable ["OCAMLRUNPARAM"] will
      be kept, however. *)

  (**
  {2 Logging}

  Logging follows the Cmdliner standards.

  All dkml_install generated executables can be supplied with the following
  options:

  {v
      --color=WHEN (absent=auto)
          Colorize the output. WHEN must be one of `auto', `always' or
          `never'.

      -q, --quiet
          Be quiet. Takes over -v and --verbosity.

      -v, --verbose
          Increase verbosity. Repeatable, but more than twice does not bring
          more.

      --verbosity=LEVEL (absent=warning)
          Be more or less verbose. LEVEL must be one of `quiet', `error',
          `warning', `info' or `debug'. Takes over -v.
  v}

  You can use {!Log_config} to pass the color and verbosity options into
  your own bytecode executables.

  Start by initializing the logger in your own executables with the
  following [setup_log_t] Cmdliner Term:

  {[
    let setup_log style_renderer level =
      Fmt_tty.setup_std_outputs ?style_renderer ();
      Logs.set_level level;
      Logs.set_reporter (Logs_fmt.reporter ());
      Dkml_install_api.Log_config.create ?log_config_style_renderer:style_renderer
        ?log_config_level:level ()

    let setup_log_t =
      Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())
  ]}

  Finally, with a {!Log_config.t} you can use {!Log_config.to_args} to pass the
  correct command line options into your own executables.
  For components that are configured to spawn bytecode programs
  you can locate the {!Log_config.t} in the
  {!Dkml_install_api.Context.log_config}
  ([ctx.Dkml_install_api.Context.log_config])
  context field. That could look like:

  {[
    let execute ctx =
      let ocamlrun =
        ctx.Context.path_eval "%{staging-ocamlrun:share}%/generic/bin/ocamlrun"
      in
      log_spawn_and_raise
        Cmd.(
          v (Fpath.to_string
              (ctx.Context.path_eval "%{staging-ocamlrun:share}%/generic/bin/ocamlrun"))
          % Fpath.to_string
              (ctx.Context.path_eval "%{_:share}%/generic/your_bytecode.bc")
          (* Pass --verbosity and --color to your bytecode *)
          %% Log_config.to_args ctx.Context.log_config)

    let () =
      let reg = Component_registry.get () in
      Component_registry.add_component reg
        (module struct
          include Default_component_config

          let component_name = "enduser-yourcomponent"

          let depends_on = [ "staging-ocamlrun" ]

          let install_user_subcommand ~component_name:_ ~subcommand_name ~ctx_t =
            let doc = "Install your component" in
            Result.ok
            @@ Cmdliner.Term.(const execute $ ctx_t, info subcommand_name ~doc)
        end)
  ]}

  Others can use the {!Log_config.t} return value from [setup_log] when
  calling {!Log_config.to_args}.
  *)

  module Log_config : module type of Log_config
end
