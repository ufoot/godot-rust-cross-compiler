#!/bin/sh
#
# Makes the official (x86_64-only) Android NDK usable on an arm64 Linux host.
#
# Google does not ship linux-aarch64 NDK prebuilts, but only the compiler
# binaries are host-specific: the sysroot, crt objects, libunwind.a and
# libclang_rt.builtins-*-android.a are target files. This script:
#
#   1. removes the x86_64 host binaries from prebuilt/linux-x86_64,
#      keeping sysroot/ and the clang resource dir (lib/clang/<major>),
#   2. creates prebuilt/linux-aarch64/bin with <triple><api>-clang wrappers
#      that call the distro clang of the same LLVM major version, pointed at
#      the NDK sysroot and resource dir, linking with lld.
#
# The resulting layout mirrors the official one, so linker paths only differ
# by the host tag (linux-aarch64 instead of linux-x86_64).
#
# Usage: android-ndk-arm64-host.sh <ndk-root>
# LLVM_BIN overrides the distro LLVM bin dir (default /usr/lib/llvm-<major>/bin).

set -eu

NDK_ROOT=$1

X86_DIR=$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64
ARM_DIR=$NDK_ROOT/toolchains/llvm/prebuilt/linux-aarch64

# The NDK clang resource dir is named after its LLVM major version.
LLVM_MAJOR=$(ls "$X86_DIR/lib/clang")
case "$LLVM_MAJOR" in
    ''|*[!0-9]*)
        echo "Unexpected NDK clang resource dirs: $LLVM_MAJOR" >&2
        exit 1
        ;;
esac

LLVM_BIN=${LLVM_BIN:-/usr/lib/llvm-$LLVM_MAJOR/bin}
for tool in clang ld.lld llvm-ar; do
    if [ ! -x "$LLVM_BIN/$tool" ]; then
        echo "NDK uses LLVM $LLVM_MAJOR but $LLVM_BIN/$tool is missing." >&2
        echo "Install clang-$LLVM_MAJOR, lld-$LLVM_MAJOR and llvm-$LLVM_MAJOR." >&2
        exit 1
    fi
done

# 1. Drop x86_64 host binaries, keep target files.
find "$X86_DIR" -mindepth 1 -maxdepth 1 ! -name sysroot ! -name lib -exec rm -rf {} +
find "$X86_DIR/lib" -mindepth 1 -maxdepth 1 ! -name clang -exec rm -rf {} +
rm -rf "$X86_DIR/lib/clang/$LLVM_MAJOR/bin"

# 2. arm64 host overlay.
mkdir -p "$ARM_DIR/bin" "$ARM_DIR/lib/clang"
ln -sfn ../linux-x86_64/sysroot "$ARM_DIR/sysroot"
ln -sfn "../../../linux-x86_64/lib/clang/$LLVM_MAJOR" "$ARM_DIR/lib/clang/$LLVM_MAJOR"

for tool in clang clang++ ld.lld lld llvm-ar llvm-nm llvm-objcopy llvm-objdump llvm-ranlib llvm-readelf llvm-strip; do
    if [ -x "$LLVM_BIN/$tool" ]; then
        ln -sfn "$LLVM_BIN/$tool" "$ARM_DIR/bin/$tool"
    fi
done

# Same triples and API levels as the official NDK wrappers.
APIS=$(ls "$X86_DIR/sysroot/usr/lib/aarch64-linux-android" | grep -E '^[0-9]+$' | sort -n)
for triple in aarch64-linux-android armv7a-linux-androideabi i686-linux-android x86_64-linux-android; do
    for api in $APIS; do
        for driver in clang clang++; do
            wrapper=$ARM_DIR/bin/$triple$api-$driver
            cat > "$wrapper" <<EOF
#!/bin/sh
bin_dir=\$(dirname "\$0")
if [ "\${1:-}" = "-cc1" ]; then
    exec "$LLVM_BIN/$driver" "\$@"
fi
exec "$LLVM_BIN/$driver" --target=$triple$api \\
    --sysroot="\$bin_dir/../sysroot" \\
    -resource-dir="\$bin_dir/../lib/clang/$LLVM_MAJOR" \\
    --ld-path="$LLVM_BIN/ld.lld" \\
    "\$@"
EOF
            chmod a+x "$wrapper"
        done
    done
done

echo "Android NDK arm64 host overlay ready in $ARM_DIR (LLVM $LLVM_MAJOR, API levels:" $APIS")"
