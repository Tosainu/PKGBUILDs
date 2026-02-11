#!/usr/bin/env sh

set -e
set -u

version=$(grep -Po '(?<=^pkgver=)[0-9.]+$' PKGBUILD | head -n1)
echo "version: $version"

podman build \
  --platform=linux/arm64 \
  --network=none \
  --pull=always \
  --stdin \
  "--build-arg=LINUX_VERSION=$version" \
  --output=type=local,dest=. \
  --target=oldconfig \
  .

updpkgsums
