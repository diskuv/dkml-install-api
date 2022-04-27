(** [ver_m_n_o_p] converts the package version, as reported by ["dune subst"] through Opam,
    into the ["mmmmm.nnnnn.ooooo.ppppp"] format required by an Application Manifest.

    Confer https://docs.microsoft.com/en-us/windows/win32/sbscs/application-manifests#assemblyidentity *)
let ver_m_n_o_p () =
  (* https://dune.readthedocs.io/en/latest/usage.html#dune-subst-1 *)
  let package_version = "%%VERSION%%" in
  if String.contains package_version '%' then
    (* dune subst has not been run as part of Opam build *)
    "0.0.0.0"
  else
    (* remove "v" as prefix, if any *)
    let package_version_sans_v =
      let l = String.length package_version in
      if l > 0 && String.get package_version 0 = 'v' then
        String.sub package_version 1 (l - 1)
      else package_version
    in
    (* parse out version *)
    match Semver.of_string package_version_sans_v with
    | Some sv -> Fmt.str "%d.%d.%d.0" sv.major sv.minor sv.patch
    | None -> "0.0.0.0"

let () =
  print_endline
    (Fmt.str
       "<?xml version='1.0' encoding='UTF-8' standalone='yes'?>\n\
        <assembly xmlns='urn:schemas-microsoft-com:asm.v1' \
        manifestVersion='1.0'>\n\
       \  <assemblyIdentity type=\"win32\" \
        name=\"Diskuv.DKML.consoleSetupExeProxy\" version=\"%s\" />\n\
        </assembly>"
       (ver_m_n_o_p ()))
