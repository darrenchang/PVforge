#!/bin/bash

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME
pwd
rm -rf .git
git init
git config --global --add safe.directory $(pwd)

# Upstream pins wasm-bindgen-cli-support =0.2.108 (the version in the
# Proxmox archive). This repo builds wasm-bindgen 0.2.118 via debcargo-conf,
# and the cli-support version must match the wasm-bindgen crate that the yew
# apps compile against, so re-pin everything to 0.2.118 (built by
# debcargo-conf-extra).
sed -i 's/=0\.2\.108/=0.2.118/' Cargo.toml
sed -i 's/0\.2\.108-~~/0.2.118-~~/g; s/0\.2\.109-~~/0.2.119-~~/g' debian/control
sed -i 's/librust-wasm-bindgen-dev (=0\.2\.108-[^)]*)/librust-wasm-bindgen-dev (>= 0.2.118-~~)/' debian/debcargo.toml
rm -f Cargo.lock
exec_build_make
