let create_v2 () =
  let open Error_handling.Monad_syntax in
  let open Dkml_install_api.Context.Abi_v2 in
  let is_32bit = Sys.int_size <= 32 in
  Host_abi.create_v2 () >>= fun (host_abi, _fl) ->
  match (host_abi, is_32bit) with
  | Windows_x86_64, true | Windows_x86, true ->
      return Dkml_install_api.Context.Abi_v2.Windows_x86
  | Windows_arm64, true | Windows_arm32, _ -> return Windows_arm32
  | Linux_x86_64, true | Linux_x86, _ -> return Linux_x86
  | Linux_arm64, true | Linux_arm32v7, true -> return Linux_arm32v7
  | Android_arm64v8a, true | Android_arm32v7a, true -> return Android_arm32v7a
  | Android_x86_64, true | Android_x86, _ -> return Android_x86
  | Linux_arm32v6, true -> return Linux_arm32v6
  | Darwin_arm64, true | Darwin_x86_64, true ->
      failwith
        (Fmt.str
           "%a does have a known 32bit mode but OCaml gave back a 32-bit int \
            size˝"
           Dkml_install_api.Context.Abi_v2.pp host_abi)
  | abi_64, false -> return abi_64
