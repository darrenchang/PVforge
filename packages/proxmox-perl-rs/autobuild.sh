#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

# for i in common/pkg pmg-rs pve-rs;

cd $SCRIPT_DIR/$PKGNAME/common/pkg
exec_build_make
# cp *.buildinfo *.changes *.dsc *.tar* *.deb $SCRIPT_DIR/$PKGNAME/ ||true
cd $SCRIPT_DIR/$PKGNAME/pmg-rs
exec_build_make
mkdir -p "/tmp/proxmox/perl-rs/";
for deb_file in $(find $SCRIPT_DIR/$PKGNAME -name '*.deb'); do
  cp $deb_file "/tmp/proxmox/perl-rs/";
done
apt install -y --allow-downgrades $(ls /tmp/proxmox/${pkg_name}/*.deb | grep -v -- '-dbgsym_\|zfs-dracut_\|-test_');

cd $SCRIPT_DIR/$PKGNAME/pbe-rs
exec_build_make
for deb_file in $(find $SCRIPT_DIR/$PKGNAME -name '*.deb'); do
  cp $deb_file "/tmp/proxmox/perl-rs/";
done
apt install -y --allow-downgrades $(ls /tmp/proxmox/${pkg_name}/*.deb | grep -v -- '-dbgsym_\|zfs-dracut_\|-test_');

