#!/bin/sh
# usage: crosscompiling-opam-installer.sh \
#   "$(opam var opam-installer-bin)/opam-installer" \
#   "%{name}%-<<TOOLCHAIN>>.install" \
#   "%{name}%" \
#   "%{lib}%" \
#   "%{man}%" \
#   "%{prefix}%" \
#   "%{stublibs}%" \
#   "%{toplevel}%"
# where <<TOOLCHAIN>> is darwin_arm64 or another target ABI.

opam_installer=$1
shift
install_file=$1
shift
name=$1
shift
libdir=$1
shift
mandir=$1
shift
prefix=$1
shift
stubsdir=$1
shift
topdir=$1
shift

if [ ! -e "$install_file" ]; then
    # if this package does not install any files, skip it
    exit 0
fi

exec "$opam_installer" \
    --install "$install_file" \
    --name="$name" \
    --libdir="$libdir" \
    --mandir="$mandir" \
    --prefix="$prefix" \
    --stubsdir="$stubsdir" \
    --topdir="$topdir"
