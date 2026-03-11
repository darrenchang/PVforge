#!/bin/bash
set -e

log_build_name(){
  echo "####################"
  echo "Building ${1}...";
  echo "####################"
}

export PACKAGE_NAME="all"

# Parse named arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --package) PACKAGE_NAME="$2"; shift ;;
        --help)
            echo "Usage: $0 [--package all|ceph-19]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

export DEBOPT="dd"
export PACKAGES_PATH="/pxvirt/packages"
git config --global --add safe.directory ${PACKAGES_PATH}/..

echo "DEBOPT: ${DEBOPT}"
echo "PACKAGES_PATH: $PACKAGES_PATH"
echo

# Packages that doesn't need to be built
SKIP_PACKAGES=("cargo" "debcargo-conf" "ceph-17" "ceph-18")

if [[ ${PACKAGE_NAME} == "all" ]]; then
  # Build all packages, except for the ones that are listed in $SKIP_PACKAGES
  for pkg_name in $(ls ${PACKAGES_PATH}/); do
    export SKIP=0
    for skip_package in "${SKIP_PACKAGES[@]}"; do
      if [ $skip_package == $pkg_name ]; then
        SKIP=1
      fi
    done
    export PKGDIR="${PACKAGES_PATH}/${pkg_name}/${pkg_name}/"
    if [[ -d $PKGDIR && $SKIP -eq 0 ]]; then
      git config --global --add safe.directory $PKGDIR
      log_build_name $PKGDIR
      sh -c '/start.sh'
    fi
  done
else
  # Build one specified package
  export PKGDIR="${PACKAGES_PATH}/${PACKAGE_NAME}/${PACKAGE_NAME}/"
  if [[ -d $PKGDIR ]]; then
    git config --global --add safe.directory $PKGDIR
    log_build_name $PKGDIR
    sh -c '/start.sh'
  fi
fi

