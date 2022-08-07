#!/bin/sh
#
# Prerequisites:
# * Docker
#
# Tested on:
# * Windows 64-bit with Diskuv OCaml and `with-dkml support/test-32bit.sh`
#
# Probably works:
# * Linux 32-bit or 64-bit. Use `sh support/test-32bit.sh`
#
# Won't work:
# * macOS ARM64; it won't let you run Docker with linux 32-bit, probably
#   because 32-bit circuitry was removed from Apple Silicon chips

set -euf

# Go to project directory
HERE=$(dirname "$0")
HERE=$(cd "$HERE" && pwd)
cd "$HERE/.."

# Get dockcross launch script
DOCKCROSS_SH=support/dockcross-manylinux2014-x86.sh
if [ ! -e ${DOCKCROSS_SH} ]; then
  if command -v dos2unix; then
    docker run --platform linux/386 -it dockcross/manylinux2014-x86:latest | dos2unix > ${DOCKCROSS_SH}.tmp
  else
    docker run --platform linux/386 -it dockcross/manylinux2014-x86:latest > ${DOCKCROSS_SH}.tmp
  fi
  chmod +x ${DOCKCROSS_SH}.tmp
  mv ${DOCKCROSS_SH}.tmp ${DOCKCROSS_SH}
fi

# Run code in test-32bit-helper.sh. The diskuvbox project directory is
# mounted at /work
exec ${DOCKCROSS_SH} --args '-it --platform linux/386' support/test-32bit-helper.sh
