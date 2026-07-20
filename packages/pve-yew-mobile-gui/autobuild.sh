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
cd support-keyring
exec_build_make

