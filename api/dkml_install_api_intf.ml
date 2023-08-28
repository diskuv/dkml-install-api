module type Component_config_defaultable = sig
  val install_depends_on : string list
  (** [install_depends_on] are the components, if any, that this component depends on
      during installation.

      Dependencies will be installed in topological order. *)

  val uninstall_depends_on : string list
  (** [uninstall_depends_on] are the components, if any, that this component depends on
      during uninstallation.
    
      Dependencies will be uninstalled in reverse topological order. *)

  val install_user_subcommand :
    component_name:string ->
    subcommand_name:string ->
    fl:Forward_progress.fatal_logger ->
    ctx_t:Types.Context.t Cmdliner.Term.t ->
    unit Cmdliner.Cmd.t Forward_progress.t
  (** [install_user_subcommand ~component_name ~subcommand_name ~ctx_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will install the component with non-privileged
      user permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["install-user-" ^ component_name].

      [~fl]: A fatal logger used whenver there is an error requiring the
      process to exit.

      [~ctx_t]: A Cmdliner term that sets up common options and delivers a
      context record. The common options include options for logging. The
      context record is described at {!Dkml_install_api}.

      You must include the [ctx_t] term in your returned [Term.t * Cmd.info],
      as in:

      {[
        let execute_install ctx =
          Format.printf
            "We can run bytecode using: %s@\n"
            (ctx.Dkml_install_api.Context.path_eval "%{ocamlrun:share-abi}/bin/ocamlrun")

        let install_user_subcommand ~component_name ~subcommand_name ~fl ~ctx_t =
          let doc = "Install the pieces that don't require Administrative rights" in
          Dkml_install_api.Forward_progress.Continue_progress (Cmdliner.Cmd.(v (info subcommand_name ~doc) (const execute_install $ ctx_t)), fl)
      ]}

      Your [Term.t] function ([install_user_subcommand ctx]) should raise
      {!Installation_error} for any unrecoverable failures. *)

  val uninstall_user_subcommand :
    component_name:string ->
    subcommand_name:string ->
    fl:Forward_progress.fatal_logger ->
    ctx_t:Types.Context.t Cmdliner.Term.t ->
    unit Cmdliner.Cmd.t Forward_progress.t
  (** [uninstall_user_subcommand ~component_name ~ctx_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will uninstall the component with non-privileged
      user permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["uninstall-user-" ^ component_name].

      [~fl]: A fatal logger used whenver there is an error requiring the
      process to exit.

      [~ctx_t]: A Cmdliner term that sets up common options and delivers a
      context record. The common options include options for logging. The
      context record is described at {!Dkml_install_api}.

      You must include the [ctx_t] term in your returned [Term.t * Cmd.info],
      as in:

      {[
        let execute_uninstall ctx =
          Format.printf
          "We can run bytecode using: %s@\n"
          (ctx.Dkml_install_api.Context.path_eval "%{ocamlrun:share-abi}/bin/ocamlrun")

      let uninstall_user_subcommand ~component_name ~subcommand_name ~fl ~ctx_t =
          let doc = "Uninstall the pieces that don't require Administrative rights" in
        Dkml_install_api.Forward_progress.Continue_progress (Cmdliner.Cmd.(v (info subcommand_name ~doc) (const execute_uninstall $ ctx_t)), fl)
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
    fl:Forward_progress.fatal_logger ->
    ctx_t:Types.Context.t Cmdliner.Term.t ->
    unit Cmdliner.Cmd.t Forward_progress.t
  (** [install_admin_subcommand ~component_name ~subcommand_name ~fl ~ctx_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will install the component with privileged
      administrator (`root` or `sudo` on Unix) permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["install-admin-" ^ component_name].

      [~fl]: A fatal logger used whenver there is an error requiring the
      process to exit.

      [~ctx_t]: A Cmdliner term that sets up common options and delivers a
      context record. The common options include options for logging. The
      context record is described at {!Dkml_install_api}.

      You must include the [ctx_t] term in your returned [Term.t * Cmd.info],
      as in:

      {[
        let execute_install_admin ctx =
          Format.printf
          "We can run bytecode using: %s@\n"
          (ctx.Dkml_install_api.Context.path_eval "%{ocamlrun:share-abi}/bin/ocamlrun")

        let install_admin_subcommand ~component_name ~subcommand_name ~ctx_t =
          let doc = "Install the pieces requiring Administrative rights" in
          Dkml_install_api.Forward_progress.Continue_progress (Cmdliner.Cmd.(v (info subcommand_name ~doc) (const execute_install_admin $ ctx_t)), fl)
      ]}

      Your [Term.t] function ([execute_install_admin ctx]) should raise
      {!Installation_error} for any unrecoverable failures. *)

  val uninstall_admin_subcommand :
    component_name:string ->
    subcommand_name:string ->
    fl:Forward_progress.fatal_logger ->
    ctx_t:Types.Context.t Cmdliner.Term.t ->
    unit Cmdliner.Cmd.t Forward_progress.t
  (** [uninstall_admin_subcommand ~component_name ~ctx_t] defines a
      subcommand that should be added to {b dkml-install-runner.exe}
      that, when invoked, will uninstall the component with privileged
      administrator (`root` or `sudo` on Unix) permissions.

      [~component_name]: This will correspond to the component name defined
      in the full [Component_config] module type.

      [~subcommand_name]: Typically but not always the subcommand name is
      ["uninstall-" ^ component_name].

      [~fl]: A fatal logger used whenver there is an error requiring the
      process to exit.

      [~ctx_t]: A Cmdliner term that sets up common options and delivers a
      context record. The common options include options for logging. The
      context record is described at {!Dkml_install_api}.

      You must include the [ctx_t] term in your returned [Term.t * Cmd.info],
      as in:

      {[
        let execute_uninstall_admin ctx =
          Format.printf
          "We can run bytecode using: %s@\n"
          (ctx.Dkml_install_api.Context.path_eval "%{ocamlrun:share-abi}/bin/ocamlrun")

        let uninstall_admin_subcommand ~component_name ~subcommand_name ~fl ~ctx_t =
          let doc = "Install the pieces requiring Administrative rights" in
          Dkml_install_api.Forward_progress.Continue_progress (Cmdliner.Cmd.(v (info subcommand_name ~doc) (const execute_uninstall_admin $ ctx_t)), fl)
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

  (** {2 Process execution} *)

  val log_spawn_onerror_exit :
    id:string ->
    ?success_exitcodes:(int -> bool) ->
    ?conformant_subprocess_exitcodes:bool ->
    Bos.Cmd.t ->
    unit
  (** [log_spawn_onerror_exit ~id ?success_exitcodes ?conformant_subprocess_exitcodes cmd] logs the
      command [cmd] and runs it synchronously, and prints an error on the fatal logger [fl ~id]
      and then exits with a non-zero exit code if the command exits with a non-zero
      error code.

      The environment variable ["OCAMLRUNPARAM"] will be set to ["b"] so that
      any OCaml bytecode launched by [log_spawn_onerror_exit] will have
      backtraces. Any exiting environment variable ["OCAMLRUNPARAM"] will
      be kept, however.

      {3 Success Exit Codes}

      By default exit code 0 is determined to be a success, and every other exit code is
      determined to be a failure. The [success_exitcodes] parameter can be specified to
      change which codes are determined to be successes.

      Further exit code process is described in the next section after an exit code is
      determined to be a failure.

      {3 Failed Exit Codes}

      The exit code used to leave this process depends on [conformant_subprocess_exitcodes].

      When [conformant_subprocess_exitcodes = true] or [conformant_subprocess_exitcodes] is not
      specified, the exit code will be the same as the
      spawned process exit code if and only if the exit code belongs to one of
      {!Forward_progress.Exit_code}; if the spawned exit code does not belong then
      the exit code will be {!Forward_progress.Exit_code.Exit_transient_failure}.

      When [conformant_subprocess_exitcodes = false] the exit code will always be
      {!Forward_progress.Exit_code.Exit_transient_failure} if the spawned process
      ends in error.
      *)

  (** {2 Uninstallation} *)

  val uninstall_directory_onerror_exit :
    id:string -> dir:Fpath.t -> wait_seconds_if_stuck:float -> unit
  (** [uninstall_directory ~id ~dir ~wait_seconds_if_stuck] removes the directory [dir] and, if any process
    is using the files in [dir], will give the [wait_seconds_if_stuck] seconds to stop using the
    program. If the directory cannot be removed then prints an error on the
    fatal logger [fl ~id] and exists with a transient error code.
    
    For Windows machines a file cannot be removed if it is in use. For most *nix
    machines the file can be removed since the inode lives on. Consequently
    only on Windows machines will trigger the logic to check if a process
    is using a file or directory. This behavior may change in the future. *)

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
      Logs.set_reporter (Logs.format_reporter ());
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
        ctx.Context.path_eval "%{staging-ocamlrun:share-abi}/bin/ocamlrun"
      in
      log_spawn_onerror_exit
        (* Always use your own unique id; create it with PowerShell on Windows:
              [guid]::NewGuid().Guid.Substring(0,8)
           or on macOS/Unix:
              uuidgen | tr A-Z a-z | cut -c1-8
         *)
        ~id:"9b7e32e0"
        Cmd.(
          v (Fpath.to_string
              (ctx.Context.path_eval "%{staging-ocamlrun:share-abi}/bin/ocamlrun"))
          % Fpath.to_string
              (ctx.Context.path_eval "%{_:share}%/generic/your_bytecode.bc")
          (* Pass --verbosity and --color to your bytecode *)
          %% of_list (Array.to_list (Log_config.to_args ctx.Context.log_config)))

    let () =
      let reg = Component_registry.get () in
      Component_registry.add_component reg
        (module struct
          include Default_component_config

          let component_name = "enduser-yourcomponent"

          let install_depends_on = [ "staging-ocamlrun" ]

          let install_user_subcommand ~component_name:_ ~subcommand_name ~fl ~ctx_t =
            let doc = "Install your component" in
            Dkml_install_api.Forward_progress.Continue_progress (Cmdliner.Term.(const execute $ ctx_t, info subcommand_name ~doc), fl)
        end)
  ]}

  Others can use the {!Log_config.t} return value from [setup_log] when
  calling {!Log_config.to_args}.
  *)

  module Log_config : module type of Log_config
end
