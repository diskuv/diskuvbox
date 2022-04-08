; This first rule creates "corrected" source code in the Dune build directory
; that always has an Apache v2.0 license at the top of each file.
(rule
 (targets diskuvbox.corrected.ml diskuvbox.corrected.mli)
 (deps
  (:license %{project_root}/etc/license-header.txt)
  (:conf    %{project_root}/etc/headache.conf))
 (action
  (progn
   ; `headache` adds/replaces headers in source code. It is documented at
   ; https://github.com/Frama-C/headache/#readme
   ;
   ; 1. The `headache` program modifies files in-place, so we make a copy of
   ;    the original file.
   ; 2. On Windows `heachache` can fail with "Permission denied" if we don't
   ;    set write permissions on the file.
   ; `diskuvbox` can accomplish both goals on all its supported platforms.
   (run diskuvbox copy-file -m 644 diskuvbox.ml  diskuvbox.corrected.ml)
   (run diskuvbox copy-file -m 644 diskuvbox.mli diskuvbox.corrected.mli)
   ; Add Apache v2.0 license to each file
   (run headache -h %{license} -c %{conf} %{targets})
   ;
   ; `ocamlformat` is used so that our source code modification is idempotent.
   ; (Advanced: Options chosen so that continuous integration tests work with
   ; any version of `ocamlformat`.)
   (run ocamlformat --inplace --disable-conf-files --enable-outside-detected-project %{targets}))))

; These second set of rules let us type:
;      dune build @runlicense --auto-promote
;
; Anytime we type that Dune will take the corrected source code from the Dune
; build directory and use it to modify the original source code.
(rule
 (alias runlicense)
 (action
   (diff diskuvbox.ml  diskuvbox.corrected.ml)))
(rule
 (alias runlicense)
 (action
   (diff diskuvbox.mli diskuvbox.corrected.mli)))
