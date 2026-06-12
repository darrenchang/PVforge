#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME
export ZSTD_SYS_USE_PKG_CONFIG=1
apt update
yes |mk-build-deps --install --remove
exec_build_make
cd $SCRIPT_DIR/$PKGNAME/build
cp *.deb *.buildinfo *.changes *.dsc *.tar* $SCRIPT_DIR/$PKGNAME/ ||true
