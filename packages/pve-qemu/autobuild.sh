#!/bin/bash
PKGNAME="pve-qemu"

errlog(){
        echo $1
        exit 1

}

update_submodule(){
	cd $SH_DIR/$PKGNAME
	echo "init submodule"
	git submodule update --init --depth=1 || errlog "submodule update failed"
	cd $SH_DIR/$PKGNAME/qemu
	git submodule update --init --depth=1
	# replace Zeex/subhook
	echo "set submodule url for subhook"
	cd  $SH_DIR/$PKGNAME/qemu/roms/edk2/
	git submodule set-url UnitTestFrameworkPkg/Library/SubhookLib/subhook https://github.com/tianocore/edk2-subhook
	git submodule update --init --recursive --depth=1
}

exec_build(){
        apt update
        apt install libpve-access-control librados2  librados-dev -y
        yes |mk-build-deps --install --remove
        echo "clean "
        make clean || echo ok
        echo "build deb in `pwd` "
	cd $SH_DIR/$PKGNAME/qemu
	meson subprojects download
	cd $SH_DIR/$PKGNAME
        make deb || errlog "make deb error"
}

echo "This is $PKGNAME build scripts"


SH_PATH=$(realpath "$0")
SH_DIR=$(dirname $SH_PATH)

rm -fr $SH_DIR/$PKGNAME/.git
rm -fr $SH_DIR/$PKGNAME/qemu
rm -fr $SH_DIR/$PKGNAME/qemu/roms/edk2
cd $SH_DIR/$PKGNAME
git init
git config --global --add safe.directory $SH_DIR/$PKGNAME
git config --global --add safe.directory $(pwd) && \
git remote add origin https://git.proxmox.com/git/pve-qemu && \
git remote set-url --push origin https://git.proxmox.com/git/pve-qemu && \
git fetch origin && \
git checkout -f master && \
git submodule update --init --recursive && \
git pull origin master && \
git config --global --add safe.directory $SH_DIR/$PKGNAME/qemu
git config --global --add safe.directory $SH_DIR/$PKGNAME/qemu/roms/edk2

exec_build
