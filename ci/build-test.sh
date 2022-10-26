#!/bin/sh
set -euf

usage() {
    echo "'--opam-package OPAM_PACKAGE.opam --executable-name EXECUTABLE_NAME' where you have a (executable (public_name EXECUTABLE_NAME) ...) in some 'dune' file" >&2
    exit 3
}
OPTION=$1
shift
[ "$OPTION" = "--opam-package" ] || usage
OPAM_PACKAGE=$1
shift
OPTION=$1
shift
[ "$OPTION" = "--executable-name" ] || usage
EXECUTABLE_NAME=$1
shift

# If (executable (public_name EXECUTABLE_NAME) ...) already has .exe then executable will
# have .exe. Otherwise it depends on exe_ext.
case "$EXECUTABLE_NAME" in
*.exe) suffix_ext="" ;;
*) suffix_ext="${exe_ext:-}" ;;
esac

# shellcheck disable=SC2154
echo "
=============
build-test.sh
=============
.
---------
Arguments
---------
OPAM_PACKAGE=$OPAM_PACKAGE
EXECUTABLE_NAME=$EXECUTABLE_NAME
.
------
Matrix
------
dkml_host_abi=$dkml_host_abi
abi_pattern=$abi_pattern
opam_root=$opam_root
exe_ext=${exe_ext:-}
.
-------
Derived
-------
suffix_ext=$suffix_ext
.
"

# PATH. Add opamrun
if [ -n "${CI_PROJECT_DIR:-}" ]; then
    export PATH="$CI_PROJECT_DIR/.ci/sd4/opamrun:$PATH"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
    export PATH="$PC_PROJECT_DIR/.ci/sd4/opamrun:$PATH"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
    export PATH="$GITHUB_WORKSPACE/.ci/sd4/opamrun:$PATH"
else
    export PATH="$PWD/.ci/sd4/opamrun:$PATH"
fi

# Initial Diagnostics
opamrun switch
opamrun list
opamrun var
opamrun config report
opamrun exec -- ocamlc -config
xswitch=$(opamrun var switch)
if [ -x /usr/bin/cypgath ]; then
    xswitch=$(/usr/bin/cygpath -au "$xswitch")
fi
if [ -e "$xswitch/src-ocaml/config.log" ]; then
    echo '--- BEGIN src-ocaml/config.log ---' >&2
    cat "$xswitch/src-ocaml/config.log" >&2
    echo '--- END src-ocaml/config.log ---' >&2
fi

# Build
OPAM_PKGNAME=${OPAM_PACKAGE%.opam}
opamrun exec -- env
opamrun install "./${OPAM_PKGNAME}.opam" --with-test --yes

# Quick regression tests
# https://github.com/diskuv/diskuvbox/issues/1
if command -v truncate >/dev/null 2>/dev/null; then
    truncate -s 20MB test32bit
else
    dd if=/dev/zero of=test32bit bs=1024 count=0 seek=20480
fi
opamrun exec -- env OCAMLRUNPARAM=b diskuvbox copy-file -vv test32bit dest/1/2/test32bit
rm -f test32bit

# Copy the installed binary from 'dkml' Opam switch into dist/ folder
install -d dist/
ls -l "${opam_root}/dkml/bin"
install -v "${opam_root}/dkml/bin/${EXECUTABLE_NAME}${suffix_ext}" "dist/${dkml_host_abi}-${EXECUTABLE_NAME}${suffix_ext}"

# Final Diagnostics
case "${dkml_host_abi}" in
linux_*)
    if command -v apk; then
        apk add file
    fi ;;
esac
file "dist/${abi_pattern}-${EXECUTABLE_NAME}${suffix_ext}"

# For Windows you must ask your users to first install the vc_redist executable.
# Confer: https://github.com/diskuv/dkml-workflows#distributing-your-windows-executables
case "${dkml_host_abi}" in
windows_x86_64) wget -O dist/vc_redist.x64.exe https://aka.ms/vs/17/release/vc_redist.x64.exe ;;
windows_x86) wget -O dist/vc_redist.x86.exe https://aka.ms/vs/17/release/vc_redist.x86.exe ;;
windows_arm64) wget -O dist/vc_redist.arm64.exe https://aka.ms/vs/17/release/vc_redist.arm64.exe ;;
esac
