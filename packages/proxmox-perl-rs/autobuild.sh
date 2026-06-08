#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

for i in common/pkg pmg-rs pve-rs;
do
	cd $SCRIPT_DIR/$PKGNAME/$i
	exec_build_make
	cp *.buildinfo *.changes *.dsc *.tar* *.deb $SCRIPT_DIR/$PKGNAME/ ||true
  mkdir -p "/tmp/proxmox/perl-rs/${i}/";
  pwd; ls
  echo $SCRIPT_DIR/$PKGNAME/${i}
  for deb_file in $(find $SCRIPT_DIR/$PKGNAME/${i} -name '*.deb'); do
    cp $deb_file "/tmp/proxmox/perl-rs/${i}/";
  done
  apt install -y --allow-downgrades $(ls /tmp/proxmox/${pkg_name}/*.deb | grep -v -- '-dbgsym_\|zfs-dracut_\|-test_');
done
