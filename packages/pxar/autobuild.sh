#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)
export DEB_BUILD_PROFILES=nocheck

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME

yes |mk-build-deps --install --remove
cd $SCRIPT_DIR/$PKGNAME
exec_build_make
