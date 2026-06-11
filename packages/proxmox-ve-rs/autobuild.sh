#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME/

for i in `cat $SCRIPT_DIR/series`;
  do patch -p1 < ../$i
done

for i in proxmox-sdn-types proxmox-frr proxmox-ve-config; do
  export CRATES=${i}
  exec_build_make &&
  apt install -y --allow-downgrades $(ls $SCRIPT_DIR/$PKGNAME/build/*.deb)
  unset CRATES
done


# do
# 	cd $SCRIPT_DIR/$PKGNAME/$i
# 	exec_build_make
# 	cp *.buildinfo *.changes *.dsc *.tar* *.deb $SCRIPT_DIR/$PKGNAME/ ||true
#   mkdir -p "/tmp/proxmox/perl-rs/${i}/";
#   pwd; ls
#   echo $SCRIPT_DIR/$PKGNAME/${i}
#   for deb_file in $(find $SCRIPT_DIR/$PKGNAME/${i} -name '*.deb'); do
#     cp $deb_file "/tmp/proxmox/perl-rs/${i}/";
#   done
# done
