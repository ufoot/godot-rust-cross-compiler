# To use this, define GRCC_GODOT_RUST_LIB_NAME then include it.
# Example:
#
# ---8<----------------------
# GRCC_GAME_PKG_NAME=cctoy
# include grcc.mk
# ---8<----------------------
#
# This will build cctoy.dll, libcctoy.dylib, libcctoy.so
#
# More info on:
# https://github.com/ufoot/godot-rust-cross-compiler
#
# Updated for Godot 4 and GDExtension (grcc 0.3.1)
#
# Most settings below use ?= so a project Makefile can override them before
# the include, e.g. GRCC_DOCKER_IMAGE, GRCC_GODOT_HEADLESS, GRCC_EXPORT_PRESET_*.

.PHONY: grcc-all
.PHONY: grcc-test
.PHONY: grcc-debug
.PHONY: grcc-release
.PHONY: grcc-clean
.PHONY: grcc-doc
.PHONY: grcc-clean-prepare
.PHONY: grcc-lib-all
.PHONY: grcc-lib-windows
.PHONY: grcc-lib-windows-x64
.PHONY: grcc-lib-windows-arm64
.PHONY: grcc-lib-android
.PHONY: grcc-lib-android-arm64
.PHONY: grcc-lib-android-arm32
.PHONY: grcc-lib-android-x64
.PHONY: grcc-lib-android-x32
.PHONY: grcc-lib-macosx
.PHONY: grcc-lib-macosx-x64
.PHONY: grcc-lib-macosx-arm64
.PHONY: grcc-lib-macosx-universal
.PHONY: grcc-lib-linux
.PHONY: grcc-lib-linux-x64
.PHONY: grcc-lib-linux-arm64
.PHONY: grcc-lib-wasm
.PHONY: grcc-lib-wasm-threads
.PHONY: grcc-lib-wasm-nothreads
.PHONY: grcc-native
.PHONY: grcc-cross
.PHONY: grcc-copy-local
.PHONY: grcc-copy-if-exists
.PHONY: grcc-copy-all
.PHONY: grcc-copy-windows
.PHONY: grcc-copy-windows-x64
.PHONY: grcc-copy-windows-arm64
.PHONY: grcc-copy-android
.PHONY: grcc-copy-macosx
.PHONY: grcc-copy-linux
.PHONY: grcc-copy-linux-x64
.PHONY: grcc-copy-linux-arm64
.PHONY: grcc-copy-wasm
.PHONY: grcc-pkg-all
.PHONY: grcc-pkg-windows
.PHONY: grcc-pkg-windows-x64
.PHONY: grcc-pkg-windows-arm64
.PHONY: grcc-installer-windows
.PHONY: grcc-installer-windows-x64
.PHONY: grcc-installer-windows-arm64
.PHONY: grcc-pkg-android
.PHONY: grcc-pkg-android-aab
.PHONY: grcc-sign-android-aab
.PHONY: grcc-check-aab-host
.PHONY: grcc-skip-android-aab
.PHONY: grcc-check-android-signing
.PHONY: grcc-pkg-macosx
.PHONY: grcc-pkg-linux
.PHONY: grcc-pkg-linux-x64
.PHONY: grcc-pkg-linux-arm64
.PHONY: grcc-pkg-wasm
.PHONY: grcc-pkg-source
.PHONY: grcc-dmg-macosx

grcc-all: grcc-native

grcc-native: grcc-test grcc-debug grcc-copy-local

grcc-cross: grcc-test grcc-lib-all grcc-copy-if-exists

grcc-export: grcc-test grcc-pkg-all grcc-installer-windows grcc-dmg-macosx
	@$(if $(filter yes,$(GRCC_AAB_POSSIBLE)),true,echo "$$GRCC_AAB_SKIPPED_NOTICE")

grcc-lib-all: grcc-lib-windows grcc-lib-android grcc-lib-macosx grcc-lib-linux grcc-lib-wasm

GRCC_WINDOWS_X64_TARGET=x86_64-pc-windows-gnullvm
GRCC_WINDOWS_ARM64_TARGET=aarch64-pc-windows-gnullvm
GRCC_ANDROID_ARM64_TARGET=aarch64-linux-android
GRCC_ANDROID_ARM32_TARGET=armv7-linux-androideabi
GRCC_ANDROID_X64_TARGET=x86_64-linux-android
GRCC_ANDROID_X32_TARGET=i686-linux-android
GRCC_MACOSX_X64_TARGET=x86_64-apple-darwin
GRCC_MACOSX_ARM64_TARGET=aarch64-apple-darwin
GRCC_LINUX_X64_TARGET=x86_64-unknown-linux-gnu
GRCC_LINUX_ARM64_TARGET=aarch64-unknown-linux-gnu
# Godot loads web GDExtensions as Emscripten side modules.
GRCC_WASM_TARGET=wasm32-unknown-emscripten

# This must be defined
ifeq (,$(GRCC_GAME_PKG_NAME))
GRCC_GAME_PKG_NAME=please-define-GRCC_GAME_PKG_NAME
endif
# This should be defined, while not strictly mandatory, version matters.
ifeq (,$(GRCC_GAME_PKG_VERSION))
GRCC_GAME_PKG_VERSION=0.0.1
endif

# Default values provided for the following, based on package info.
ifeq (,$(GRCC_GODOT_RUST_LIB_NAME))
GRCC_GODOT_RUST_LIB_NAME=$(GRCC_GAME_PKG_NAME)
endif
ifeq (,$(GRCC_GAME_REPO_NAME))
GRCC_GAME_REPO_NAME=$(GRCC_GAME_PKG_NAME)
endif
ifeq (,$(GRCC_GAME_REPO_VERSION))
GRCC_GAME_REPO_VERSION=$(GRCC_GAME_PKG_VERSION)
endif

# The image is published per architecture (<version>-amd64, <version>-arm64);
# pick the one matching the host so everything runs natively. Override
# GRCC_DOCKER_ARCH=amd64 on an arm64 host to force emulation.
GRCC_HOST_ARCH := $(shell uname -m)
ifneq (,$(filter aarch64 arm64,$(GRCC_HOST_ARCH)))
GRCC_DOCKER_ARCH?=arm64
else
GRCC_DOCKER_ARCH?=amd64
endif
GRCC_DOCKER_VERSION?=0.3.1
GRCC_DOCKER_IMAGE?=ufoot/godot-rust-cross-compiler:$(GRCC_DOCKER_VERSION)-$(GRCC_DOCKER_ARCH)

# Android signing keys live in the project, outside export/ (removed by
# grcc-clean) and out of git and source packages: $(GRCC_KEYSTORE_DIR)/.
# - release keystore: used when it exists AND its password is given, from the
#   environment only: GRCC_ANDROID_RELEASE_KEYSTORE_PASSWORD (alias in
#   GRCC_ANDROID_RELEASE_KEYSTORE_USER). APKs and the AAB upload signature use it.
# - debug keystore: otherwise. A project copy keeps the same signature across
#   image rebuilds (the image one is regenerated at each build).
# - the image's own debug keystore if the project has none.
# Godot reads GODOT_ANDROID_KEYSTORE_{RELEASE,DEBUG}_{PATH,USER,PASSWORD}; they
# are passed to Docker by name (values never echoed) and can still be set
# directly in the environment, which overrides all of the above.
GRCC_KEYSTORE_DIR?=.keystore
GRCC_ANDROID_DEBUG_KEYSTORE?=$(GRCC_KEYSTORE_DIR)/debug.keystore
GRCC_ANDROID_DEBUG_KEYSTORE_USER?=androiddebugkey
GRCC_ANDROID_DEBUG_KEYSTORE_PASSWORD?=android
GRCC_ANDROID_RELEASE_KEYSTORE?=$(GRCC_KEYSTORE_DIR)/release.keystore
GRCC_ANDROID_RELEASE_KEYSTORE_USER?=
GRCC_ANDROID_RELEASE_KEYSTORE_PASSWORD?=

# Paths as seen by Godot: the project is /build in the container.
ifeq (,$(wildcard /opt/godot-rust-cross-compiler.txt))
GRCC_BUILD_ROOT=/build
else
GRCC_BUILD_ROOT=$(CURDIR)
endif

ifneq (,$(wildcard $(GRCC_ANDROID_DEBUG_KEYSTORE)))
GRCC_ANDROID_DEBUG_SIGNING_PATH=$(GRCC_BUILD_ROOT)/$(GRCC_ANDROID_DEBUG_KEYSTORE)
GRCC_ANDROID_DEBUG_SIGNING_DESC=project debug keystore $(GRCC_ANDROID_DEBUG_KEYSTORE)
else
GRCC_ANDROID_DEBUG_SIGNING_PATH=/root/.android/debug.keystore
GRCC_ANDROID_DEBUG_SIGNING_DESC=image debug keystore (no $(GRCC_ANDROID_DEBUG_KEYSTORE))
endif
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH?=$(GRCC_ANDROID_DEBUG_SIGNING_PATH)
export GODOT_ANDROID_KEYSTORE_DEBUG_USER?=$(GRCC_ANDROID_DEBUG_KEYSTORE_USER)
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD?=$(GRCC_ANDROID_DEBUG_KEYSTORE_PASSWORD)

ifneq (,$(and $(wildcard $(GRCC_ANDROID_RELEASE_KEYSTORE)),$(GRCC_ANDROID_RELEASE_KEYSTORE_PASSWORD)))
GRCC_ANDROID_SIGNING=release
GRCC_ANDROID_SIGNING_DESC=release keystore $(GRCC_ANDROID_RELEASE_KEYSTORE) (alias $(GRCC_ANDROID_RELEASE_KEYSTORE_USER))
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH?=$(GRCC_BUILD_ROOT)/$(GRCC_ANDROID_RELEASE_KEYSTORE)
export GODOT_ANDROID_KEYSTORE_RELEASE_USER?=$(GRCC_ANDROID_RELEASE_KEYSTORE_USER)
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD?=$(GRCC_ANDROID_RELEASE_KEYSTORE_PASSWORD)
else
GRCC_ANDROID_SIGNING=debug
GRCC_ANDROID_SIGNING_DESC=$(GRCC_ANDROID_DEBUG_SIGNING_DESC)
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH?=$(GRCC_ANDROID_DEBUG_SIGNING_PATH)
export GODOT_ANDROID_KEYSTORE_RELEASE_USER?=$(GRCC_ANDROID_DEBUG_KEYSTORE_USER)
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD?=$(GRCC_ANDROID_DEBUG_KEYSTORE_PASSWORD)
endif

# Exports run the Linux Godot editor of the image, which loads the GDExtension
# for its own platform (else: "Can't open dynamic library" and extension classes
# unknown while exporting scenes). Every grcc-pkg-* target builds that lib too.
ifeq (arm64,$(GRCC_DOCKER_ARCH))
GRCC_COPY_EDITOR_LIB=grcc-copy-linux-arm64
else
GRCC_COPY_EDITOR_LIB=grcc-copy-linux-x64
endif

GRCC_DOCKER_SIGNING_ENV=-e GODOT_ANDROID_KEYSTORE_RELEASE_PATH -e GODOT_ANDROID_KEYSTORE_RELEASE_USER -e GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -e GODOT_ANDROID_KEYSTORE_DEBUG_PATH -e GODOT_ANDROID_KEYSTORE_DEBUG_USER -e GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD

ifeq (,$(wildcard /opt/godot-rust-cross-compiler.txt))
GRCC_USE_DOCKER=yes
GRCC_INVOKE_DOCKER_RUST=install -d $(GRCC_CROSS_COMPILER_CACHE_DIR)/git && install -d $(GRCC_CROSS_COMPILER_CACHE_DIR)/registry && docker run --platform linux/$(GRCC_DOCKER_ARCH) -v $$(pwd):/build -v$$(realpath $(GRCC_CROSS_COMPILER_CACHE_DIR)/git):/root/.cargo/git -v$$(realpath $(GRCC_CROSS_COMPILER_CACHE_DIR)/registry):/root/.cargo/registry
GRCC_INVOKE_DOCKER_GODOT_EXPORT=docker run --platform linux/$(GRCC_DOCKER_ARCH) -v $$(pwd):/build $(GRCC_DOCKER_SIGNING_ENV) $(GRCC_DOCKER_IMAGE)
# Same, plus a persistent Gradle home (wrapper distribution + Maven dependencies),
# on the image chosen for AABs (see GRCC_AAB_EMULATE).
GRCC_INVOKE_DOCKER_GODOT_GRADLE=install -d $(GRCC_CROSS_COMPILER_CACHE_DIR)/gradle && docker run --platform linux/$(GRCC_AAB_DOCKER_ARCH) -v $$(pwd):/build -v$$(realpath $(GRCC_CROSS_COMPILER_CACHE_DIR)/gradle):/root/.gradle $(GRCC_DOCKER_SIGNING_ENV) $(GRCC_AAB_DOCKER_IMAGE)
else
GRCC_USE_DOCKER=no
GRCC_INVOKE_DOCKER_GODOT_EXPORT=
GRCC_INVOKE_DOCKER_GODOT_GRADLE=
endif

# Google Play needs an Android App Bundle, built by Godot's Gradle template.
# Gradle's aapt2 only exists for x86_64 Linux, so the AAB export always runs in
# the amd64 image: natively on amd64 hosts, emulated (Rosetta/QEMU) on arm64
# hosts. Only that export step is emulated; libraries and signing stay native.
# GRCC_AAB_EMULATE=no keeps arm64 hosts native, which skips the AAB.
GRCC_AAB_EMULATE?=yes
ifeq (yes,$(GRCC_AAB_EMULATE))
GRCC_AAB_DOCKER_ARCH=amd64
else
GRCC_AAB_DOCKER_ARCH=$(GRCC_DOCKER_ARCH)
endif
ifeq ($(GRCC_AAB_DOCKER_ARCH),$(GRCC_DOCKER_ARCH))
GRCC_AAB_DOCKER_IMAGE?=$(GRCC_DOCKER_IMAGE)
else
GRCC_AAB_DOCKER_IMAGE?=ufoot/godot-rust-cross-compiler:$(GRCC_DOCKER_VERSION)-$(GRCC_AAB_DOCKER_ARCH)
endif
# The editor running the AAB export loads the GDExtension for its own arch.
ifeq (amd64,$(GRCC_AAB_DOCKER_ARCH))
GRCC_AAB_EDITOR_LIB=grcc-copy-linux-x64
else
GRCC_AAB_EDITOR_LIB=grcc-copy-linux-arm64
endif
# Possible when the export runs in an amd64 container, or directly on an amd64
# image (no Docker switch is possible from inside an image).
ifeq (amd64,$(GRCC_AAB_DOCKER_ARCH))
ifeq (yes,$(GRCC_USE_DOCKER))
GRCC_AAB_POSSIBLE=yes
else
GRCC_AAB_POSSIBLE=$(if $(filter amd64,$(GRCC_DOCKER_ARCH)),yes,no)
endif
else
GRCC_AAB_POSSIBLE=no
endif
ifeq (yes,$(GRCC_AAB_POSSIBLE))
GRCC_PKG_ANDROID_AAB=grcc-sign-android-aab
else
GRCC_PKG_ANDROID_AAB=grcc-skip-android-aab
endif

GRCC_NATIVE_DEBUG_WINDOWS_SRC=./rust/target/debug/$(GRCC_GODOT_RUST_LIB_NAME).dll
GRCC_NATIVE_DEBUG_MACOSX_SRC=./rust/target/debug/lib$(GRCC_GODOT_RUST_LIB_NAME).dylib
GRCC_NATIVE_DEBUG_LINUX_SRC=./rust/target/debug/lib$(GRCC_GODOT_RUST_LIB_NAME).so

GRCC_GODOT_GDNATIVE_DIR=./godot/gdnative
GRCC_WINDOWS_X64_SRC=./rust/target/$(GRCC_WINDOWS_X64_TARGET)/release/$(GRCC_GODOT_RUST_LIB_NAME).dll
GRCC_WINDOWS_X64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/windows/$(GRCC_WINDOWS_X64_TARGET)/
GRCC_WINDOWS_ARM64_SRC=./rust/target/$(GRCC_WINDOWS_ARM64_TARGET)/release/$(GRCC_GODOT_RUST_LIB_NAME).dll
GRCC_WINDOWS_ARM64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/windows/$(GRCC_WINDOWS_ARM64_TARGET)/
GRCC_ANDROID_ARM64_SRC=./rust/target/$(GRCC_ANDROID_ARM64_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_ANDROID_ARM64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/android/$(GRCC_ANDROID_ARM64_TARGET)/
GRCC_ANDROID_ARM32_SRC=./rust/target/$(GRCC_ANDROID_ARM32_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_ANDROID_ARM32_DST=$(GRCC_GODOT_GDNATIVE_DIR)/android/$(GRCC_ANDROID_ARM32_TARGET)/
GRCC_ANDROID_X64_SRC=./rust/target/$(GRCC_ANDROID_X64_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_ANDROID_X64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/android/$(GRCC_ANDROID_X64_TARGET)/
GRCC_ANDROID_X32_SRC=./rust/target/$(GRCC_ANDROID_X32_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_ANDROID_X32_DST=$(GRCC_GODOT_GDNATIVE_DIR)/android/$(GRCC_ANDROID_X32_TARGET)/
GRCC_MACOSX_X64_SRC=./rust/target/$(GRCC_MACOSX_X64_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).dylib
GRCC_MACOSX_X64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/macosx/$(GRCC_MACOSX_X64_TARGET)/
GRCC_MACOSX_ARM64_SRC=./rust/target/$(GRCC_MACOSX_ARM64_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).dylib
GRCC_MACOSX_ARM64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/macosx/$(GRCC_MACOSX_ARM64_TARGET)/
# A macOS "universal" export bundles every matching library under its file
# name, so x86_64 and arm64 dylibs with the same name would clash. Merge them
# with lipo and point macos.debug/macos.release (no arch tag) at this one.
GRCC_MACOSX_UNIVERSAL_DST=$(GRCC_GODOT_GDNATIVE_DIR)/macosx/universal/
GRCC_MACOSX_UNIVERSAL_LIB=$(GRCC_MACOSX_UNIVERSAL_DST)lib$(GRCC_GODOT_RUST_LIB_NAME).dylib
GRCC_LINUX_X64_SRC=./rust/target/$(GRCC_LINUX_X64_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_LINUX_X64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/linux/$(GRCC_LINUX_X64_TARGET)/
GRCC_LINUX_ARM64_SRC=./rust/target/$(GRCC_LINUX_ARM64_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_LINUX_ARM64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/linux/$(GRCC_LINUX_ARM64_TARGET)/
# Web needs two builds of the same crate: a threaded one (Godot "Thread Support"
# on, needs cross-origin isolation headers) and a nothreads one (runs on any
# static host). They use separate target dirs so they don't invalidate each
# other, and Godot picks <lib>.threads.wasm or <lib>.wasm at export time.
# The crate must define: [features] nothreads = ["godot/experimental-wasm-nothreads"]
GRCC_GODOT_RUST_CRATE_NAME?=$(GRCC_GODOT_RUST_LIB_NAME)
GRCC_WASM_NOTHREADS_FEATURE?=nothreads
GRCC_WASM_THREADS_TARGET_DIR=target/wasm-threads
GRCC_WASM_NOTHREADS_TARGET_DIR=target/wasm-nothreads
GRCC_WASM_THREADS_SRC=./rust/$(GRCC_WASM_THREADS_TARGET_DIR)/$(GRCC_WASM_TARGET)/release/$(GRCC_GODOT_RUST_LIB_NAME).wasm
GRCC_WASM_NOTHREADS_SRC=./rust/$(GRCC_WASM_NOTHREADS_TARGET_DIR)/$(GRCC_WASM_TARGET)/release/$(GRCC_GODOT_RUST_LIB_NAME).wasm
GRCC_WASM_DST=$(GRCC_GODOT_GDNATIVE_DIR)/web/$(GRCC_WASM_TARGET)/
GRCC_WASM_RUSTFLAGS_COMMON=-C link-args=-sSIDE_MODULE=2 -C llvm-args=-enable-emscripten-cxx-exceptions=0 -Z default-visibility=hidden -Z link-native-libraries=no -Z emscripten-wasm-eh=false
GRCC_WASM_RUSTFLAGS_THREADS=-C link-args=-pthread -C target-feature=+atomics $(GRCC_WASM_RUSTFLAGS_COMMON)
# Pinned nightly: -Zemscripten-wasm-eh=false was removed from rustc on 2026-06-04
# (rust-lang/rust#156928), and Godot web templates still use JS exception
# handling, so newer nightlies produce side modules Godot cannot load
# ("__cpp_exception is not a Tag"). See godot-rust/gdext#1119.
GRCC_WASM_NIGHTLY?=nightly-2026-06-01
GRCC_WASM_CARGO=cargo +$(GRCC_WASM_NIGHTLY) build -Zbuild-std --release --target $(GRCC_WASM_TARGET) -p $(GRCC_GODOT_RUST_CRATE_NAME)

GRCC_CROSS_COMPILER_CACHE_DIR=target/cross-compiler-cache

GRCC_WINDOWS_MINGW_HEADERS=/opt/llvm-mingw/x86_64-w64-mingw32/include
GRCC_MACOSX_SDK_HEADERS=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX26.1.sdk/usr/include
GRCC_MACOSX_SDK_CC_X64=/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin25.1-clang
GRCC_MACOSX_SDK_CC_ARM64=/opt/macosx-build-tools/cross-compiler/bin/aarch64-apple-darwin25.1-clang
GRCC_MACOSX_LIPO?=/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin25.1-lipo

GRCC_EXPORT_DIR=export
GRCC_EXPORT_WINDOWS_X64_PKG=$(GRCC_GAME_PKG_NAME)-windows-x64-v$(GRCC_GAME_PKG_VERSION)
GRCC_EXPORT_WINDOWS_ARM64_PKG=$(GRCC_GAME_PKG_NAME)-windows-arm64-v$(GRCC_GAME_PKG_VERSION)
GRCC_EXPORT_ANDROID_PKG=$(GRCC_GAME_PKG_NAME)-android-v$(GRCC_GAME_PKG_VERSION)
GRCC_EXPORT_ANDROID_AAB_UNSIGNED=$(GRCC_EXPORT_ANDROID_PKG)-unsigned.aab
GRCC_EXPORT_ANDROID_AAB=$(GRCC_EXPORT_ANDROID_PKG).aab
GRCC_EXPORT_MACOSX_PKG=$(GRCC_GAME_PKG_NAME)-macosx-v$(GRCC_GAME_PKG_VERSION)
GRCC_EXPORT_LINUX_X64_PKG=$(GRCC_GAME_PKG_NAME)-linux-x64-v$(GRCC_GAME_PKG_VERSION)
GRCC_EXPORT_LINUX_ARM64_PKG=$(GRCC_GAME_PKG_NAME)-linux-arm64-v$(GRCC_GAME_PKG_VERSION)
GRCC_EXPORT_WASM_PKG=$(GRCC_GAME_PKG_NAME)-web-v$(GRCC_GAME_PKG_VERSION)

# Windows installer settings
GRCC_INSTALLER_TEMPLATE=/opt/grcc/installer.nsi.template
GRCC_INSTALLER_WINDOWS_X64=$(GRCC_GAME_PKG_NAME)-windows-x64-v$(GRCC_GAME_PKG_VERSION)-setup.exe
GRCC_INSTALLER_WINDOWS_ARM64=$(GRCC_GAME_PKG_NAME)-windows-arm64-v$(GRCC_GAME_PKG_VERSION)-setup.exe
GRCC_GAME_PUBLISHER?=Unknown Publisher

# macOS DMG settings
GRCC_DMG_MACOSX=$(GRCC_GAME_PKG_NAME)-macosx-v$(GRCC_GAME_PKG_VERSION).dmg
GRCC_DMG_VOLUME_NAME=$(GRCC_GAME_PKG_NAME)

# Godot 4 uses --headless instead of separate headless binary
GRCC_GODOT_HEADLESS?=godot --headless

grcc-test:
	cd rust && cargo test

grcc-debug:
	cd rust && cargo build

grcc-release:
	cd rust && cargo build --release

grcc-clean: grcc-clean-prepare
	rm -rf export

grcc-doc:
	cd rust && cargo doc --workspace --offline

grcc-clean-prepare:
	rm -rf $(GRCC_GODOT_GDNATIVE_DIR)
	cd rust && (cargo clean || rm -rf ./target || sudo rm -rf ./target)


grcc-lib-windows: grcc-lib-windows-x64 grcc-lib-windows-arm64

grcc-lib-windows-x64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) -e C_INCLUDE_PATH=$(GRCC_WINDOWS_MINGW_HEADERS) $(GRCC_DOCKER_IMAGE) cargo build --release --target $(GRCC_WINDOWS_X64_TARGET)
else
	export C_INCLUDE_PATH=$(GRCC_WINDOWS_MINGW_HEADERS) && cd rust && cargo build --release --target $(GRCC_WINDOWS_X64_TARGET)
endif

grcc-lib-windows-arm64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) $(GRCC_DOCKER_IMAGE) cargo build --release --target $(GRCC_WINDOWS_ARM64_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_WINDOWS_ARM64_TARGET)
endif

grcc-lib-android: grcc-lib-android-arm64 grcc-lib-android-arm32 grcc-lib-android-x64 grcc-lib-android-x32

grcc-lib-android-arm64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) $(GRCC_DOCKER_IMAGE) cargo build --release --target $(GRCC_ANDROID_ARM64_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_ANDROID_ARM64_TARGET)
endif

grcc-lib-android-arm32:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) $(GRCC_DOCKER_IMAGE) cargo build --release --target $(GRCC_ANDROID_ARM32_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_ANDROID_ARM32_TARGET)
endif

grcc-lib-android-x64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) $(GRCC_DOCKER_IMAGE) cargo build --release --target $(GRCC_ANDROID_X64_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_ANDROID_X64_TARGET)
endif

grcc-lib-android-x32:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) $(GRCC_DOCKER_IMAGE) cargo build --release --target $(GRCC_ANDROID_X32_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_ANDROID_X32_TARGET)
endif

grcc-lib-macosx: grcc-lib-macosx-x64 grcc-lib-macosx-arm64 grcc-lib-macosx-universal

grcc-lib-macosx-x64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) -e CC=$(GRCC_MACOSX_SDK_CC_X64) -e C_INCLUDE_PATH=$(GRCC_MACOSX_SDK_HEADERS) $(GRCC_DOCKER_IMAGE) cargo build --release --target $(GRCC_MACOSX_X64_TARGET)
else
	export CC=$(GRCC_MACOSX_SDK_CC_X64) C_INCLUDE_PATH=$(GRCC_MACOSX_SDK_HEADERS) && cd rust && cargo build --release --target $(GRCC_MACOSX_X64_TARGET)
endif

grcc-lib-macosx-arm64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) -e CC=$(GRCC_MACOSX_SDK_CC_ARM64) -e C_INCLUDE_PATH=$(GRCC_MACOSX_SDK_HEADERS) $(GRCC_DOCKER_IMAGE) cargo build --release --target $(GRCC_MACOSX_ARM64_TARGET)
else
	export CC=$(GRCC_MACOSX_SDK_CC_ARM64) C_INCLUDE_PATH=$(GRCC_MACOSX_SDK_HEADERS) && cd rust && cargo build --release --target $(GRCC_MACOSX_ARM64_TARGET)
endif

grcc-lib-macosx-universal: grcc-lib-macosx-x64 grcc-lib-macosx-arm64
	install -d $(GRCC_MACOSX_UNIVERSAL_DST)
ifeq (yes,$(GRCC_USE_DOCKER))
	$(GRCC_INVOKE_DOCKER_GODOT_EXPORT) $(GRCC_MACOSX_LIPO) -create $(GRCC_MACOSX_X64_SRC) $(GRCC_MACOSX_ARM64_SRC) -output $(GRCC_MACOSX_UNIVERSAL_LIB)
else
	$(GRCC_MACOSX_LIPO) -create $(GRCC_MACOSX_X64_SRC) $(GRCC_MACOSX_ARM64_SRC) -output $(GRCC_MACOSX_UNIVERSAL_LIB)
endif

grcc-lib-linux: grcc-lib-linux-x64 grcc-lib-linux-arm64

grcc-lib-linux-x64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) $(GRCC_DOCKER_IMAGE) cargo build --release --target $(GRCC_LINUX_X64_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_LINUX_X64_TARGET)
endif

grcc-lib-linux-arm64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) $(GRCC_DOCKER_IMAGE) cargo build --release --target $(GRCC_LINUX_ARM64_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_LINUX_ARM64_TARGET)
endif

grcc-lib-wasm: grcc-lib-wasm-threads grcc-lib-wasm-nothreads

grcc-lib-wasm-threads:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) -e "CARGO_TARGET_WASM32_UNKNOWN_EMSCRIPTEN_RUSTFLAGS=$(GRCC_WASM_RUSTFLAGS_THREADS)" $(GRCC_DOCKER_IMAGE) $(GRCC_WASM_CARGO) --target-dir $(GRCC_WASM_THREADS_TARGET_DIR)
else
	cd rust && CARGO_TARGET_WASM32_UNKNOWN_EMSCRIPTEN_RUSTFLAGS="$(GRCC_WASM_RUSTFLAGS_THREADS)" $(GRCC_WASM_CARGO) --target-dir $(GRCC_WASM_THREADS_TARGET_DIR)
endif

grcc-lib-wasm-nothreads:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) -e "CARGO_TARGET_WASM32_UNKNOWN_EMSCRIPTEN_RUSTFLAGS=$(GRCC_WASM_RUSTFLAGS_COMMON)" $(GRCC_DOCKER_IMAGE) $(GRCC_WASM_CARGO) --target-dir $(GRCC_WASM_NOTHREADS_TARGET_DIR) --features $(GRCC_WASM_NOTHREADS_FEATURE)
else
	cd rust && CARGO_TARGET_WASM32_UNKNOWN_EMSCRIPTEN_RUSTFLAGS="$(GRCC_WASM_RUSTFLAGS_COMMON)" $(GRCC_WASM_CARGO) --target-dir $(GRCC_WASM_NOTHREADS_TARGET_DIR) --features $(GRCC_WASM_NOTHREADS_FEATURE)
endif

grcc-copy-local:
	if (uname -a | grep -i windows) ; then install -d $(GRCC_WINDOWS_X64_DST) && cp $(GRCC_NATIVE_DEBUG_WINDOWS_SRC) $(GRCC_WINDOWS_X64_DST) ; fi
	if (uname -a | grep -i darwin) ; then \
		if (uname -m | grep -i arm64) ; then \
			install -d $(GRCC_MACOSX_ARM64_DST) && cp $(GRCC_NATIVE_DEBUG_MACOSX_SRC) $(GRCC_MACOSX_ARM64_DST) ; \
		else \
			install -d $(GRCC_MACOSX_X64_DST) && cp $(GRCC_NATIVE_DEBUG_MACOSX_SRC) $(GRCC_MACOSX_X64_DST) ; \
		fi ; \
		install -d $(GRCC_MACOSX_UNIVERSAL_DST) && cp $(GRCC_NATIVE_DEBUG_MACOSX_SRC) $(GRCC_MACOSX_UNIVERSAL_DST) ; \
	fi
	if (uname -a | grep -i linux) ; then \
		if (uname -m | grep -iE 'aarch64|arm64') ; then \
			install -d $(GRCC_LINUX_ARM64_DST) && cp $(GRCC_NATIVE_DEBUG_LINUX_SRC) $(GRCC_LINUX_ARM64_DST) ; \
		else \
			install -d $(GRCC_LINUX_X64_DST) && cp $(GRCC_NATIVE_DEBUG_LINUX_SRC) $(GRCC_LINUX_X64_DST) ; \
		fi \
	fi

grcc-copy-if-exists:
	if test -f $(GRCC_WINDOWS_X64_SRC) ; then install -d $(GRCC_WINDOWS_X64_DST) && cp $(GRCC_WINDOWS_X64_SRC) $(GRCC_WINDOWS_X64_DST) ; fi
	if test -f $(GRCC_WINDOWS_ARM64_SRC) ; then install -d $(GRCC_WINDOWS_ARM64_DST) && cp $(GRCC_WINDOWS_ARM64_SRC) $(GRCC_WINDOWS_ARM64_DST) ; fi
	if test -f $(GRCC_ANDROID_ARM64_SRC) ; then install -d $(GRCC_ANDROID_ARM64_DST) && cp $(GRCC_ANDROID_ARM64_SRC) $(GRCC_ANDROID_ARM64_DST) ; fi
	if test -f $(GRCC_ANDROID_ARM32_SRC) ; then install -d $(GRCC_ANDROID_ARM32_DST) && cp $(GRCC_ANDROID_ARM32_SRC) $(GRCC_ANDROID_ARM32_DST) ; fi
	if test -f $(GRCC_ANDROID_X64_SRC) ; then install -d $(GRCC_ANDROID_X64_DST) && cp $(GRCC_ANDROID_X64_SRC) $(GRCC_ANDROID_X64_DST) ; fi
	if test -f $(GRCC_ANDROID_X32_SRC) ; then install -d $(GRCC_ANDROID_X32_DST) && cp $(GRCC_ANDROID_X32_SRC) $(GRCC_ANDROID_X32_DST) ; fi
	if test -f $(GRCC_MACOSX_X64_SRC) ; then install -d $(GRCC_MACOSX_X64_DST) && cp $(GRCC_MACOSX_X64_SRC) $(GRCC_MACOSX_X64_DST) ; fi
	if test -f $(GRCC_MACOSX_ARM64_SRC) ; then install -d $(GRCC_MACOSX_ARM64_DST) && cp $(GRCC_MACOSX_ARM64_SRC) $(GRCC_MACOSX_ARM64_DST) ; fi
	if test -f $(GRCC_MACOSX_X64_SRC) && test -f $(GRCC_MACOSX_ARM64_SRC) ; then $(MAKE) grcc-lib-macosx-universal ; fi
	if test -f $(GRCC_LINUX_X64_SRC) ; then install -d $(GRCC_LINUX_X64_DST) && cp $(GRCC_LINUX_X64_SRC) $(GRCC_LINUX_X64_DST) ; fi
	if test -f $(GRCC_LINUX_ARM64_SRC) ; then install -d $(GRCC_LINUX_ARM64_DST) && cp $(GRCC_LINUX_ARM64_SRC) $(GRCC_LINUX_ARM64_DST) ; fi
	if test -f $(GRCC_WASM_THREADS_SRC) ; then install -d $(GRCC_WASM_DST) && cp $(GRCC_WASM_THREADS_SRC) $(GRCC_WASM_DST)$(GRCC_GODOT_RUST_LIB_NAME).threads.wasm ; fi
	if test -f $(GRCC_WASM_NOTHREADS_SRC) ; then install -d $(GRCC_WASM_DST) && cp $(GRCC_WASM_NOTHREADS_SRC) $(GRCC_WASM_DST)$(GRCC_GODOT_RUST_LIB_NAME).wasm ; fi

grcc-copy-all: grcc-copy-windows grcc-copy-android grcc-copy-macosx grcc-copy-linux grcc-copy-wasm

grcc-copy-windows: grcc-copy-windows-x64 grcc-copy-windows-arm64

grcc-copy-windows-x64: grcc-lib-windows-x64
	install -d $(GRCC_WINDOWS_X64_DST) && cp $(GRCC_WINDOWS_X64_SRC) $(GRCC_WINDOWS_X64_DST)

grcc-copy-windows-arm64: grcc-lib-windows-arm64
	install -d $(GRCC_WINDOWS_ARM64_DST) && cp $(GRCC_WINDOWS_ARM64_SRC) $(GRCC_WINDOWS_ARM64_DST)

grcc-copy-android: grcc-lib-android-arm64 grcc-lib-android-arm32 grcc-lib-android-x64 grcc-lib-android-x32
	install -d $(GRCC_ANDROID_ARM64_DST) && cp $(GRCC_ANDROID_ARM64_SRC) $(GRCC_ANDROID_ARM64_DST)
	install -d $(GRCC_ANDROID_ARM32_DST) && cp $(GRCC_ANDROID_ARM32_SRC) $(GRCC_ANDROID_ARM32_DST)
	install -d $(GRCC_ANDROID_X64_DST) && cp $(GRCC_ANDROID_X64_SRC) $(GRCC_ANDROID_X64_DST)
	install -d $(GRCC_ANDROID_X32_DST) && cp $(GRCC_ANDROID_X32_SRC) $(GRCC_ANDROID_X32_DST)

grcc-copy-macosx: grcc-lib-macosx-x64 grcc-lib-macosx-arm64 grcc-lib-macosx-universal
	install -d $(GRCC_MACOSX_X64_DST) && cp $(GRCC_MACOSX_X64_SRC) $(GRCC_MACOSX_X64_DST)
	install -d $(GRCC_MACOSX_ARM64_DST) && cp $(GRCC_MACOSX_ARM64_SRC) $(GRCC_MACOSX_ARM64_DST)

grcc-copy-linux: grcc-copy-linux-x64 grcc-copy-linux-arm64

grcc-copy-linux-x64: grcc-lib-linux-x64
	install -d $(GRCC_LINUX_X64_DST) && cp $(GRCC_LINUX_X64_SRC) $(GRCC_LINUX_X64_DST)

grcc-copy-linux-arm64: grcc-lib-linux-arm64
	install -d $(GRCC_LINUX_ARM64_DST) && cp $(GRCC_LINUX_ARM64_SRC) $(GRCC_LINUX_ARM64_DST)

grcc-copy-wasm: grcc-lib-wasm
	install -d $(GRCC_WASM_DST)
	cp $(GRCC_WASM_THREADS_SRC) $(GRCC_WASM_DST)$(GRCC_GODOT_RUST_LIB_NAME).threads.wasm
	cp $(GRCC_WASM_NOTHREADS_SRC) $(GRCC_WASM_DST)$(GRCC_GODOT_RUST_LIB_NAME).wasm

grcc-pkg-all: grcc-pkg-windows grcc-pkg-android $(GRCC_PKG_ANDROID_AAB) grcc-pkg-macosx grcc-pkg-linux grcc-pkg-wasm grcc-pkg-source

# [TODO] report this bug, need to launch the export twice for it to work, else complains about missing lib
GRCC_PKG_BUILDX2=godot/buildx2.sh

# Godot 4 export preset names (architecture-specific presets must be defined in export_presets.cfg)
GRCC_EXPORT_PRESET_WINDOWS_X64?=Windows Desktop x64
GRCC_EXPORT_PRESET_WINDOWS_ARM64?=Windows Desktop arm64
GRCC_EXPORT_PRESET_ANDROID?=Android
# Gradle build, export format AAB, "package/signed" off (see grcc-sign-android-aab)
GRCC_EXPORT_PRESET_ANDROID_AAB?=Android AAB
GRCC_EXPORT_PRESET_MACOSX?=macOS
GRCC_EXPORT_PRESET_LINUX_X64?=Linux x64
GRCC_EXPORT_PRESET_LINUX_ARM64?=Linux arm64
GRCC_EXPORT_PRESET_WEB?=Web

grcc-pkg-windows: grcc-pkg-windows-x64 grcc-pkg-windows-arm64

grcc-pkg-windows-x64: grcc-copy-windows-x64 $(GRCC_COPY_EDITOR_LIB)
	rm -f $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_X64_PKG).zip godot/$(GRCC_GAME_PKG_NAME).exe godot/$(GRCC_GODOT_RUST_LIB_NAME).dll
	echo 'for i in warmup real ; do $(GRCC_GODOT_HEADLESS) --path godot --export-release "$(GRCC_EXPORT_PRESET_WINDOWS_X64)" $(GRCC_GAME_PKG_NAME).exe ; done' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_X64_PKG)
	mv godot/$(GRCC_GAME_PKG_NAME).exe godot/$(GRCC_GODOT_RUST_LIB_NAME).dll $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_X64_PKG)
	cd $(GRCC_EXPORT_DIR) && zip -r $(GRCC_EXPORT_WINDOWS_X64_PKG).zip $(GRCC_EXPORT_WINDOWS_X64_PKG) && rm -rf $(GRCC_EXPORT_WINDOWS_X64_PKG)

grcc-pkg-windows-arm64: grcc-copy-windows-arm64 $(GRCC_COPY_EDITOR_LIB)
	rm -f $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_ARM64_PKG).zip godot/$(GRCC_GAME_PKG_NAME).exe godot/$(GRCC_GODOT_RUST_LIB_NAME).dll
	echo 'for i in warmup real ; do $(GRCC_GODOT_HEADLESS) --path godot --export-release "$(GRCC_EXPORT_PRESET_WINDOWS_ARM64)" $(GRCC_GAME_PKG_NAME).exe ; done' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_ARM64_PKG)
	mv godot/$(GRCC_GAME_PKG_NAME).exe godot/$(GRCC_GODOT_RUST_LIB_NAME).dll $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_ARM64_PKG)
	cd $(GRCC_EXPORT_DIR) && zip -r $(GRCC_EXPORT_WINDOWS_ARM64_PKG).zip $(GRCC_EXPORT_WINDOWS_ARM64_PKG) && rm -rf $(GRCC_EXPORT_WINDOWS_ARM64_PKG)

# Tells which key Android exports will use; fails on a release keystore given
# a password but no alias.
grcc-check-android-signing:
	@echo "grcc: Android signing: $(GRCC_ANDROID_SIGNING_DESC)"
ifeq (release,$(GRCC_ANDROID_SIGNING))
ifeq (,$(GRCC_ANDROID_RELEASE_KEYSTORE_USER))
	@echo "grcc: GRCC_ANDROID_RELEASE_KEYSTORE_USER (key alias) is required with $(GRCC_ANDROID_RELEASE_KEYSTORE)" >&2
	@exit 1
endif
else
ifneq (,$(wildcard $(GRCC_ANDROID_RELEASE_KEYSTORE)))
	@echo "grcc: $(GRCC_ANDROID_RELEASE_KEYSTORE) found but GRCC_ANDROID_RELEASE_KEYSTORE_PASSWORD is not set: not using it"
endif
endif

grcc-pkg-android: grcc-check-android-signing grcc-copy-android $(GRCC_COPY_EDITOR_LIB)
	rm -f $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_ANDROID_PKG).apk godot/$(GRCC_EXPORT_ANDROID_PKG).apk
	echo 'for i in warmup real ; do $(GRCC_GODOT_HEADLESS) --path godot --export-release "$(GRCC_EXPORT_PRESET_ANDROID)" $(GRCC_EXPORT_ANDROID_PKG).apk ; done' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR) && mv godot/$(GRCC_EXPORT_ANDROID_PKG).apk $(GRCC_EXPORT_DIR)

define GRCC_AAB_UNAVAILABLE

Android App Bundles (.aab) need the amd64 image (Gradle's aapt2 is x86_64-only)
and this build would run the AAB export on $(GRCC_AAB_DOCKER_ARCH)
(GRCC_AAB_EMULATE=$(GRCC_AAB_EMULATE), Docker: $(GRCC_USE_DOCKER)).
Use the default GRCC_AAB_EMULATE=yes with Docker, or build on an amd64 host.

endef
export GRCC_AAB_UNAVAILABLE

define GRCC_AAB_SKIPPED_NOTICE

NOTICE: no Android App Bundle (.aab) was built.$(GRCC_AAB_UNAVAILABLE)
endef
export GRCC_AAB_SKIPPED_NOTICE

# In grcc-pkg-all when no AAB can be built, instead of silently leaving it out.
grcc-skip-android-aab:
	@echo "$$GRCC_AAB_SKIPPED_NOTICE"

grcc-check-aab-host:
ifneq (yes,$(GRCC_AAB_POSSIBLE))
	@echo "ERROR: $$GRCC_AAB_UNAVAILABLE" >&2
	@exit 1
endif
ifneq ($(GRCC_AAB_DOCKER_ARCH),$(GRCC_DOCKER_ARCH))
	@echo "grcc: AAB export runs in the emulated $(GRCC_AAB_DOCKER_ARCH) image $(GRCC_AAB_DOCKER_IMAGE) (slow; GRCC_AAB_EMULATE=no to disable)"
endif

# Unsigned AAB: Godot's Gradle build (template reinstalled on each export so it
# always matches the image's Godot; no Gradle daemon, so a failed warmup pass
# cannot keep the build cache locked for the real one), then checked with bundletool.
grcc-pkg-android-aab: grcc-check-aab-host grcc-check-android-signing grcc-copy-android $(GRCC_AAB_EDITOR_LIB)
	rm -f $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_ANDROID_AAB_UNSIGNED) godot/$(GRCC_EXPORT_ANDROID_AAB_UNSIGNED)
	echo 'set -e ; export GRADLE_OPTS="$${GRADLE_OPTS:+$$GRADLE_OPTS }-Dorg.gradle.daemon=false" ; for i in warmup real ; do $(GRCC_GODOT_HEADLESS) --path godot --install-android-build-template --export-release "$(GRCC_EXPORT_PRESET_ANDROID_AAB)" $(GRCC_EXPORT_ANDROID_AAB_UNSIGNED) || test $$i = warmup ; done ; java -jar /opt/bundletool.jar validate --bundle=godot/$(GRCC_EXPORT_ANDROID_AAB_UNSIGNED)' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_GRADLE) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR) && mv godot/$(GRCC_EXPORT_ANDROID_AAB_UNSIGNED) $(GRCC_EXPORT_DIR)

# Upload signature only: with Play App Signing, Google signs what devices get,
# but Play still requires the AAB to be signed with the registered upload key.
# Uses GODOT_ANDROID_KEYSTORE_RELEASE_* (see GRCC_ANDROID_RELEASE_KEYSTORE); with
# a debug keystore ("Android Debug" certificate) the AAB is left unsigned.
define GRCC_AAB_SIGN_SCRIPT
set -e
in="$(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_ANDROID_AAB_UNSIGNED)"
out="$(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_ANDROID_AAB)"
ks="$$GODOT_ANDROID_KEYSTORE_RELEASE_PATH"
alias="$$GODOT_ANDROID_KEYSTORE_RELEASE_USER"
rm -f "$$out"
if [ ! -f "$$ks" ]; then
    echo "grcc: upload keystore not found: $$ks" >&2
    exit 1
fi
if keytool -list -v -keystore "$$ks" -alias "$$alias" -storepass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD 2>/dev/null | grep -q "CN=Android Debug"; then
    echo "grcc: $$ks is an Android debug key, which Google Play rejects."
    echo "grcc: AAB left unsigned: $$in"
    echo "grcc: to sign it, export GRCC_ANDROID_RELEASE_KEYSTORE_PASSWORD (password of $(GRCC_ANDROID_RELEASE_KEYSTORE)$(if $(GRCC_ANDROID_RELEASE_KEYSTORE_USER),,, plus GRCC_ANDROID_RELEASE_KEYSTORE_USER for its alias))."
    exit 0
fi
jarsigner -keystore "$$ks" -storepass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -keypass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD -signedjar "$$out" "$$in" "$$alias"
jarsigner -verify "$$out" > /dev/null
echo "grcc: signed with upload key ($$alias): $$out"
endef
export GRCC_AAB_SIGN_SCRIPT

GRCC_AAB_SIGN_BUILDSCRIPT=godot/aab-sign.sh

grcc-sign-android-aab: grcc-pkg-android-aab
	printf '%s\n' "$$GRCC_AAB_SIGN_SCRIPT" > $(GRCC_AAB_SIGN_BUILDSCRIPT) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_AAB_SIGN_BUILDSCRIPT) ; ret=$$? ; rm -f $(GRCC_AAB_SIGN_BUILDSCRIPT) ; exit $$ret

grcc-pkg-macosx: grcc-copy-macosx $(GRCC_COPY_EDITOR_LIB)
	rm -f $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_MACOSX_PKG).zip godot/$(GRCC_EXPORT_MACOSX_PKG).zip
	echo 'for i in warmup real ; do $(GRCC_GODOT_HEADLESS) --path godot --export-release "$(GRCC_EXPORT_PRESET_MACOSX)" $(GRCC_EXPORT_MACOSX_PKG).zip ; done' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR) && mv godot/$(GRCC_EXPORT_MACOSX_PKG).zip $(GRCC_EXPORT_DIR)

grcc-pkg-linux: grcc-pkg-linux-x64 grcc-pkg-linux-arm64

grcc-pkg-linux-x64: grcc-copy-linux-x64 $(GRCC_COPY_EDITOR_LIB)
	rm -f $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_LINUX_X64_PKG).tar.gz godot/$(GRCC_GAME_PKG_NAME) godot/lib$(GRCC_GODOT_RUST_LIB_NAME).so
	echo 'for i in warmup real ; do $(GRCC_GODOT_HEADLESS) --path godot --export-release "$(GRCC_EXPORT_PRESET_LINUX_X64)" $(GRCC_GAME_PKG_NAME) ; done' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_LINUX_X64_PKG)
	mv godot/$(GRCC_GAME_PKG_NAME) godot/lib$(GRCC_GODOT_RUST_LIB_NAME).so $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_LINUX_X64_PKG)
	cd $(GRCC_EXPORT_DIR) && tar czf $(GRCC_EXPORT_LINUX_X64_PKG).tar.gz $(GRCC_EXPORT_LINUX_X64_PKG) && rm -rf $(GRCC_EXPORT_LINUX_X64_PKG)

grcc-pkg-linux-arm64: grcc-copy-linux-arm64 $(GRCC_COPY_EDITOR_LIB)
	rm -f $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_LINUX_ARM64_PKG).tar.gz godot/$(GRCC_GAME_PKG_NAME) godot/lib$(GRCC_GODOT_RUST_LIB_NAME).so
	echo 'for i in warmup real ; do $(GRCC_GODOT_HEADLESS) --path godot --export-release "$(GRCC_EXPORT_PRESET_LINUX_ARM64)" $(GRCC_GAME_PKG_NAME) ; done' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_LINUX_ARM64_PKG)
	mv godot/$(GRCC_GAME_PKG_NAME) godot/lib$(GRCC_GODOT_RUST_LIB_NAME).so $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_LINUX_ARM64_PKG)
	cd $(GRCC_EXPORT_DIR) && tar czf $(GRCC_EXPORT_LINUX_ARM64_PKG).tar.gz $(GRCC_EXPORT_LINUX_ARM64_PKG) && rm -rf $(GRCC_EXPORT_LINUX_ARM64_PKG)

grcc-pkg-wasm: grcc-copy-wasm $(GRCC_COPY_EDITOR_LIB)
	rm -rf $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WASM_PKG) $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WASM_PKG).zip godot/$(GRCC_EXPORT_WASM_PKG)
	install -d godot/$(GRCC_EXPORT_WASM_PKG)
	echo 'for i in warmup real ; do $(GRCC_GODOT_HEADLESS) --path godot --export-release "$(GRCC_EXPORT_PRESET_WEB)" $(GRCC_EXPORT_WASM_PKG)/index.html ; done' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR) && mv godot/$(GRCC_EXPORT_WASM_PKG) $(GRCC_EXPORT_DIR)/
	cd $(GRCC_EXPORT_DIR) && zip -r $(GRCC_EXPORT_WASM_PKG).zip $(GRCC_EXPORT_WASM_PKG) && rm -rf $(GRCC_EXPORT_WASM_PKG)

# Signing keys must never end up in source packages: exclude the keystore
# directory and any key file by extension, then fail if one slipped through.
GRCC_PKG_SOURCE_EXCLUDES=--exclude=.git --exclude=$(GRCC_KEYSTORE_DIR) --exclude='*.keystore' --exclude='*.jks' --exclude=export --exclude=./target --exclude=rust/target --exclude=godot/.godot --exclude=godot/android --exclude=godot/gdnative
GRCC_PKG_SOURCE_KEY_PATTERN=(^|/)($(notdir $(GRCC_KEYSTORE_DIR))/|[^/]*\.(keystore|jks)$$)

grcc-pkg-source: .git/config grcc-clean-prepare
	install -d $(GRCC_EXPORT_DIR) && rm -f $(GRCC_EXPORT_DIR)/$(GRCC_GAME_REPO_NAME).tar
	tar cf $(GRCC_EXPORT_DIR)/$(GRCC_GAME_REPO_NAME).tar $(GRCC_PKG_SOURCE_EXCLUDES) .
	if tar tf $(GRCC_EXPORT_DIR)/$(GRCC_GAME_REPO_NAME).tar | grep -E '$(GRCC_PKG_SOURCE_KEY_PATTERN)' ; then echo "grcc: signing keys found in source package, aborting" >&2 ; rm -f $(GRCC_EXPORT_DIR)/$(GRCC_GAME_REPO_NAME).tar ; exit 1 ; fi
	cd $(GRCC_EXPORT_DIR) && rm -rf $(GRCC_GAME_REPO_NAME)-$(GRCC_GAME_REPO_VERSION) && rm -f $(GRCC_GAME_REPO_NAME)-$(GRCC_GAME_REPO_VERSION).tar.gz $(GRCC_GAME_REPO_NAME)-$(GRCC_GAME_REPO_VERSION).zip && mkdir $(GRCC_GAME_REPO_NAME)-$(GRCC_GAME_REPO_VERSION) && cd $(GRCC_GAME_REPO_NAME)-$(GRCC_GAME_REPO_VERSION) && tar xf ../$(GRCC_GAME_REPO_NAME).tar && cd .. && rm $(GRCC_GAME_REPO_NAME).tar && tar czf $(GRCC_GAME_REPO_NAME)-$(GRCC_GAME_REPO_VERSION).tar.gz $(GRCC_GAME_REPO_NAME)-$(GRCC_GAME_REPO_VERSION) && zip -r $(GRCC_GAME_REPO_NAME)-$(GRCC_GAME_REPO_VERSION).zip $(GRCC_GAME_REPO_NAME)-$(GRCC_GAME_REPO_VERSION) && rm -rf $(GRCC_GAME_REPO_NAME)-$(GRCC_GAME_REPO_VERSION)

# Windows installers (NSIS)
# -------------------------

grcc-installer-windows: grcc-installer-windows-x64 grcc-installer-windows-arm64

# makensis resolves relative paths from the .nsi directory (/opt/grcc) unless
# -NOCD is given; all paths passed below are relative to the project root.
GRCC_INSTALLER_BUILDSCRIPT=godot/installer-build.sh

grcc-installer-windows-x64: grcc-pkg-windows-x64
	install -d $(GRCC_EXPORT_DIR)
	cd $(GRCC_EXPORT_DIR) && unzip -o $(GRCC_EXPORT_WINDOWS_X64_PKG).zip
	echo 'makensis -NOCD -DGAME_NAME="$(GRCC_GAME_PKG_NAME)" \
		-DGAME_VERSION="$(GRCC_GAME_PKG_VERSION)" \
		-DGAME_PUBLISHER="$(GRCC_GAME_PUBLISHER)" \
		-DEXE_FILE="$(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_X64_PKG)/$(GRCC_GAME_PKG_NAME).exe" \
		-DEXE_NAME="$(GRCC_GAME_PKG_NAME).exe" \
		-DDLL_FILE="$(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_X64_PKG)/$(GRCC_GODOT_RUST_LIB_NAME).dll" \
		-DDLL_NAME="$(GRCC_GODOT_RUST_LIB_NAME).dll" \
		-DOUTPUT_FILE="$(GRCC_EXPORT_DIR)/$(GRCC_INSTALLER_WINDOWS_X64)" \
		$(GRCC_INSTALLER_TEMPLATE)' > $(GRCC_INSTALLER_BUILDSCRIPT) && chmod a+x $(GRCC_INSTALLER_BUILDSCRIPT) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_INSTALLER_BUILDSCRIPT) && rm $(GRCC_INSTALLER_BUILDSCRIPT)
	rm -rf $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_X64_PKG)

grcc-installer-windows-arm64: grcc-pkg-windows-arm64
	install -d $(GRCC_EXPORT_DIR)
	cd $(GRCC_EXPORT_DIR) && unzip -o $(GRCC_EXPORT_WINDOWS_ARM64_PKG).zip
	echo 'makensis -NOCD -DGAME_NAME="$(GRCC_GAME_PKG_NAME)" \
		-DGAME_VERSION="$(GRCC_GAME_PKG_VERSION)" \
		-DGAME_PUBLISHER="$(GRCC_GAME_PUBLISHER)" \
		-DEXE_FILE="$(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_ARM64_PKG)/$(GRCC_GAME_PKG_NAME).exe" \
		-DEXE_NAME="$(GRCC_GAME_PKG_NAME).exe" \
		-DDLL_FILE="$(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_ARM64_PKG)/$(GRCC_GODOT_RUST_LIB_NAME).dll" \
		-DDLL_NAME="$(GRCC_GODOT_RUST_LIB_NAME).dll" \
		-DOUTPUT_FILE="$(GRCC_EXPORT_DIR)/$(GRCC_INSTALLER_WINDOWS_ARM64)" \
		$(GRCC_INSTALLER_TEMPLATE)' > $(GRCC_INSTALLER_BUILDSCRIPT) && chmod a+x $(GRCC_INSTALLER_BUILDSCRIPT) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_INSTALLER_BUILDSCRIPT) && rm $(GRCC_INSTALLER_BUILDSCRIPT)
	rm -rf $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_ARM64_PKG)

# macOS DMG (disk image)
# ----------------------
# Creates a DMG from the macOS zip export
# Uses genisoimage to create hybrid ISO and libdmg-hfsplus ("dmg dmg <iso> <dmg>")
# to convert it to a compressed DMG.

GRCC_DMG_BUILDSCRIPT=godot/dmg-build.sh

grcc-dmg-macosx: grcc-pkg-macosx
	install -d $(GRCC_EXPORT_DIR)
	rm -rf $(GRCC_EXPORT_DIR)/dmg-staging $(GRCC_EXPORT_DIR)/$(GRCC_DMG_MACOSX)
	mkdir -p $(GRCC_EXPORT_DIR)/dmg-staging
	cd $(GRCC_EXPORT_DIR)/dmg-staging && unzip -q ../$(GRCC_EXPORT_MACOSX_PKG).zip
	echo 'genisoimage -V "$(GRCC_DMG_VOLUME_NAME)" -D -R -apple -no-pad -o $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_MACOSX_PKG).cdr $(GRCC_EXPORT_DIR)/dmg-staging && \
		dmg dmg $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_MACOSX_PKG).cdr $(GRCC_EXPORT_DIR)/$(GRCC_DMG_MACOSX)' > $(GRCC_DMG_BUILDSCRIPT) && chmod a+x $(GRCC_DMG_BUILDSCRIPT) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_DMG_BUILDSCRIPT) && rm $(GRCC_DMG_BUILDSCRIPT)
	rm -rf $(GRCC_EXPORT_DIR)/dmg-staging $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_MACOSX_PKG).cdr
