(lang dune 2.9)

(name dkml-install-api)
(version 0.1.0)

(generate_opam_files true)

(source
 (github diskuv/dkml-install-api))
(license Apache-2.0)
(authors "Diskuv, Inc. <opensource+diskuv-ocaml@support.diskuv.com>")
(maintainers "opensource+diskuv-ocaml@support.diskuv.com")

(package
 (name dkml-install-api)
 (synopsis "API for Diskuv OCaml (DKML) installation components")
 (description
  "All DKML installation components implement the interfaces exposed in this API.")
 (depends
  (alcotest (and (>= 1.4.0) :with-test))
  (odoc (and (>= 1.5.3) :with-doc))
  (dune (>= 2.9))
  (fmt (>= 0.8.9))
  (astring (>= 0.8.5))))
