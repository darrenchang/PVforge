#!/bin/bash
PKGNAME="proxmox-offline-mirror"

errlog(){
        echo $1
        exit 1

}

exec_build(){
        apt update
        yes |mk-build-deps --install --remove
        echo "clean "
        make clean || echo ok
        echo "build deb in `pwd` "
        make dsc || errlog "build dsc error"
        make deb || errlog "build deb error"
}

echo "This is $PKGNAME build scripts"


SH_PATH=$(realpath "$0")
SH_DIR=$(dirname $SH_PATH)

cd $SH_DIR/$PKGNAME

for i in `cat $SCRIPT_DIR/series`;
  do patch -p1 < ../$i
done

exec_build
