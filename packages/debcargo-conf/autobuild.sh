#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME

RUST_LIBS=(
    "endian-trait-derive"
    "endian-trait"
  )

for rust_lib in "${RUST_LIBS[@]}"; do
  rm -rf ./build/*
  ./repackage.sh ${rust_lib//-/_}
  (
    cd build/${rust_lib}/
    pwd
    mk-build-deps --install --remove
    dpkg-buildpackage -b -us -uc
  )
  mkdir -p /tmp/${PKGNAME}-temp
  mkdir -p /tmp/${PKGNAME}
  for deb_pkg in $(find $(pwd)/build/ -name *.deb); do
    cp ${deb_pkg} "/tmp/${PKGNAME}-temp/"
    cp ${deb_pkg} "/tmp/${PKGNAME}/"
    apt install -y --allow-downgrades /tmp/${PKGNAME}-temp/*.deb --reinstall
  done
  rm -rf /tmp/${PKGNAME}-temp
done

