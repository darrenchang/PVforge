#!/bin/bash

set -e

BUILDKIT_PROGRESS=plain \
docker buildx bake --set "*.output=type=docker,compression=uncompressed,force-compression=true"

