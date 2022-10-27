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

# Set HERE
HERE=$(dirname "$0")
HERE=$(cd "$HERE" && pwd)
if [ -x /usr/bin/cygpath ]; then
    HERE_MIXED=$(/usr/bin/cygpath -aw "$HERE")
else
    HERE_MIXED=$HERE
fi

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

# Update
opamrun update

# Configure cross-compiling in Opam
OPAM_PKGNAME=${OPAM_PACKAGE%.opam}
#   0. Some host ABIs can cross-compile; set config for those.
case "$dkml_host_abi" in
darwin_x86_64)
    dunecontext='(context (default (targets native darwin_arm64)))'
    toolchain=darwin_arm64;;
*)
    dunecontext='';
    toolchain=''
esac
if [ -n "$dunecontext" ]; then
    #   1. Get a copy of opam-installer. We'll just need the binary.
    if [ ! -x .ci/cross/opam-installer ] && [ ! -x .ci/cross/opam-installer.exe ]; then
        install -d .ci/cross
        opamrun list
        opamrun install opam-installer --yes
        opaminstaller="${opam_root}/dkml/bin/opam-installer"
        if [ -x "$opaminstaller.exe" ]; then
            install "$opaminstaller.exe" .ci/cross/opam-installer.exe
        else
            install "$opaminstaller" .ci/cross/opam-installer
        fi
        # Any transitive packages should be removed since the switch has not been configured
        # for cross-compiling yet. They will only be compiled for the host ABI.
        opamrun remove cmdliner cppo ocamlgraph opam-file-format re seq stdlib-shims --yes
    fi
    #   2. Use Dune-ified packages so can cross-compile (same principle underneath Opam monorepo).
    #      Opam monorepo doesn't work yet for dkml-base-compiler.
    opamrun repository add dune-universe git+https://github.com/dune-universe/opam-overlays.git
    #   3. Set pre-build-commands so that each Opam package has a correct dune-workspace when
    #      cross-compiling.
    option_args=$(printf 'pre-build-commands=["%s" "%s" "%s" "%s"]' \
                "$HERE_MIXED/crosscompiling-workspace-generator.sh" \
                '%{name}%' \
                '%{_:build}%/dune-workspace' \
                "$dunecontext")
    opamrun option "$option_args"
    #   4. Each Opam package must install its cross-compiled libraries into Opam switch
    option_args=$(printf 'post-install-commands=["%s" "%s" "%s" "%s" "%s" "%s" "%s" "%s" "%s"]' \
        "$HERE_MIXED/crosscompiling-opam-installer.sh" \
        "$PWD/.ci/cross/opam-installer" \
        "%{name}%-${toolchain}.install" \
        "%{name}%" \
        "%{lib}%" \
        "%{man}%" \
        "%{prefix}%" \
        "%{stublibs}%" \
        "%{toplevel}%")
    opamrun option "$option_args"

    #   Pin to the Dune-ified packages. Technically most of these are unnecessary
    #   because they will be repeated in `opamrun install` but some are
    #   required to remove DKML's standard MSVC pins
    opamrun pin astring -k version 0.8.5+dune --no-action --yes
    opamrun pin base-bytes -k version base --no-action --yes
    opamrun pin bos -k version 0.2.1+dune --no-action --yes
    opamrun pin cmdliner -k version 1.1.1+dune --no-action --yes
    opamrun pin fmt -k version 0.9.0+dune --no-action --yes
    opamrun pin fpath -k version 0.7.3+dune --no-action --yes
    opamrun pin logs -k version 0.7.0+dune2 --no-action --yes
    opamrun pin ptime -k version 1.0.0+dune2  --no-action --yes
    opamrun pin rresult -k version 0.7.0+dune  --no-action --yes
    opamrun pin seq -k version base+dune  --no-action --yes
    opamrun pin uucp -k version 14.0.0+dune  --no-action --yes
    opamrun pin uuseg -k version 14.0.0+dune  --no-action --yes
    opamrun pin uutf -k version 1.0.3+dune  --no-action --yes
    #   * no --with-test since likely can't run cross-compiled
    #     architecture without an emulator
    opamrun install \
        "./${OPAM_PKGNAME}.opam" \
        astring.0.8.5+dune \
        base-bytes.base \
        bos.0.2.1+dune \
        cmdliner.1.1.1+dune \
        fmt.0.9.0+dune \
        fpath.0.7.3+dune \
        logs.0.7.0+dune2 \
        ptime.1.0.0+dune2 \
        rresult.0.7.0+dune \
        seq.base+dune \
        uucp.14.0.0+dune \
        uuseg.14.0.0+dune \
        uutf.1.0.3+dune \
        --deps-only --yes
    
    # Test
    opamrun exec -- dune build -p diskuvbox @runtest

    # Cross-compile
    opamrun exec -- dune build -p diskuvbox -x "${toolchain}" _build/default/diskuvbox.install "_build/default.${toolchain}/diskuvbox-${toolchain}.install"
else
    # If config switches from cross-compiling to host compiling, reset cross-compiling
    opamrun option 'pre-build-commands='
    opamrun option 'post-install-commands='

    # Build
    opamrun install "./${OPAM_PKGNAME}.opam" --with-test --deps-only --yes
    opamrun exec -- dune build -p diskuvbox                   _build/default/diskuvbox.install
fi

# Quick regression tests
# https://github.com/diskuv/diskuvbox/issues/1
if command -v truncate >/dev/null 2>/dev/null; then
    truncate -s 20MB test32bit
else
    dd if=/dev/zero of=test32bit bs=1024 count=0 seek=20480
fi
opamrun exec -- env OCAMLRUNPARAM=b diskuvbox copy-file -vv test32bit dest/1/2/test32bit
rm -f test32bit

# Prereq: Diagnostics
case "${dkml_host_abi}" in
linux_*)
    if command -v apk; then
        apk add file
    fi ;;
esac

# Copy the installed binaries (including cross-compiled ones) from Opam into dist/ folder.
# Name the binaries with the target ABI since GitHub Releases are flat namespaces.
install -d dist/
mv _build/install/default "_build/install/default.${dkml_host_abi}"
set +f
for i in _build/install/default.*; do
  target_abi=$(basename "$i" | sed s/default.//)
  if [ -e "_build/install/default.${target_abi}/bin/${OPAM_PKGNAME}.exe" ]; then
    install -v "_build/install/default.${target_abi}/bin/${OPAM_PKGNAME}.exe" "dist/${target_abi}-${OPAM_PKGNAME}.exe"
    file "dist/${target_abi}-${OPAM_PKGNAME}.exe"
  else
    install -v "_build/install/default.${target_abi}/bin/${OPAM_PKGNAME}" "dist/${target_abi}-${OPAM_PKGNAME}"
    file "dist/${target_abi}-${OPAM_PKGNAME}"
  fi
done

# For Windows you must ask your users to first install the vc_redist executable.
# Confer: https://github.com/diskuv/dkml-workflows#distributing-your-windows-executables
case "${dkml_host_abi}" in
windows_x86_64) wget -O dist/vc_redist.x64.exe https://aka.ms/vs/17/release/vc_redist.x64.exe ;;
windows_x86) wget -O dist/vc_redist.x86.exe https://aka.ms/vs/17/release/vc_redist.x86.exe ;;
windows_arm64) wget -O dist/vc_redist.arm64.exe https://aka.ms/vs/17/release/vc_redist.arm64.exe ;;
esac
