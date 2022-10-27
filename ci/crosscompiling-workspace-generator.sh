#!/bin/sh
# usage: crosscompiling-workspace-generator.sh "%{name}%" "%{_:build}%/dune-workspace" DUNE_CONTEXT
# args:
#   DUNE_CONTEXT: The contents of your desired Dune workspace file except the "(lang dune 2.9)" header line.
#       example: "(context (default (targets native darwin_arm64)))"
name=$1
shift
duneworkspace_filename=$1
shift
duneworkspace_content=$1
shift

# Get out of here if no cross-compiling needed
case "$name" in
    base-bigarray|base-threads|base-unix|ocaml-system|dkml-base-compiler|ocaml-config|ocaml|dune|conf-dkml-cross-toolchain)
        # Don't need to, and don't want to, cross-compile these packages.
        exit 0
        ;;
esac

# Add dune-workspace
#   We populate (lang dune 2.9) so can guarantee there is a newline. Dune 3.2.0 and likely many
#   other versions require the (lang ...) clause to be by itself.
printf "(lang dune 2.9)\n%s" "$duneworkspace_content" > "$duneworkspace_filename"
