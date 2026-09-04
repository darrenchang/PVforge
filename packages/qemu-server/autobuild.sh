#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME

rm -fr $SCRIPT_DIR/$PKGNAME/.git
git init
git config --global --add safe.directory $(pwd) && \
git remote add origin https://git.proxmox.com/git/qemu-server && \
git remote set-url --push origin https://git.proxmox.com/git/qemu-server && \
git fetch origin && \
git checkout -f master && \
git submodule update --init --recursive && \
sed -i '/pve-ha-manager <!nocheck>/d' $SCRIPT_DIR/$PKGNAME/debian/control;

# local fixes on top of upstream master (see patches/ and series)
for i in `cat $SCRIPT_DIR/series`;
  do patch -p1 < ../$i || errlog "failed to apply $i"
done

exec_build_make
