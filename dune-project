(lang dune 2.9)
(cram enable)

(name dkml-install-api)
(version 0.3.0)

(package
 (name dkml-install))

(package
 (name dkml-install-runner))

(package
 (name dkml-install-installer))

(package
 (name dkml-package-console))

; (source
;  (github diskuv/dkml-install-api))
; (license Apache-2.0)
; (authors "Diskuv, Inc. <opensource+diskuv-ocaml@support.diskuv.com>")
; (maintainers "opensource+diskuv-ocaml@support.diskuv.com")
;
; (package
;  (name dkml-install)
;  (synopsis "API and registry for Diskuv OCaml (DKML) installation components")
;  (description
;   "All DKML installation components implement the interfaces exposed in this API.")
;  (depends
;   (alcotest (and (>= 1.4.0) :with-test))
;   (odoc (and (>= 1.5.3) :with-doc))
;   (dune (>= 2.9))
;   (ppx_deriving (>= 5.2.1))
;   (astring (>= 0.8.5))
;   (bos (>= 0.2.0))
;   (cmdliner (= 1.0.4))
;   (fmt (>= 0.8.9))
;   (tsort (>= 2.1.0))))

; (package
;  (name dkml-install-runner)
;  (synopsis "Runner executable for Diskuv OCaml (DKML) installation")
;  (description
;   "The runner executable is responsible for loading and running all DKML installation components.")
;  (sites
;   ; <section> <name>
;   (lib plugins))
;  (depends
;   (alcotest (and (>= 1.4.0) :with-test))
;   (odoc (and (>= 1.5.3) :with-doc))
;   (dkml-install (= :version))
;   (dune (>= 2.9))
;   (ppx_expect (>= v0.14.1))
;   (astring (>= 0.8.5))
;   (bos (>= 0.2.0))
;   (cmdliner (= 1.0.4))
;   (fmt (>= 0.8.9))
;   (logs (>= 0.7.0))
;   (diskuvbox (>= 0.1.0))))
;
; (package
;  (name dkml-package-console)
;  (synopsis "Console setup and uninstall executables for Diskuv OCaml (DKML) installation")
;  (description
;   "The setup and uninstall executables are responsible for launching the DKML runners.")
;  (depends
;   (alcotest (and (>= 1.4.0) :with-test))
;   (odoc (and (>= 1.5.3) :with-doc))
;   (dkml-install (= :version))
;   ; runner/console/bin/dune site requires dkml-install-runner package
;   (dkml-install-runner (= :version))
;   (dune (>= 2.9))
;   (diskuvbox (>= 0.1.0))
;   (crunch (>= 3.2.0))))
