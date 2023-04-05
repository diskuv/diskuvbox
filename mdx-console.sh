#!/bin/sh
IN=$1
shift

#   shellcheck disable=SC2016
sed 's/```console/```sh/g; s#[$] diskuvbox#$ ./diskuvbox.exe#g' "$IN" > "$IN.sh"

#   produce "$IN.sh".corrected
TERM=dumb ocaml-mdx test --force-output "$IN.sh"

#   shellcheck disable=SC2016
sed 's/```sh/```console/g; s#[$] ./diskuvbox.exe#$ diskuvbox#g' "$IN.sh.corrected" > "$IN.corrected"
