#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"


cd $SCRIPT_DIR/$PKGNAME

RUST_LIBS=(
    "perlmod-macro"
    "perlmod"
  )

for rust_lib in "${RUST_LIBS[@]}"; do
  rm -rf ./build/*
  ./build.sh ${rust_lib}
  mkdir -p /tmp/${PKGNAME}-temp
  mkdir -p /tmp/${PKGNAME}
  for deb_pkg in $(find $(pwd)/build/ -name *.deb); do
    cp ${deb_pkg} "/tmp/${PKGNAME}-temp/"
    cp ${deb_pkg} "/tmp/${PKGNAME}/"
  done
  apt install -y --allow-downgrades /tmp/${PKGNAME}-temp/*.deb --reinstall
  rm -rf /tmp/${PKGNAME}-temp
done

