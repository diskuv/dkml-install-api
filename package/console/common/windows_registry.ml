(*
     * https://nsis.sourceforge.io/Add_uninstall_information_to_Add/Remove_Programs
     * https://docs.microsoft.com/en-us/windows/win32/msi/uninstall-registry-key
*)

open Dkml_install_runner.Error_handling.Monad_syntax
open Author_types

(** Find reg.exe. For safety we'll look in the same directory as cmd.exe
    first. *)
let find_reg_exe () =
  let* std_search_path, _fl =
    Dkml_install_runner.Error_handling.map_msg_error_to_progress
      (Bos.OS.Cmd.search_path_dirs (Bos.OS.Env.opt_var ~absent:"" "PATH"))
  in
  let* search, _fl =
    (* Ex. C:\WINDOWS\system32\reg.exe *)
    match Bos.OS.Env.var "COMSPEC" with
    | None -> return std_search_path
    | Some comspec ->
        (* Ex. C:\WINDOWS\system32 *)
        let comspec_dir = Fpath.(v comspec |> parent) in
        let* exists, _fl =
          Dkml_install_runner.Error_handling.map_msg_error_to_progress
            (Bos.OS.Dir.exists comspec_dir)
        in
        if exists then return (comspec_dir :: std_search_path)
        else return std_search_path
  in
  Dkml_install_runner.Error_handling.map_msg_error_to_progress
    (Bos.OS.Cmd.get_tool ~search Bos.Cmd.(v "reg"))

module Add_remove_programs = struct
  let registry_template_pf =
    Printf.sprintf
      {|

Windows Registry Editor Version 5.00

[%s]
"DisplayName"="%s"
"DisplayVersion"="%s"
%s
"Publisher"="%s"
"InstallDate"="%s"
"InstallLocation"="%s"
"QuietUninstallString"="\"%s\\uninstall.exe\" --ci --prefix \"%s\" --quiet --color=never"
"UninstallString"="\"%s\\uninstall.exe\" --prefix \"%s\""
"URLInfoAbout"="%s"
"URLUpdateInfo"="%s"
"HelpLink"="%s"
%s
"NoModify"=dword:00000001
"NoRepair"=dword:00000001
"Language"=%s
|}

  (** [registry_key ~program_name] is
    ["HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\<program_name.name_camel_case_nospaces>"] *)
  let registry_key ~(program_name : program_name) =
    "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\"
    ^ program_name.name_camel_case_nospaces

  let registry_template ~installation_prefix ~(organization : organization)
      ~(program_name : program_name) ~(program_info : program_info)
      ~program_version ~app_ico_path_opt =
    let escaped_installation_prefix =
      String.escaped (Fpath.to_string installation_prefix)
    in
    let localnow = Unix.localtime (Unix.time ()) in
    let localyyyymmdd =
      Printf.sprintf "%04d%02d%02d" (1900 + localnow.tm_year)
        (localnow.tm_mon + 1) localnow.tm_mday
    in

    registry_template_pf
      (* [HKEY\...\_] *) (registry_key ~program_name)
      (* DisplayName=%s *)
      program_name.name_full (* DisplayVersion=%s *) program_version
      (* "DisplayIcon"="C:\\Users\\beckf\\AppData\\Local\\Programs\\DiskuvOCaml\\32x32.ico" *)
      (Option.fold ~none:""
         ~some:(fun app_ico_path ->
           let escaped_app_ico_path =
             String.escaped (Fpath.to_string app_ico_path)
           in
           Printf.sprintf {|"DisplayIcon"="%s"|} escaped_app_ico_path)
         app_ico_path_opt)
      (* Publisher=%s *)
      organization.legal_name (* InstallDate=%s *) localyyyymmdd
      (* InstallLocation=%s *)
      escaped_installation_prefix
      (* QuietUninstallString=%s --prefix %s *)
      escaped_installation_prefix escaped_installation_prefix
      (* UninstallString=%s --prefix %s *)
      escaped_installation_prefix escaped_installation_prefix
      (* URLInfoAbout=%s *)
      (Option.fold ~none:""
         ~some:(Printf.sprintf {|"URLInfoAbout"="%s"|})
         program_info.url_info_about_opt)
      (* URLUpdateInfo=%s *)
      (Option.fold ~none:""
         ~some:(Printf.sprintf {|"URLUpdateInfo"="%s"|})
         program_info.url_update_info_opt)
      (* HelpLink=%s *)
      (Option.fold ~none:""
         ~some:(Printf.sprintf {|"HelpLink"="%s"|})
         program_info.help_link_opt)
      (* "EstimatedSize"=dword:0015cff7 | units in KB *)
      (Option.fold ~none:""
         ~some:(fun estimated_byte_size ->
           Printf.sprintf {|"EstimatedSize"=dword:%08Lx|}
             (Int64.div estimated_byte_size 1024L))
         program_info.estimated_byte_size_opt)
      (* "Language"=%s | default is en-US (0x409) *)
      (Printf.sprintf "dword:%08x"
         (Option.value ~default:0x409 program_info.windows_language_code_id_opt))

  let delete_program_entry ~program_name =
    (* Delete from registry.

       https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/reg-delete *)
    let* reg_exe, _fl = find_reg_exe () in
    let cmd =
      Bos.Cmd.(
        v (Fpath.to_string reg_exe)
        % "delete" % registry_key ~program_name % "/f")
    in
    Logs.debug (fun l -> l "Running:@ %a" Bos.Cmd.pp cmd);
    Spawn.spawn ~err_ok:true cmd

  let write_program_entry ~installation_prefix ~organization ~program_name
      ~program_assets ~program_version ~program_info =
    (* Make absolute path for installation prefix.

       No guarantee that prefix is not relative like in --prefix=_build/p.
       Since goes into Registry, it needs to be an absolute path. *)
    let* pwd, _fl =
      Dkml_install_runner.Error_handling.map_msg_error_to_progress
        (Bos.OS.Dir.current ())
    in
    let installation_prefix =
      match Fpath.is_rel installation_prefix with
      | true -> Fpath.(pwd // installation_prefix)
      | false -> installation_prefix
    in

    (* Make PREFIX/app.ico if available *)
    let* app_ico_path_opt, _fl =
      match program_assets.logo_icon_32x32_opt with
      | None -> return None
      | Some logo_icon_32x32 ->
          let app_ico_path = Fpath.(installation_prefix / "app.ico") in
          let* (), _fl =
            Dkml_install_runner.Error_handling.map_msg_error_to_progress
              (Bos.OS.File.write app_ico_path logo_icon_32x32)
          in
          return (Some app_ico_path)
    in

    (* Make a TMP/uninstall.reg file *)
    let registry_contents =
      String.trim
        (registry_template ~installation_prefix ~organization ~program_name
           ~program_version ~program_info ~app_ico_path_opt)
    in
    let* registry_file, _fl =
      Dkml_install_runner.Error_handling.map_msg_error_to_progress
        (Bos.OS.File.tmp "uninstall%s.reg")
    in
    let* (), _fl =
      Dkml_install_runner.Error_handling.map_msg_error_to_progress
        (Bos.OS.File.write registry_file registry_contents)
    in

    (* Write into registry.

       https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/reg-import *)
    let* reg_exe, _fl = find_reg_exe () in
    Logs.info (fun l -> l "Writing to registry for Add/Remove Programs");
    let cmd =
      Bos.Cmd.(
        v (Fpath.to_string reg_exe) % "import" % Fpath.to_string registry_file)
    in
    Logs.debug (fun l ->
        l "Running:@ %a@ with the contents:@ @[<v>  %a@]" Bos.Cmd.pp cmd
          Fmt.lines registry_contents);
    Spawn.spawn cmd
end
