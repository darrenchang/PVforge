#!/bin/bash
export ZSTD_SYS_USE_PKG_CONFIG=1
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME
git config --global --add safe.directory $SCRIPT_DIR/$PKGNAME
git submodule deinit -f submodules/proxmox-backup/
git submodule update --init --recursive

cd $SCRIPT_DIR/$PKGNAME/submodules/proxmox-backup/
git checkout 6d515b2625d235360199f299da0cfff68f240c86
apt update
yes |mk-build-deps --install --remove
apt install librust-pbs-api-types-dev=1.0.1-1 -y
cd $SCRIPT_DIR/$PKGNAME
exec_build_make

