(lang dune 2.9)

(name diskuvbox)
(version 0.1.0)
(cram enable)
(using mdx 0.1)

(generate_opam_files true)

(source
 (github diskuv/diskuvbox))
(license Apache-2.0)
(authors "Diskuv, Inc. <opensource+diskuv-ocaml@support.diskuv.com>")
(maintainers "opensource+diskuv-ocaml@support.diskuv.com")

(package
 (name diskuvbox)
 (synopsis "Cross-platform basic set of script commands")
 (description
  "A cross-platform basic set of script commands. Available as a single binary (`diskuvbox`, or `diskuvbox.exe` on Windows) and as an OCaml library.")
 (depends
  (odoc     (and (>= 1.5.3) :with-doc))
  ; minimums come from matrix testing in .github/workflows/test.yml
  (ocaml    (>= 4.09.0))
  ; all of these may go lower; simply has not been tested
  (ppx_deriving (>= 5.2.1))
  (bos      (>= 0.2.0))
  (fmt      (>= 0.8.9))
  (logs     (>= 0.7.0))
  (mdx      (>= 2.0.0))
  (cmdliner (>= 1.0.0))
  ; these are used in src/lib/dune.runlicense.inc
  (headache    (and (>= 1.05)   :build))
  (ocamlformat (and (>= 0.19.0) :build))
  ))
