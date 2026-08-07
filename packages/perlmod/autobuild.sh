#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME/perlmod-bin
exec_build_dpkg

cd $SCRIPT_DIR/$PKGNAME
RUST_LIBS=(
    "perlmod-macro"
    "perlmod"
  )

for i in `cat $SCRIPT_DIR/series`;
  do patch -p1 < ../$i
done

export CARGO=/usr/local/bin/cargo
export RUSTC=/usr/local/bin/rustc
for rust_lib in "${RUST_LIBS[@]}"; do
  rm -rf ./build/*
  ./build.sh ${rust_lib}
  mkdir -p /tmp/${PKGNAME}-temp
  mkdir -p /tmp/${PKGNAME}
  # ./build is wiped for each lib, so keep a copy under the package dir where
  # build.sh's deb collection (find + cp to /deb/proxmox/) can still see it.
  mkdir -p $SCRIPT_DIR/deb
  for deb_pkg in $(find $(pwd)/build/ -name '*.deb'); do
    cp ${deb_pkg} "/tmp/${PKGNAME}-temp/"
    cp ${deb_pkg} "/tmp/${PKGNAME}/"
    cp ${deb_pkg} "$SCRIPT_DIR/deb/"
  done
  apt install -y --allow-downgrades /tmp/${PKGNAME}-temp/*.deb --reinstall
  rm -rf /tmp/${PKGNAME}-temp
done

