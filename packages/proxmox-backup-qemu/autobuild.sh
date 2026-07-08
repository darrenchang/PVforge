#!/bin/bash
export ZSTD_SYS_USE_PKG_CONFIG=1
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME/submodules/proxmox-backup/
apt update
yes |mk-build-deps --install --remove
apt install librust-pbs-api-types-dev=1.0.1-1 -y
cd $SCRIPT_DIR/$PKGNAME
exec_build_make

