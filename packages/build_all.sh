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
export PACKAGES_PATH="/workspace/packages"

echo "DEBOPT: ${DEBOPT}"
echo "PACKAGES_PATH: $PACKAGES_PATH"
echo

if [[ ${PACKAGE_NAME} == "all" ]]; then
  # Build all packages, except for the ones that are listed in $SKIP_PACKAGES
  for pkg_name in $(extract_subgraph_packages "/workspace/packages/deptree.mmd"); do
    export PKGDIR="${PACKAGES_PATH}/${pkg_name}/${pkg_name}/"
    if [[ -d $PKGDIR ]]; then
      log_build_name $PKGDIR
      sh -c './start.sh'
      # Install the compiled package
      mkdir -p "/tmp/proxmox/${pkg_name}/"
      for i in $(find /workspace/packages/${pkg_name}/ -name '*.deb'); do
        cp $i "/tmp/proxmox/${pkg_name}/";
      done
      apt install -y --allow-downgrades $(ls /tmp/proxmox/${pkg_name}/*.deb | grep -v -- '-dbgsym_\|zfs-dracut_\|-test_');
    fi
  done
else
  # Build one specified package
  export PKGDIR="${PACKAGES_PATH}/${PACKAGE_NAME}/${PACKAGE_NAME}/"
  if [[ -d $PKGDIR ]]; then
    log_build_name $PKGDIR
    sh -c './start.sh'
    mkdir -p "/tmp/proxmox/${PACKAGE_NAME}/"
    for i in $(find /workspace/packages/${PACKAGE_NAME}/ -name '*.deb'); do
      cp $i "/tmp/proxmox/${PACKAGE_NAME}/";
    done
    apt install -y --allow-downgrades $(ls /tmp/proxmox/${PACKAGE_NAME}/*.deb | grep -v -- '-dbgsym_\|zfs-dracut_\|-test_');
  fi
fi

