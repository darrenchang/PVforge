#!/bin/bash

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
PKGNAME=$(basename $SCRIPT_DIR)

echo "This is $PKGNAME build scripts"

. ../common.sh

# Extra rust libraries needed by the yew GUI stack (proxmox-yew-widget-toolkit,
# proxmox-yew-comp, proxmox-wasm-builder, pve-yew-mobile-gui). They are built
# from the debcargo-conf tree that the dockerfile copies next to this package,
# so that adding them does not invalidate the (very expensive) main
# debcargo-conf docker layer.
cd $SCRIPT_DIR/../debcargo-conf/debcargo-conf

RUST_LIBS=(
    "derivative:derivative:patches:notvendor"
    "geo-types:geo-types:patches:notvendor"
    "geojson:geojson:patches:notvendor"
    "qrcode:qrcode:patches:notvendor"
    "phf-generator:phf_generator:patches:notvendor"
    "phf-macros:phf_macros:none:notvendor"
    "phf:phf:none:notvendor"
    "lasso:lasso:patches:notvendor"
    "codemap:codemap:none:notvendor"
    "grass-compiler:grass_compiler:none:notvendor"
    "grass:grass:patches:notvendor"
    "leb128:leb128:patches:notvendor"
    "gimli-0.32:gimli 0.32:none:notvendor"
    "walrus-macro:walrus-macro:none:notvendor"
    "walrus:walrus:none:notvendor"
    "wasm-bindgen-cli-support:wasm-bindgen-cli-support:none:notvendor"
    "pulldown-cmark-0.11:pulldown-cmark 0.11:none:notvendor"
    "encoding-index-tests:encoding_index_tests:none:notvendor"
    "encoding-index-japanese:encoding-index-japanese:none:notvendor"
    "encoding-index-korean:encoding-index-korean:none:notvendor"
    "encoding-index-simpchinese:encoding-index-simpchinese:none:notvendor"
    "encoding-index-singlebyte:encoding-index-singlebyte:none:notvendor"
    "encoding-index-tradchinese:encoding-index-tradchinese:none:notvendor"
    "encoding:encoding:none:notvendor"
  )

export CARGO=/usr/local/bin/cargo
export RUSTC=/usr/local/bin/rustc

# criterion & friends (test-only build-deps of the phf/grass chain) are not
# packaged; skip them via the nocheck build profile
export DEB_BUILD_PROFILES=nocheck
export DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)"

rm -rf .git
git init
git config --global --add safe.directory $(pwd)

apt update || echo ok

# The wasm-bindgen-cli-support / walrus packaging in src/ predates the
# wasm-bindgen (0.2.118) built by the main debcargo-conf run; the cli-support
# version must match that wasm-bindgen crate exactly, so bump the packaging
# to the matching upstream versions. Their patches are for the old versions
# and are no longer needed (0.26.x already targets wasmparser 0.245 and
# heck 0.5, both of which are available).
sed -i '1s/(0\.2\.99-[^)]*)/(0.2.118-1)/' src/wasm-bindgen-cli-support/debian/changelog
sed -i '1s/(0\.23\.3-[^)]*)/(0.26.1-1)/' src/walrus/debian/changelog
rm -rf src/walrus/debian/patches
sed -i '1s/(0\.22\.0-[^)]*)/(0.26.0-1)/' src/walrus-macro/debian/changelog
rm -rf src/walrus-macro/debian/patches
# walrus 0.26 needs gimli 0.32 while src/gimli packages 0.33: create a
# semver-suffixed gimli-0.32 package (its 0.33-specific patch is dropped,
# 0.32 builds with the default features)
rm -rf src/gimli-0.32
cp -r src/gimli src/gimli-0.32
rm -rf src/gimli-0.32/debian/patches
sed -i '1s/^rust-gimli (0\.33\.0-[^)]*)/rust-gimli-0.32 (0.32.0-1)/' src/gimli-0.32/debian/changelog
grep -q semver_suffix src/gimli-0.32/debian/debcargo.toml || \
  sed -i '1i semver_suffix = true' src/gimli-0.32/debian/debcargo.toml
# proxmox-yew-comp needs pulldown-cmark 0.11 (main src packages 0.13):
# semver package without the CLI bin (the 0.13 bin package is already
# installed and would collide)
rm -rf src/pulldown-cmark-0.11
cp -r src/pulldown-cmark src/pulldown-cmark-0.11
rm -f src/pulldown-cmark-0.11/debian/rules \
      src/pulldown-cmark-0.11/debian/rules.debcargo.hint \
      src/pulldown-cmark-0.11/debian/pulldown-cmark.manpages
sed -i '1s/^rust-pulldown-cmark (0\.13\.3-[^)]*)/rust-pulldown-cmark-0.11 (0.11.3-1)/' src/pulldown-cmark-0.11/debian/changelog
cat > src/pulldown-cmark-0.11/debian/debcargo.toml <<'EOF'
semver_suffix = true
overlay = "."
uploaders = ["Wolfgang Silbermayr <wolfgang@silbermayr.at>"]
excludes = ["benches/**"]
collapse_features = true
bin = false

[packages."lib+@"]
test_is_broken = true

[packages."lib+gen-tests"]
test_is_broken = true

[packages."lib+getopts"]
test_is_broken = true
EOF

# Some optional dependencies of the extra crates are not packaged (image,
# include_sass, abomonation, deepsize, dashmap 6); with collapse_features
# the generated -dev packages would depend on them, so patch those optional
# deps out (same approach as geo-types' remove-rstar.patch).
mkdir -p src/qrcode/debian/patches
cp $SCRIPT_DIR/patches/qrcode-remove-image.patch src/qrcode/debian/patches/remove-image.patch
echo "remove-image.patch" > src/qrcode/debian/patches/series
cp $SCRIPT_DIR/patches/grass-remove-include-sass.patch src/grass/debian/patches/remove-include-sass.patch
echo "remove-include-sass.patch" >> src/grass/debian/patches/series
mkdir -p src/lasso/debian/patches
cp $SCRIPT_DIR/patches/lasso-remove-optional-deps.patch src/lasso/debian/patches/remove-optional-deps.patch
echo "remove-optional-deps.patch" > src/lasso/debian/patches/series
# phf-generator's fix-criterion-feature.patch turns criterion into a hard
# dependency of the -dev package; criterion is not packaged, so drop the
# criterion dependency and the gen_hash_test helper binary instead
cp $SCRIPT_DIR/patches/phf-generator-remove-criterion.patch src/phf-generator/debian/patches/remove-criterion.patch
echo "remove-criterion.patch" > src/phf-generator/debian/patches/series

build_rust_libs(){
  rust_lib=$1
  repackage_name=$2
  patch_name=$3
  vendor=$4

  rm -rf ./build/*
  # Prepare patch for ./repackage.sh script
  cp -r "./src/${rust_lib}/" "/tmp/tmp_${rust_lib}"
  if [[ $patch_name == "none" ]]; then
    rm -rf "./src/${rust_lib}/debian/patches/"
    rm -rf "./src/${rust_lib}/debian/patches_*/"
    ./repackage.sh ${repackage_name}
  elif [[ $patch_name == "patches" ]]; then
    rm -rf "./src/${rust_lib}/debian/patches_*/"
    ./repackage.sh ${repackage_name}
  else
    rm -rf "./src/${rust_lib}/debian/patches/"
    mv "./src/${rust_lib}/debian/${patch_name}/" "./src/${rust_lib}/debian/patches"
    rm -rf "./src/${rust_lib}/debian/patches_*/"
    ./repackage.sh ${repackage_name}
  fi
  rm -rf "./src/${rust_lib}/"
  mv "/tmp/tmp_${rust_lib}" "./src/${rust_lib}"
  # Build librust package
  (
    cd ./build/${rust_lib}/;
    yes | mk-build-deps \
      --install \
      --tool 'apt-get -o APT::Get::Remove=false --yes' && \
    dpkg-buildpackage -b -us -uc -Pnocheck
  )
  mkdir -p /tmp/${PKGNAME}-temp
  mkdir -p ./deb/
  for deb_pkg in $(find $(pwd)/build/ -name "*.deb"); do
    cp ${deb_pkg} "/tmp/${PKGNAME}-temp/"
    cp ${deb_pkg} "./deb/"
  done
  apt install --reinstall -y --allow-downgrades --no-remove /tmp/${PKGNAME}-temp/*.deb || return $? &&
  rm -rf /tmp/${PKGNAME}-temp

  echo "Build finished for rust library ${repackage_name}..."
}

TOTAL=${#RUST_LIBS[@]}
CURRENT=0
for entry in "${RUST_LIBS[@]}"; do
  IFS=':' read -r \
    rust_lib \
    repackage_name \
    patch_name \
    vendor \
    <<< "$entry"
  CURRENT=$((CURRENT + 1))
  print_progress ${TOTAL} ${CURRENT} "${repackage_name}"
  if [ ! -t 1 ]; then
    log_file=$(mktemp)
    if ! build_rust_libs "${rust_lib}" "${repackage_name}" "${patch_name}" "${vendor}" > "$log_file" 2>&1; then
      echo "ERROR: build_rust_libs failed for ${rust_lib}" >&2
      cat "$log_file" >&2
      rm -f "$log_file"
      exit 1
    fi
    rm -f "$log_file"
  else
    if ! build_rust_libs "${rust_lib}" "${repackage_name}" "${patch_name}" "${vendor}"; then
      echo "ERROR: build_rust_libs failed for ${rust_lib}" >&2
      exit 1
    fi
  fi
done

# expose the built debs to packages/build.sh, which collects *.deb from
# below this package's own directory
mkdir -p $SCRIPT_DIR/deb/
for deb_pkg in $(find $(pwd)/deb/ -name "*.deb"); do
  cp ${deb_pkg} "$SCRIPT_DIR/deb/"
done
