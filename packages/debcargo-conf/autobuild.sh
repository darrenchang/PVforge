#!/bin/bash

set -e

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
    "tracing-journald:tracing-journald"
    "handlebars:handlebars"
    "serde-with:serde_with"
    "pam:pam"
    "regex:regex"
    "base64urlsafedata:base64urlsafedata"
    "openssl-macros:openssl-macros"
    "openssl-sys:openssl-sys"
    "compact-jwt:compact_jwt"
    "der-parser:der-parser"
    "serde-cbor:serde_cbor"
    "serde-cbor-2:serde_cbor_2"
    "webauthn-attestation-ca:webauthn-attestation-ca"
    "serde-wasm-bindgen:serde-wasm-bindgen"
    "rustversion:rustversion"
    "wasm-bindgen-shared:wasm-bindgen-shared"
    "wasm-bindgen-macro-support:wasm-bindgen-macro-support"
    "wasm-bindgen-macro:wasm-bindgen-macro"
    "wasm-bindgen:wasm-bindgen"
    "js-sys:js-sys"
    "web-sys:web-sys"
    "webauthn-rs-proto:webauthn-rs-proto"
    "webauthn-rs-core:webauthn-rs-core"
    "webauthn-rs:webauthn-rs"
    "endian-trait-derive:endian_trait_derive"
    "endian-trait:endian_trait"
    "rustyline:rustyline"
  )

export CARGO=/usr/local/bin/cargo
export RUSTC=/usr/local/bin/rustc

for entry in "${RUST_LIBS[@]}"; do
  rust_lib="${entry%%:*}"
  repackage_name="${entry##*:}"
  echo "####################"
  echo "Build start..."
  echo "Building rust package ${repackage_name}..."
  echo "CARGO: $($CARGO --version)"
  echo "RUSTC: $($RUSTC --version)"
  rm -rf ./build/*
  ./repackage.sh ${repackage_name}
  (
    cd build/${rust_lib}/
    pwd
    yes |mk-build-deps --install --remove; \
    dpkg-buildpackage -b -us -uc
  )
  mkdir -p /tmp/${PKGNAME}-temp
  mkdir -p /tmp/${PKGNAME}
  for deb_pkg in $(find $(pwd)/build/ -name *.deb); do
    cp ${deb_pkg} "/tmp/${PKGNAME}-temp/"
    cp ${deb_pkg} "/tmp/${PKGNAME}/"
    apt install --reinstall -y --allow-downgrades $(ls /pxvirt/packages/debcargo-conf/debcargo-conf/build/librust-compact-jwt*.deb | grep -v -- 'compact-jwt+msextensions-dev\|-abcdtz_')
  done
  rm -rf /tmp/${PKGNAME}-temp
  echo "Build finished for rust library ${repackage_name}..."
done

