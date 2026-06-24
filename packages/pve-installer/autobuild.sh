#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"
apt update && \
apt install -y geoip-bin libgtk3-perl;

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME
git config --global --add safe.directory $(pwd)
exec_build_make
