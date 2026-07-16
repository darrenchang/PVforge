#!/bin/bash
export ZSTD_SYS_USE_PKG_CONFIG=1
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME
rm -fr .git
rm -fr submodules/proxmox-backup/
git init
git config --global --add safe.directory $(pwd) && \
git remote add origin https://git.proxmox.com/git/proxmox-backup-qemu && \
git remote set-url --push origin https://git.proxmox.com/git/proxmox-backup-qemu && \
git fetch origin && \
git checkout -f master && \
git submodule update --init --recursive && \
git pull origin master && \

cd $SCRIPT_DIR/$PKGNAME/submodules/proxmox-backup/
git checkout 6d515b2625d235360199f299da0cfff68f240c86
apt update
yes |mk-build-deps --install --remove
cd $SCRIPT_DIR/$PKGNAME
exec_build_make

