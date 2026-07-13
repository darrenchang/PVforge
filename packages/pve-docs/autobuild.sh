#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME
git config --global --add safe.directory $(pwd) || true

arch=`arch`
if [[ "$arch" == "loongarch64" || "$arch" == "aarch64" ]];then
  for i in `cat $SCRIPT_DIR/series`; do
   patch -p1 < ../$i
  done
fi

# The repo ships pre-generated docs (generated/, api-viewer/apidata.js) so
# bootstrap builds don't need the PVE perl stack (pve-manager, pve-cluster,
# pve-ha-manager) that is only built later. Git checkout writes scripts/
# after those outputs, so make sees the generator scripts as newer and tries
# to regenerate — failing on the missing PVE modules. Touch the shipped
# outputs so make keeps them.
touch generated/* api-viewer/apidata.js

if [ "$(ls -di /)" != "$(ls -di /proc/1/root)" ]; then
	export DEB_BUILD_OPTIONS=nocheck
fi

if grep -qa container /proc/1/cgroup; then
	export DEB_BUILD_OPTIONS=nocheck
fi

exec_build_make
