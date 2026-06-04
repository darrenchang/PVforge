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
fi
apt update
apt install usr-is-merged usrmerge -y
yes |mk-build-deps --install --remov
cd $SCRIPT_DIR/$PKGNAME
exec_build_make

# Remvoe debug and test symbols
for i in $(find ./ \( -name '*-test_*.deb' -o -name '*-dbg_*.deb' \)); do
  rm "${i}";
done

