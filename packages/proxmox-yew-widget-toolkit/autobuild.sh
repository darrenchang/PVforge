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

# pwt-macros dev-depends on trybuild, which is not packaged; tests are not
# run here, so drop the dev-dependencies (debcargo resolves them against
# /usr/share/cargo/registry even when only packaging).
sed -i '/^\[dev-dependencies\]/,$d' pwt-macros/Cargo.toml

# The upstream Makefile 'build' target runs debcargo for pwt-macros AND pwt
# before anything is installed, but debcargo for pwt only resolves the
# pwt-macros path dependency once librust-pwt-macros-dev is present in
# /usr/share/cargo/registry -- so the steps are driven manually here:
# package/build/install pwt-macros first, then package/build pwt.
MACRO_PKG_VER=$(dpkg-parsechangelog -l pwt-macros/debian/changelog -SVersion | sed -e 's/-.*//')
PKG_VER=$(dpkg-parsechangelog -l debian/changelog -SVersion | sed -e 's/-.*//')

# the pwt-macros test suite needs the dropped dev-dependencies (trybuild),
# so skip tests entirely
export DEB_BUILD_PROFILES=nocheck
export DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)"

yes | mk-build-deps \
  --install \
  --tool 'apt-get -o APT::Get::Remove=false --yes' \
  pwt-macros/debian/control

make clean || echo ok
rm -rf build
mkdir build
echo system >build/rust-toolchain

rm -f pwt-macros/debian/control
debcargo package \
  --config "$PWD/pwt-macros/debian/debcargo.toml" \
  --changelog-ready --no-overlay-write-back \
  --directory "$PWD/build/pwt-macros" \
  "pwt-macros" "${MACRO_PKG_VER}" || errlog "debcargo pwt-macros error"
(cd build/pwt-macros && dpkg-buildpackage -b -uc -us -Pnocheck) || errlog "build pwt-macros deb error"
apt install -y --allow-downgrades --no-remove ./build/librust-pwt-macros-dev_*.deb || errlog "install pwt-macros error"

rm -f debian/control
debcargo package \
  --config "$PWD/debian/debcargo.toml" \
  --changelog-ready --no-overlay-write-back \
  --directory "$PWD/build/pwt" "pwt" "${PKG_VER}" || errlog "debcargo pwt error"
yes | mk-build-deps \
  --install \
  --tool 'apt-get -o APT::Get::Remove=false --yes' \
  build/pwt/debian/control
(cd build/pwt && dpkg-buildpackage -b -uc -us -Pnocheck) || errlog "build pwt deb error"
