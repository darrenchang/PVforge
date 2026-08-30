#!/bin/bash

set -e
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

BUILDKIT_PROGRESS=plain \
docker buildx bake --set "*.output=type=docker,compression=uncompressed,force-compression=true"

# Assemble ./target: every installable deb from the finished image plus the
# install script. Copy the folder to the machine to install and run
# ./install.sh there.
echo "Assembling ./target from the pve-builder image..."
rm -rf target
CID=$(docker create pve-builder:latest)
docker cp -q "$CID:/deb/proxmox" target
docker rm "$CID" >/dev/null

# Drop what must not be installed on a target machine (same exclusions as
# install.sh, which keeps them as a safety net for unfiltered trees):
# debug symbols, mk-build-deps artifacts, build-time rust sources and their
# only dependent proxmox-wasm-builder, the alternatives that conflict with
# the shipped set (zfs-dracut, proxmox-backup-client-static), the
# transitional pve-headers (needs the unbuilt proxmox-default-headers), the
# zfs test suite, and the ISO installer environment.
# find target \( \
#   -name '*-dbgsym_*.deb' -o \
#   -name '*-build-deps_*.deb' -o \
#   -name 'librust-*.deb' -o \
#   -name 'proxmox-wasm-builder_*.deb' -o \
#   -name 'zfs-dracut_*.deb' -o \
#   -name 'zfs-test_*.deb' -o \
#   -name 'proxmox-backup-client-static_*.deb' -o \
#   -name 'pve-headers_*.deb' \
#   \) -delete
# rm -rf target/pve-installer
find target -type d -empty -delete

cp install-target.sh target/install.sh

echo "Done: ./target holds $(find target -name '*.deb' | wc -l) debs."
echo "Copy it to the target machine and run:  sudo ./install.sh"
