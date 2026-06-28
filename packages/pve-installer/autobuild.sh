#!/bin/bash
# zstd-sys: link the system libzstd via pkg-config instead of the (absent)
# bundled zstd submodule.
export ZSTD_SYS_USE_PKG_CONFIG=1
# aws-lc-sys (pulled in by rustls/ureq): jitterentropy-base.c has a compile-time
# #error unless built with -O0, but Debian's CFLAGS append -O2 after the build
# script's -O0, so -O2 wins. Disable jitter entropy (Linux getrandom() provides
# sufficient entropy) and force -O0.
export AWS_LC_SYS_NO_JITTER_ENTROPY=1
export AWS_LC_SYS_CFLAGS=-O0

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"
apt update && \
apt install -y geoip-bin libgtk3-perl;

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME
git config --global --add safe.directory $(pwd)
exec_build_make
