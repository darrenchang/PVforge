#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

SH_PATH=$(realpath "$0")
SH_DIR=$(dirname $SH_PATH)

. ../common.sh

copy_dir
# The Proxmox git tree ships a packaging-only GNUmakefile at the source root.
# GNU make prefers it over the autotools-generated Makefile, so an in-tree
# dpkg-buildpackage would run its empty 'all' target and debhelper would skip
# the (non-existent) 'install' target, leaving debian/tmp empty. Proxmox's own
# 'make deb' removes it before building; do the same here.
rm -f GNUmakefile
DEB_BUILD_OPTIONS=nocheck exec_build_dpkg
cp  /build/*.changes /build/*.buildinfo /build/*.deb /build/*.tar.* /build/*.dsc $SH_DIR/$PKGNAME || true
