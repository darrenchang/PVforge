#!/bin/bash

set -e

export DEBIAN_APT="http://mirrors.ustc.edu.cn"

# Parse named arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --debian_apt) DEBIAN_APT="$2"; shift ;;
        --help)
            echo "Usage: $0 [--apt_proxy \"http://mirrors.ustc.edu.cn\"]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

docker buildx bake
docker run --rm -d --name pxvirt_builder pvebuilder /bin/sh -c "sleep infinity";
docker cp ./ pxvirt_builder:/pxvirt
docker exec -ti pxvirt_builder bash -c '/pxvirt/packages/build_all.sh';
docker pxvirt_builder:/logs/ ./
# docker stop pxvirt_builder;

