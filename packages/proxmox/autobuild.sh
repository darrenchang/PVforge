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
    "proxmox-api-macro"
    "proxmox-time-api"
    "proxmox-acme"
    "proxmox-config-digest"
    # "proxmox-apt-api-types"
    # "pbs-api-types"
    # "proxmox-access-control"
    # "proxmox-acme-api"
    # "proxmox-apt"
    # "proxmox-auth-api"
    # "proxmox-borrow"
    # "proxmox-client"
    # "proxmox-daemon"
    # "proxmox-deb-version"
    # "proxmox-dns-api"
    # "proxmox-docgen"
    # "proxmox-fixed-string"
    # "proxmox-human-byte"
    # "proxmox-ldap"
    # "proxmox-log"
    # "proxmox-login"
    # "proxmox-metrics"
    # "proxmox-network-api"
    # "proxmox-network-types"
    # "proxmox-node-status"
    # "proxmox-notify"
    # "proxmox-oci"
    # "proxmox-openid"
    # "proxmox-pgp"
    # "proxmox-resource-scheduling"
    # "proxmox-rest-server"
    # "proxmox-rrd"
    # "proxmox-rrd-api-types"
    # "proxmox-s3-client"
    # "proxmox-sendmail"
    # "proxmox-serde"
    # "proxmox-simple-config"
    # "proxmox-sortable-macro"
    # "proxmox-subscription"
    # "proxmox-syslog-api"
    # "proxmox-systemd"
    # "proxmox-tfa"
    # "proxmox-upgrade-checks"
    # "proxmox-uuid"
    # "proxmox-worker-task"
    # "pve-api-types"
  )

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

