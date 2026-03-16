#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME

arch=`arch`
if [[ "$arch" == "loongarch64" || "$arch" == "aarch64" ]];then
  for i in `cat $SCRIPT_DIR/series`; do
   patch -p1 < ../$i
  done
fi

RUST_LIBS=(
    "cc:cc"
    "openssl:openssl"
    "openssl-probe:openssl-probe"
    "url:url"
    "http-body-util:http-body-util"
    "hyper:hyper"
    "hyper-util:hyper-util"
    "futures:futures"
    "js-sys:js-sys"
    "zstd:zstd"
    "const-format:const_format"
    "env-logger:env_logger"
    "tar:tar"
    "walkdir:walkdir"
    "sync-wrapper:sync_wrapper"
    "tokio-openssl:tokio-openssl"
    "tokio-stream:tokio-stream"
    "textwrap:textwrap"
    "serde:serde"
    "serde-bytes:serde_bytes"
    "serde-plain:serde_plain"
    "endian-trait-derive:endian_trait_derive"
    "endian-trait:endian_trait"
    "rustyline:rustyline"
  )

for entry in "${RUST_LIBS[@]}"; do
  rust_lib="${entry%%:*}"
  repackage_name="${entry##*:}"
  rm -rf ./build/*
  ./repackage.sh ${repackage_name}
  (
    cd build/${rust_lib}/
    pwd
    yes |mk-build-deps --install --remove
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

