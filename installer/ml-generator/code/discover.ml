open Configurator.V1
open Bos

let admin_link_flags ~ccomp_type =
  if ccomp_type = "msvc" then
    [
      (* On Windows all linking first goes through flexlink.exe, so
         we need -link to pass the option to LINK.EXE. *)
      "-cclib";
      "-link";
      "-cclib";
      "/MANIFEST:EMBED";
      "-cclib";
      "-link";
      "-cclib";
      "/MANIFESTUAC:level='requireAdministrator'";
    ]
  else []

let user_link_flags ~ccomp_type =
  if ccomp_type = "msvc" then
    [
      (* https://docs.microsoft.com/en-us/windows/security/identity-protection/user-account-control/how-user-account-control-works#installer-detection-technology 
         says if we don't explicitly set an elevation level, anything that
         looks like an installer filename (ex. dkml-user-install-runner.exe) will
         be treated as an admin installer. So we explicitly must say that
         we do not need elevation.
       *)
      (* On Windows all linking first goes through flexlink.exe, so
         we need -link to pass the option to LINK.EXE. *)
      "-cclib";
      "-link";
      "-cclib";
      "/MANIFEST:EMBED";
      "-cclib";
      "-link";
      "-cclib";
      "/MANIFESTUAC:level='asInvoker'";
    ]
  else []

let console_link_flags ~ccomp_type =
  if ccomp_type = "msvc" then
    let current_dir = Rresult.R.error_msg_to_invalid_arg (OS.Dir.current ()) in
    [
      (* On Windows all linking first goes through flexlink.exe, so
         we need -link to pass the option to LINK.EXE.

         All the /MANIFESTINPUT:filename will be merged and embedded. *)
      "-cclib";
      "-link";
      "-cclib";
      "/MANIFEST:EMBED";
      "-cclib";
      "-link";
      "-cclib";
      Fmt.str "/MANIFESTINPUT:%a" Fpath.pp
        Fpath.(current_dir / "entry.assembly.manifest");
      "-cclib";
      "-link";
      "-cclib";
      Fmt.str "/MANIFESTINPUT:%a" Fpath.pp
        Fpath.(current_dir / "entry-application.manifest");
    ]
  else []

let () =
  main ~name:"runner" (fun c ->
      let ccomp_type = ocaml_config_var_exn c "ccomp_type" in
      Flags.write_sexp "admin-link-flags.sexp" (admin_link_flags ~ccomp_type);
      Flags.write_sexp "user-link-flags.sexp" (user_link_flags ~ccomp_type);
      Flags.write_sexp "console-link-flags.sexp"
        (console_link_flags ~ccomp_type))
