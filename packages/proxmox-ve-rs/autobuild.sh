#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME/

for i in `cat $SCRIPT_DIR/series`;
  do patch -p1 < ../$i
done

# Build frr-templates
(
  cd proxmox-frr-templates && \
  make && \
  apt install -y "$(pwd)/"*".deb";
)

# Build deb
mkdir ./build-tmp
for i in proxmox-sdn-types proxmox-frr proxmox-ve-config; do
  export CRATES=${i}
  exec_build_make &&
  apt install -y --allow-downgrades $(ls $SCRIPT_DIR/$PKGNAME/build/*.deb)
  cp build/*.deb build-tmp/
  make clean
  unset CRATES
done

