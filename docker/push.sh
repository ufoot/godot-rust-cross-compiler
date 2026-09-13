#!/bin/sh
#
# Usage: ./push.sh [amd64|arm64]   (default: host architecture)

set -e

VERSION=0.3.1
case "${1:-$(uname -m)}" in
    x86_64|amd64) ARCH=amd64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) echo "Unsupported architecture: ${1:-$(uname -m)}" >&2 ; exit 1 ;;
esac

docker push ufoot/godot-rust-cross-compiler:$VERSION-$ARCH
docker push ufoot/godot-rust-cross-compiler:latest-$ARCH
