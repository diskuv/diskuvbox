#!/bin/sh
set -euf

# Install Opam
printf "\n\n[linux-32bit]$ # \e[31mInstalling Opam ...\e[0m\n\n"
echo /usr/local/bin | bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/cbd243246aba43d2ad0ec2b461ac8486d5881bc4/shell/install.sh)"
echo

opamrun() {
  printf "\n\n[linux-32bit]$ \e[31mopam %s\e[0m\n\n" "$*" >&2
  /usr/local/bin/opam "$@"
}

# Init opam
opamrun init --disable-sandboxing --no-setup --compiler=ocaml-base-compiler.4.12.1 -y

# Install diskuvbox
opamrun install . --yes

# [file_in_mb FILE MB] create a sparse file FILE of size MB kilobytes.
file_in_mb() {
  file_in_mb_FILE=$1
  shift
  file_in_mb_MB=$1
  shift
  if command -v truncate >/dev/null 2>/dev/null; then
    truncate -s "$file_in_mb_MB"M "$file_in_mb_FILE"
  else
    dd if=/dev/zero of="$file_in_mb_FILE" bs=1048576 count=0 seek="$file_in_mb_MB"
  fi
}

# Regression test #1
#   https://github.com/diskuv/diskuvbox/issues/1
file_in_mb _build/test_20m 20
opamrun exec -- env OCAMLRUNPARAM=b diskuvbox copy-file -vv _build/test_20m _build/dest/test_20m

# Regression test #2
#   Same as https://github.com/diskuv/diskuvbox/issues/1, but see if 32-bit can
#   create a larger than 32-bit file.
#
#   2022-08-06: Fails!
#
file_in_mb _build/test_5gb 5120
#   Continue after failure.
set +e
#   Here is the original failure
opamrun exec -- env OCAMLRUNPARAM=b dune exec -- src/bin/main.exe copy-file -vv _build/test_5gb _build/dest/test_5gb
#   Here is a smallest reproducible test case
echo
ls -lh _build/test_20m _build/test_5gb
opamrun exec -- ocaml < support/test_32bit_bos.ml

#   Troubleshooting
#     shellcheck disable=SC2016
printf '\n\nEntering a bash shell for you to see what is wrong. Use [opam exec --] or [eval $(opam env)] to run commands. Type [exit] when done\n\n'
exec bash -l
