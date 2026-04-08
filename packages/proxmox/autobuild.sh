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
    "proxmox-http"
    "proxmox-http-error"
    "proxmox-schema"
    "proxmox-router"
    "proxmox-section-config"
    "proxmox-serde"
    "proxmox-fixed-string"
    "proxmox-log"
    "proxmox-network-types"
    "proxmox-worker-task"
    "proxmox-uuid"
    "proxmox-systemd"
    "proxmox-daemon"
    "proxmox-borrow"
    "proxmox-deb-version"
    "proxmox-docgen"
    "proxmox-metrics"
    "proxmox-resource-scheduling"
    "proxmox-sendmail"
    "proxmox-sortable-macro"
    "proxmox-api-macro"
    "proxmox-time-api"
    "proxmox-acme"
    "proxmox-config-digest"
    "proxmox-apt-api-types"
    "proxmox-acme-api"
    "proxmox-tfa"
    "proxmox-rest-server"
    "proxmox-auth-api"
    "pbs-api-types"
    "proxmox-access-control"
    "proxmox-apt"
    "proxmox-client"
    "proxmox-dns-api"
    "proxmox-human-byte"
    "proxmox-ldap"
    "proxmox-login"
    "proxmox-network-api"
    "proxmox-node-status"
    "proxmox-notify"
    "proxmox-oci"
    "proxmox-openid"
    "proxmox-pgp"
    "proxmox-rrd"
    "proxmox-rrd-api-types"
    "proxmox-s3-client"
    "proxmox-simple-config"
    "proxmox-subscription"
    "proxmox-syslog-api"
    "proxmox-upgrade-checks"
    "pve-api-types"
  )

TOTAL=${#RUST_LIBS[@]}
CURRENT=0

rm -rf /tmp/${PKGNAME}
for rust_lib in "${RUST_LIBS[@]}"; do
  print_progress ${TOTAL} ${CURRENT} ${ITEM_NAME}

  echo "####################"
  echo "Build start... [${CURRENT}/${TOTAL}]"
  echo "Building rust package ${rust_lib}..."
  echo "DEBCARGO: $(debcargo --version)"
  rm -rf ./build/*
  ./build.sh ${rust_lib}
  mkdir -p /tmp/${PKGNAME}-temp
  mkdir -p /tmp/${PKGNAME}
  for deb_pkg in $(find $(pwd)/build/ -name '*.deb'); do
    cp ${deb_pkg} "/tmp/${PKGNAME}-temp/"
    cp ${deb_pkg} "/tmp/${PKGNAME}/"
  done
  apt install -y --allow-downgrades /tmp/${PKGNAME}-temp/*.deb --reinstall
  rm -rf /tmp/${PKGNAME}-temp

  CURRENT=$((CURRENT + 1))
  echo "Build finished for rust library ${rust_lib}... [${CURRENT}/${TOTAL}]"

  print_progress ${TOTAL} ${CURRENT} ${ITEM_NAME}
done

