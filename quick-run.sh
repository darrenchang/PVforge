#!/bin/bash

set -e

export BUILDER_CONTAINER=pve_builder;
export PACKAGE_NAME=proxmox-kernel-helper

# Parse named arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --builder_name) export BUILDER_CONTAINER="$2"; shift ;;
        --package_name) export PACKAGE_NAME="$2"; shift ;;
        --help)
            echo "Usage: $0 [--builder_name \"pve_builder\"]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

docker exec -ti ${BUILDER_CONTAINER} bash -c "rm -rf /tmp/${PACKAGE_NAME}*";
docker exec -ti ${BUILDER_CONTAINER} bash -c "rm -rf /workspace/packages/${PACKAGE_NAME}/";
docker exec -ti ${BUILDER_CONTAINER} bash -c "rm -f /workspace/packages/build.sh";
docker cp ./packages/${PACKAGE_NAME}/ ${BUILDER_CONTAINER}:/workspace/packages/${PACKAGE_NAME}/;
docker cp ./packages/build.sh ${BUILDER_CONTAINER}:/workspace/packages/build.sh;
docker exec -ti ${BUILDER_CONTAINER} bash -c "/workspace/packages/build.sh --package ${PACKAGE_NAME}"

