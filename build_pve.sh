#!/bin/bash

set -e

BUILDKIT_PROGRESS=plain \
docker buildx bake

