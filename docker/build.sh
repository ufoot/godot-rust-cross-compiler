#!/bin/sh
#
# Usage: ./build.sh [amd64|arm64]   (default: host architecture)
#
# Images are built natively per architecture and tagged <version>-<arch>;
# cross-building the other architecture works through QEMU but is very slow.

set -e

VERSION=0.3.1
case "${1:-$(uname -m)}" in
    x86_64|amd64) ARCH=amd64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) echo "Unsupported architecture: ${1:-$(uname -m)}" >&2 ; exit 1 ;;
esac

cd "$(dirname "$0")"
docker build --platform linux/$ARCH . -t ufoot/godot-rust-cross-compiler:$VERSION-$ARCH
docker tag ufoot/godot-rust-cross-compiler:$VERSION-$ARCH ufoot/godot-rust-cross-compiler:latest-$ARCH
