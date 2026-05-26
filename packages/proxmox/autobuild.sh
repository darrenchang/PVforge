#!/bin/bash

set -e

export ZSTD_SYS_USE_PKG_CONFIG=1 # proxmox-sys needs this setting

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME

for i in `cat $SCRIPT_DIR/series`; do
  patch --forward -p1 < ../$i || true
done

RUST_LIBS=(
    "proxmox-base64"
    "proxmox-io"
    "proxmox-lang"
    "proxmox-async"
    "proxmox-time"
    "proxmox-sys"
    "proxmox-product-config"
    "proxmox-compression"
    "proxmox-shared-memory"
    "proxmox-shared-cache"
    "proxmox-rate-limiter"
    "proxmox-serde"
    "proxmox-systemd"
    "proxmox-sendmail"
    "proxmox-uuid"
    "proxmox-api-macro"
    "proxmox-schema"
    "proxmox-simple-config"
    "proxmox-http"
    "proxmox-http-error"
    "proxmox-router"
    "proxmox-acme"
    "proxmox-log"
    "proxmox-section-config"
    "proxmox-daemon"
    "proxmox-network-types"
    "proxmox-config-digest"
    "proxmox-network-api"
    "proxmox-worker-task"
    "proxmox-rest-server"
    "proxmox-acme-api"
    "proxmox-fixed-string"
    "proxmox-apt-api-types"
    "proxmox-tfa"
    "proxmox-auth-api"
    "proxmox-human-byte"
    "proxmox-access-control"
    "proxmox-borrow"
    "proxmox-deb-version"
    "proxmox-dns-api"
    "proxmox-docgen"
    "proxmox-ini"
    "proxmox-login"
    "proxmox-metrics"
    "proxmox-node-status"
    "proxmox-parallel-handler"
    "proxmox-resource-scheduling"
    "proxmox-rrd"
    "proxmox-rrd-api-types"
    "proxmox-sortable-macro"
    "proxmox-subscription"
    "proxmox-syslog-api"
    "proxmox-time-api"
    "proxmox-pgp"
    "proxmox-apt"
    "proxmox-upgrade-checks"
    "proxmox-wireguard"
    "proxmox-client"
    "pve-api-types"
    "proxmox-s3-client"
    "proxmox-ldap"
    "proxmox-notify"
    "proxmox-oci"
    "proxmox-openid"
    "pbs-api-types"
    "proxmox-procfs"
)

build_rust_libs(){
  rm -rf ./build/*
  ./build.sh ${rust_lib}
  mkdir -p /tmp/${PKGNAME}-temp
  mkdir -p ./deb/
  for deb_pkg in $(find $(pwd)/build/ -name '*.deb'); do
    cp ${deb_pkg} "/tmp/${PKGNAME}-temp/"
    cp ${deb_pkg} "./deb/"
  done
  apt install -y --allow-downgrades /tmp/${PKGNAME}-temp/*.deb --reinstall
  rm -rf /tmp/${PKGNAME}-temp

  echo "Build finished for rust library ${rust_lib}... [${CURRENT}/${TOTAL}]"
}

export NOTEST=1
TOTAL=${#RUST_LIBS[@]}
CURRENT=0
rm -rf /tmp/${PKGNAME}
for rust_lib in "${RUST_LIBS[@]}"; do
  # print_progress ${TOTAL} ${CURRENT} ${rust_lib}

  CURRENT=$((CURRENT + 1))
  print_progress ${TOTAL} ${CURRENT} ${rust_lib}
  if [ ! -t 1 ]; then
    build_rust_libs > /dev/null 2>&1
  else
    build_rust_libs
  fi
done

