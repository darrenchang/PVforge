#!/bin/bash
export ZSTD_SYS_USE_PKG_CONFIG=1
export AWS_LC_SYS_NO_JITTER_ENTROPY=1
export AWS_LC_SYS_CFLAGS=-O0

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME
rm -fr .git
git init
git config --global --add safe.directory $(pwd)
git remote add origin https://git.proxmox.com/git/proxmox-backup && \
git remote set-url --push origin https://git.proxmox.com/git/proxmox-backup && \
git fetch origin && \
git checkout -f master && \
git pull origin master && \
git checkout be67219cb && \
exec_build_make

# Remove static deb
for i in $(find $SCRIPT_DIR/$PKGNAME -name "*client-static*.deb"); do
  rm $i
done

