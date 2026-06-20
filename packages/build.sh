#!/bin/bash
set -e
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

log_build_name(){
  echo "########################################"
  echo "Building ${1}...";
  echo "########################################"
}

extract_subgraph_packages() {
  local file="${1:-deptree.mmd}"
  awk '/subgraph T0\[/{skip=1} skip{if(/^\s*end\s*$/)skip=0; next} 1' "$file" \
      | grep -vE '^\s*(%%|subgraph|end|graph|---|title)' \
      | grep -E '^\s*\S' \
      | awk '{print $NF}' \
      | awk '!seen[$0]++'
}

export PACKAGE_NAME=""
# Parse named arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --package) PACKAGE_NAME="$2"; shift ;;
    --help)
      echo "Usage: $0 [--package ceph-19]"
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
export PACKAGES_PATH="/workspace/packages"

echo "DEBOPT: ${DEBOPT}"
echo "PACKAGES_PATH: $PACKAGES_PATH"
echo

# Build one specified package
export PKGDIR="${PACKAGES_PATH}/${PACKAGE_NAME}/${PACKAGE_NAME}/"
if [[ -d $PKGDIR ]]; then
  log_build_name $PKGDIR
  sh -c './start.sh'
  mkdir -p "/deb/proxmox/${PACKAGE_NAME}/"
  for i in $(find /workspace/packages/${PACKAGE_NAME}/ -name '*.deb'); do
    cp $i "/deb/proxmox/${PACKAGE_NAME}/";
  done
  rm -rf $PKGDIR/../*
fi

