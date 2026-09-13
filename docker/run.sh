#!/bin/sh
#
# Usage: ./run.sh [amd64|arm64]   (default: host architecture)

set -e

case "${1:-$(uname -m)}" in
    x86_64|amd64) ARCH=amd64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) echo "Unsupported architecture: ${1:-$(uname -m)}" >&2 ; exit 1 ;;
esac

docker run -it --platform linux/$ARCH ufoot/godot-rust-cross-compiler:latest-$ARCH
