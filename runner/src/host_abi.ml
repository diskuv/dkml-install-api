open Error_handling
open Error_handling.Monad_syntax
open Astring

let detect_with_uname () =
  (* list from https://en.wikipedia.org/wiki/Uname and https://stackoverflow.com/questions/45125516/possible-values-for-uname-m *)
  (* corresponds to autodetect_buildhost_arch in crossplatform-functions.sh *)
  let open Bos in
  let* uname = map_rresult_error_to_string @@ OS.Cmd.resolve Cmd.(v "uname") in
  let* uname_m =
    map_rresult_error_to_string
      OS.Cmd.(run_out Cmd.(uname % "-m") |> to_string ~trim:true)
  in
  let* uname_s =
    map_rresult_error_to_string
      OS.Cmd.(run_out Cmd.(uname % "-s") |> to_string ~trim:true)
  in
  let open Dkml_install_api.Context.Abi_v2 in
  match (uname_s, uname_m) with
  | "Linux", s when String.is_prefix ~affix:"armv7" s -> Result.ok Linux_arm32v7
  | "Linux", s when String.is_prefix ~affix:"armv6" s -> Result.ok Linux_arm32v6
  | "Linux", "aarch64" | "Linux", "arm64" -> Result.ok Linux_arm64
  | "Linux", s when String.is_prefix ~affix:"armv8" s -> Result.ok Linux_arm64
  | "Linux", "i386" | "Linux", "i686" -> Result.ok Linux_x86
  | "Linux", "x86_64" -> Result.ok Linux_x86_64
  | "Darwin", "arm64" -> Result.ok Darwin_arm64
  | "Darwin", "x86_64" -> Result.ok Darwin_x86_64
  | _ ->
      Result.error
        (Fmt.str
           "FATAL: Unsupported build machine type obtained from 'uname -s' and \
            'uname -m': %s and %s"
           uname_s uname_m)

let detect_on_windows () =
  let open Bos in
  let open Dkml_install_api.Context.Abi_v2 in
  let* arch =
    (*
      https://superuser.com/questions/305901/possible-values-of-processor-architecture
      https://winaero.com/check-if-processor-is-32-bit-64-bit-or-arm-in-windows-10/
    *)
    map_rresult_error_to_string @@ OS.Env.req_var "PROCESSOR_ARCHITECTURE"
  in
  if arch = "ARM64" then Result.ok Windows_arm64
  else if arch = "ARM" then Result.ok Windows_arm32
  else
    (* For x86_64 vs x86 we need to look at the CPU *)
    let* reg_opt = map_msg_error_to_string @@ OS.Cmd.find_tool Cmd.(v "reg") in
    match reg_opt with
    | Some reg ->
        (* https://stackoverflow.com/questions/12322308/batch-file-to-check-64bit-or-32bit-os or
           https://mskb.pkisolutions.com/kb/556009
        *)
        let+ lines =
          map_rresult_error_to_string
          @@ OS.Cmd.(
               run_out
                 Cmd.(
                   v (Fpath.to_string reg)
                   % "Query"
                   % {|HKLM\Hardware\Description\System\CentralProcessor\0|})
               |> to_lines)
        in
        if
          List.exists
            (fun line ->
              String.is_prefix ~affix:"Identifier" line
              &&
              match
                String.find_sub ~sub:"x86" (String.Ascii.lowercase line)
              with
              | Some _ -> true
              | None -> false)
            lines
        then Windows_x86
        else Windows_x86_64
    | None ->
        (* Fallback to PROCESSOR_ARCHITECTURE *)
        if arch = "x86" then Result.ok Windows_x86 else Result.ok Windows_x86_64

let create_v2 () =
  if Sys.win32 then detect_on_windows () else detect_with_uname ()
