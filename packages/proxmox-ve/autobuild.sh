#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME
git config --global --add safe.directory $(pwd) || true

# This arm64 port does not build a Proxmox kernel (the host distro provides
# one), so the proxmox-ve meta package must not depend on
# proxmox-default-kernel or it becomes uninstallable outside the builder.
# The transitional pve-headers package still depends on the unavailable
# proxmox-default-headers; it is filtered out by build_pve.sh/install.sh.
sed -i '/proxmox-default-kernel/d' debian/control

exec_build_make
