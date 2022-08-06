Create a file
  $ touch a

Create a symlink
  $ touch m
  $ ln -s m n

Use diskuvbox to copy each one at a time. The destination directory should be autocreated.
  $ ./diskuvbox.exe copy-file a dest/1/2/a_copied
  $ ./diskuvbox.exe copy-file n dest/1/2/n_copied

Verify
  $ ls dest/1/2 | sort
  a_copied
  n_copied

Regression test for 32-bit.
| https://github.com/diskuv/diskuvbox/issues/1
| Bug with 32-bit Windows:
|   FATAL: read D:\.opam\dkml\share\dkml-installer-network-ocaml\t\u-unsigned-diskuv-ocaml-windows_x86_64-0.4.1.exe: file too large (44.2MB, max supported size: 16.8MB)
| Root cause:
|   * copy-file used to read file into memory.
|   * On 32-bit OCaml, max memory block is 2^22 words = 2^22 * 4 B = 16MB.
|   * Confer: https://github.com/ocaml/ocaml/blob/f40bc2697234e075eb69294e2e2e19a790de8aba/runtime/caml/mlvalues.h#L159
|   * Confer: https://ocamlverse.github.io/content/runtime.html
  $ if command -v truncate >/dev/null 2>/dev/null; then truncate -s 20MB test32bit; else dd if=/dev/zero of=test32bit bs=1024 count=0 seek=20480; fi
  $ ./diskuvbox.exe copy-file test32bit dest/1/2/test32bit
