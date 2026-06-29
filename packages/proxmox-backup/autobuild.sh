#!/bin/bash
export ZSTD_SYS_USE_PKG_CONFIG=1
export AWS_LC_SYS_NO_JITTER_ENTROPY=1
export AWS_LC_SYS_CFLAGS=-O0

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME
git config --global --add safe.directory $(pwd)
exec_build_make

# Remove static deb
for i in $(find $SCRIPT_DIR/$PKGNAME -name "*client-static*.deb"); do
  rm $i
done

