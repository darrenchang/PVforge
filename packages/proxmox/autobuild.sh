#!/bin/bash

set -e

# Function to clean up on exit (Ctrl+C)
cleanup() {
    printf "\033[r"
    printf "\033[${ROWS};1H"
    tput cnorm
    # Add a newline so the prompt appears BELOW the progress bar
    echo ""
    exit
}
trap cleanup SIGINT EXIT

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
    "proxmox-api-macro"
    "proxmox-time-api"
    "proxmox-acme"
    "proxmox-config-digest"
    "proxmox-serde"
    "proxmox-fixed-string"
    "proxmox-apt-api-types"
    "proxmox-log"
    "proxmox-systemd"
    "proxmox-daemon"
    "proxmox-network-types"
    "proxmox-worker-task"
    "proxmox-rest-server"
    "proxmox-uuid"
    "proxmox-acme-api"
    "proxmox-tfa"
    "proxmox-auth-api"
    "pbs-api-types"
    "proxmox-access-control"
    "proxmox-apt"
    "proxmox-borrow"
    "proxmox-client"
    "proxmox-deb-version"
    "proxmox-dns-api"
    "proxmox-docgen"
    "proxmox-human-byte"
    "proxmox-ldap"
    "proxmox-login"
    "proxmox-metrics"
    "proxmox-network-api"
    "proxmox-node-status"
    "proxmox-notify"
    "proxmox-oci"
    "proxmox-openid"
    "proxmox-pgp"
    "proxmox-resource-scheduling"
    "proxmox-rrd"
    "proxmox-rrd-api-types"
    "proxmox-s3-client"
    "proxmox-sendmail"
    "proxmox-simple-config"
    "proxmox-sortable-macro"
    "proxmox-subscription"
    "proxmox-syslog-api"
    "proxmox-upgrade-checks"
    "pve-api-types"
  )

TOTAL=${#RUST_LIBS[@]}
CURRENT=0

rm -rf /tmp/${PKGNAME}
for rust_lib in "${RUST_LIBS[@]}"; do
  # Print progress bar
  BAR_WIDTH=40
  ROWS=$(tput lines)
  printf "\033[1;$(($ROWS - 1))r"
  printf "\n%.0s" $(seq 1 $ROWS)
  tput civis
  printf "\033[s"
  printf "\033[${ROWS};1H"
  PERCENT=$(( CURRENT * 100 / TOTAL))
  FILLED=$(( CURRENT * BAR_WIDTH / TOTAL))
  EMPTY=$(( BAR_WIDTH - FILLED ))
  BAR=$(printf "%${FILLED}s" | tr ' ' '#')
  SPACE=$(printf "%${EMPTY}s" | tr ' ' '-')
  printf "\033[K\e[30;46m[%s%s] %d%% (%d/%d) building ${rust_lib}...\e[0m" "$BAR" "$SPACE" "$PERCENT" "$CURRENT" "$TOTAL"
  printf "\033[u"

  echo "####################"
  echo "Build start... [${CURRENT}/${TOTAL}]"
  echo "Building rust package ${rust_lib}..."
  echo "CARGO: $($CARGO --version)"
  echo "RUSTC: $($RUSTC --version)"
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
  # Print progress bar
  BAR_WIDTH=40
  ROWS=$(tput lines)
  printf "\033[1;$(($ROWS - 1))r"
  printf "\n%.0s" $(seq 1 $ROWS)
  tput civis
  printf "\033[s"
  printf "\033[${ROWS};1H"
  PERCENT=$(( CURRENT * 100 / TOTAL))
  FILLED=$(( CURRENT * BAR_WIDTH / TOTAL))
  EMPTY=$(( BAR_WIDTH - FILLED ))
  BAR=$(printf "%${FILLED}s" | tr ' ' '#')
  SPACE=$(printf "%${EMPTY}s" | tr ' ' '-')
  printf "\033[K\e[30;46m[%s%s] %d%% (%d/%d) building ${rust_lib}...\e[0m" "$BAR" "$SPACE" "$PERCENT" "$CURRENT" "$TOTAL"
  printf "\033[u"
done

