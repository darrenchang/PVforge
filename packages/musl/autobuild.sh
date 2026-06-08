#!/bin/bash
echo "HELLO"
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

SH_PATH=$(realpath "$0")
SH_DIR=$(dirname $SH_PATH)
 
curl -L -o musl-cross-make.zip https://github.com/richfelker/musl-cross-make/archive/e5147dde912478dd32ad42a25003e82d4f5733aa.zip
unzip -d ./musl/ musl-cross-make.zip
rm -r musl-cross-make.zip
mv ./musl/musl-cross-make-* ./musl/musl-cross-make
cp ./musl/config.mak ./musl/musl-cross-make/
(
  cd ./musl/musl-cross-make/;
  make -j"$(nproc)";
  make install;
)

