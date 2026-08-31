#!/bin/bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

cd $SCRIPT_DIR/$PKGNAME/ceph

arch=`arch`
if [ "$arch" == "loongarch64" ];then
	for i in `cat $SCRIPT_DIR/series.loongarch64.ceph`;
		do patch -p1 < ../../$i
	done
elif [ "$arch" == "aarch64" ]; then
	patch -p1 -d "$SCRIPT_DIR/$PKGNAME" < "$SCRIPT_DIR/patches/002-remove-lintian.patch"
	# GCC 14 stack-clash probe loop CFI bug -> SIGILL of ceph-mon/osd/mgr/mds
	# on FPAC CPUs; see the patch header.
	patch -p1 -d "$SCRIPT_DIR/$PKGNAME" < "$SCRIPT_DIR/patches/006-rules-arm64-no-stack-clash-protection.patch"
fi
# The packaging repo is a submodule whose .git is a gitfile into the parent
# repo, which is not in the Docker build context: 'git rev-parse HEAD' fails
# and the binaries report "ceph version 20.2.1 ()", which PVE rejects as
# "Ceph Nautilus required". Fall back to the recorded upstream commit.
patch -p1 -d "$SCRIPT_DIR/$PKGNAME" < "$SCRIPT_DIR/patches/005-makefile-git-version-fallback.patch"
apt update
apt install usr-is-merged usrmerge -y
yes |mk-build-deps --install --remov
cd $SCRIPT_DIR/$PKGNAME
exec_build_make

# Remvoe debug and test symbols
for i in $(find ./ \( -name '*-test_*.deb' -o -name '*-dbg_*.deb' \)); do
  rm "${i}";
done

