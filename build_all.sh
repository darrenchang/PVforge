#!/bin/bash

set -e

export BUILDER_NAME="pve_builder"

# Parse named arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --builder_name) export BUILDER_NAME="$2"; shift ;;
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

docker buildx bake && \
docker run --rm -d --name ${BUILDER_NAME} pvebuilder /bin/sh -c "sleep infinity" && \
echo "Copying $(du -sh ./) to the container ${BUILDER_NAME}..." && \
docker exec ${BUILDER_NAME} bash -c "mkdir /pxvirt/" && \
tar -cf - ./ | pv -f -s $(du -sb ./ | cut -f1) | docker exec -i ${BUILDER_NAME} bash -c "tar -xf - -C /pxvirt/"
# docker exec -ti ${BUILDER_NAME} bash -c '/pxvirt/packages/build_all.sh';
# docker cp ${BUILDER_NAME}:/logs/ ./
# docker stop ${BUILDER_NAME};

