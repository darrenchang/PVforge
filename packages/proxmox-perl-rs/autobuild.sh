#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)
export ZSTD_SYS_USE_PKG_CONFIG=1

echo "This is $PKGNAME build scripts"

. ../common.sh

# for i in common/pkg pmg-rs pve-rs;

cd $SCRIPT_DIR/$PKGNAME/common/pkg
exec_build_make
cd $SCRIPT_DIR/$PKGNAME/pmg-rs
exec_build_make
mkdir -p "/tmp/proxmox/$PKGNAME/";
for deb_file in $(find $SCRIPT_DIR/$PKGNAME -name '*.deb'); do
  cp $deb_file "/tmp/proxmox/$PKGNAME/";
done
apt install -y --allow-downgrades $(ls /tmp/proxmox/$PKGNAME/*.deb | grep -v -- '-dbgsym_\|zfs-dracut_\|-test_');

cd $SCRIPT_DIR/$PKGNAME/pve-rs
exec_build_make
for deb_file in $(find $SCRIPT_DIR/$PKGNAME -name '*.deb'); do
  cp $deb_file "/tmp/proxmox/$PKGNAME/";
done
apt install -y --allow-downgrades $(ls /tmp/proxmox/$PKGNAME/*.deb | grep -v -- '-dbgsym_\|zfs-dracut_\|-test_');

