#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME

arch=`arch`
if [[ "$arch" == "loongarch64" || "$arch" == "aarch64" ]];then
  for i in `cat $SCRIPT_DIR/series`; do
   patch -p1 < ../$i
  done
fi
yes |mk-build-deps --install --remove
cd $SCRIPT_DIR/$PKGNAME
exec_build_make
