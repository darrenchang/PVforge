#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME

for i in `cat $SCRIPT_DIR/series`; do
  patch -p1 < ../$i
done

RUST_LIBS=(
    # "proxmox-base64"
    # "proxmox-io"
    # "proxmox-lang"
    # "proxmox-async"
    # "proxmox-time"
    # "proxmox-sys"
    # "proxmox-product-config"
    # "proxmox-compression"
    # "proxmox-shared-memory"
    # "proxmox-shared-cache"
    # "proxmox-rate-limiter"
    # "proxmox-http"
    # "proxmox-http-error"
    # "proxmox-schema"
    # "proxmox-router"
    # "proxmox-section-config"
    # "proxmox-api-macro"
    # "proxmox-time-api"
    # "proxmox-acme"
    # "proxmox-config-digest"
    # "proxmox-serde"
    # "proxmox-fixed-string"
    # "proxmox-apt-api-types"
    # "proxmox-log"
    # "proxmox-systemd"
    # "proxmox-daemon"
    # "proxmox-network-types"
    # "proxmox-worker-task"
    # "proxmox-rest-server"
    # "proxmox-uuid"
    # "proxmox-acme-api"
    "proxmox-tfa"
    # "proxmox-auth-api"
    # "pbs-api-types"
    # "proxmox-access-control"
    # "proxmox-apt"
    # "proxmox-borrow"
    # "proxmox-client"
    # "proxmox-deb-version"
    # "proxmox-dns-api"
    # "proxmox-docgen"
    # "proxmox-human-byte"
    # "proxmox-ldap"
    # "proxmox-login"
    # "proxmox-metrics"
    # "proxmox-network-api"
    # "proxmox-node-status"
    # "proxmox-notify"
    # "proxmox-oci"
    # "proxmox-openid"
    # "proxmox-pgp"
    # "proxmox-resource-scheduling"
    # "proxmox-rrd"
    # "proxmox-rrd-api-types"
    # "proxmox-s3-client"
    # "proxmox-sendmail"
    # "proxmox-simple-config"
    # "proxmox-sortable-macro"
    # "proxmox-subscription"
    # "proxmox-syslog-api"
    # "proxmox-upgrade-checks"
    # "pve-api-types"
  )

rm -rf /tmp/${PKGNAME}
for rust_lib in "${RUST_LIBS[@]}"; do
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
done

