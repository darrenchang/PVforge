#!/bin/bash
set -e
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

export PACKAGE_NAME=""
export FORCE_INSTALL="false"
# Parse named arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --package) PACKAGE_NAME="$2"; shift ;;
        --force-install) FORCE_INSTALL="$2"; shift ;;
        --help)
            echo "Usage: $0 [--package ceph-19]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Install one specified package
if [ "$FORCE_INSTALL" = "true" ]; then
  dpkg -i --force-depends /deb/proxmox/${PACKAGE_NAME}/*.deb
else
  apt install -y --allow-downgrades -o Dpkg::Options::="--force-confnew" $(ls /deb/proxmox/${PACKAGE_NAME}/*.deb | grep -v -- '-dbgsym_\|zfs-dracut_\|-test_');
fi
