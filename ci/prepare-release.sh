#!/bin/sh
set -euf

# Restructure multi-ABI directories
_release="$(pwd)/_release"
install -d "$_release"

cd dist
find . -mindepth 1 -maxdepth 1 -type d | while read -r distname; do
    rsync -av "$distname/" "$_release"
done
cd ..

# Display files to be distributed
cd _release
ls -R
cd ..
