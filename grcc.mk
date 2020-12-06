# To use this, define GRCC_GODOT_RUST_LIB_NAME then include it.
# Example:
#
# ---8<----------------------
# GRCC_GODOT_RUST_LIB_NAME=cctoy
# include grcc.mk
# ---8<----------------------
#
# This will build cctoy.dll, libcctoy.dylib, libcctoy.so
#
# More info on:
# https://github.com/ufoot/godot-rust-cross-compiler

.PHONY: grcc-all
.PHONY: grcc-test
.PHONY: grcc-debug
.PHONY: grcc-release
.PHONY: grcc-lib-all
.PHONY: grcc-lib-windows
.PHONY: grcc-lib-windows-i64
.PHONY: grcc-lib-android
.PHONY: grcc-lib-android-arm64
.PHONY: grcc-lib-android-arm32
.PHONY: grcc-lib-android-i64
.PHONY: grcc-lib-android-i32
.PHONY: grcc-lib-macosx
.PHONY: grcc-lib-macosx-i64
.PHONY: grcc-lib-linux
.PHONY: grcc-lib-linux-i64
.PHONY: grcc-lib-linux-i32
.PHONY: grcc-native
.PHONY: grcc-cross
.PHONY: grcc-copy-local
.PHONY: grcc-copy-if-exists
.PHONY: grcc-copy-all
.PHONY: grcc-copy-windows
.PHONY: grcc-copy-android
.PHONY: grcc-copy-macosx
.PHONY: grcc-copy-linux
.PHONY: grcc-pkg-all
.PHONY: grcc-pkg-windows
.PHONY: grcc-pkg-android
.PHONY: grcc-pkg-macosx
.PHONY: grcc-pkg-linux

grcc-all: grcc-native

grcc-native: grcc-test grcc-debug grcc-copy-local

grcc-cross: grcc-test grcc-lib-all grcc-copy-all

grcc-export: grcc-test grcc-pkg-all

grcc-lib-all: grcc-lib-windows grcc-lib-android grcc-lib-macosx grcc-lib-linux

GRCC_WINDOWS_I64_TARGET=x86_64-pc-windows-gnu
GRCC_ANDROID_ARM64_TARGET=aarch64-linux-android
GRCC_ANDROID_ARM32_TARGET=armv7-linux-androideabi
GRCC_ANDROID_I64_TARGET=x86_64-linux-android
GRCC_ANDROID_I32_TARGET=i686-linux-android
GRCC_MACOSX_I64_TARGET=x86_64-apple-darwin
GRCC_LINUX_I64_TARGET=x86_64-unknown-linux-gnu
GRCC_LINUX_I32_TARGET=i686-unknown-linux-gnu

ifeq (,$(GRCC_GODOT_RUST_LIB_NAME))
GRCC_GODOT_RUST_LIB_NAME=please-define-GRCC_GODOT_RUST_LIB_NAME
endif
ifeq (,$(GRCC_GAME_PKG_NAME))
GRCC_GAME_PKG_NAME=$(GRCC_GODOT_RUST_LIB_NAME)
endif
ifeq (,$(GRCC_GAME_PKG_VERSION))
GRCC_GAME_PKG_VERSION=0.0.1
endif

ifeq (,$(wildcard /opt/godot-rust-cross-compiler.txt))
GRCC_USE_DOCKER=yes
GRCC_INVOKE_DOCKER_RUST=install -d $(GRCC_CROSS_COMPILER_CACHE_DIR)/git && install -d $(GRCC_CROSS_COMPILER_CACHE_DIR)/registry && docker run -v $$(pwd):/build -v$$(realpath $(GRCC_CROSS_COMPILER_CACHE_DIR)/git):/root/.cargo/git -v$$(realpath $(GRCC_CROSS_COMPILER_CACHE_DIR)/registry):/root/.cargo/registry
GRCC_INVOKE_DOCKER_GODOT_EXPORT=docker run -v $$(pwd):/build ufoot/godot-rust-cross-compiler
else
GRCC_USE_DOCKER=no
GRCC_INVOKE_DOCKER_GODOT_EXPORT=
endif

GRCC_NATIVE_DEBUG_SRC=./rust/target/debug/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_NATIVE_RELEASE_SRC=./rust/target/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so

GRCC_GODOT_GDNATIVE_DIR=./godot/gdnative
GRCC_WINDOWS_I64_SRC=./rust/target/$(GRCC_WINDOWS_I64_TARGET)/release/$(GRCC_GODOT_RUST_LIB_NAME).dll
GRCC_WINDOWS_I64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/windows/$(GRCC_WINDOWS_I64_TARGET)/
GRCC_ANDROID_ARM64_SRC=./rust/target/$(GRCC_ANDROID_ARM64_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_ANDROID_ARM64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/android/$(GRCC_ANDROID_ARM64_TARGET)/
GRCC_ANDROID_ARM32_SRC=./rust/target/$(GRCC_ANDROID_ARM32_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_ANDROID_ARM32_DST=$(GRCC_GODOT_GDNATIVE_DIR)/android/$(GRCC_ANDROID_ARM32_TARGET)/
GRCC_ANDROID_I64_SRC=./rust/target/$(GRCC_ANDROID_I64_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_ANDROID_I64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/android/$(GRCC_ANDROID_I64_TARGET)/
GRCC_ANDROID_I32_SRC=./rust/target/$(GRCC_ANDROID_I32_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_ANDROID_I32_DST=$(GRCC_GODOT_GDNATIVE_DIR)/android/$(GRCC_ANDROID_I32_TARGET)/
GRCC_MACOSX_I64_SRC=./rust/target/$(GRCC_MACOSX_I64_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).dylib
GRCC_MACOSX_I64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/macosx/$(GRCC_MACOSX_I64_TARGET)/
GRCC_LINUX_I64_SRC=./rust/target/$(GRCC_LINUX_I64_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_LINUX_I64_DST=$(GRCC_GODOT_GDNATIVE_DIR)/linux/$(GRCC_LINUX_I64_TARGET)/
GRCC_LINUX_I32_SRC=./rust/target/$(GRCC_LINUX_I32_TARGET)/release/lib$(GRCC_GODOT_RUST_LIB_NAME).so
GRCC_LINUX_I32_DST=$(GRCC_GODOT_GDNATIVE_DIR)/linux/$(GRCC_LINUX_I32_TARGET)/

GRCC_CROSS_COMPILER_CACHE_DIR=cross-compile-cache

GRCC_WINDOWS_MINGW_HEADERS=/usr/x86_64-w64-mingw32/include
GRCC_MACOSX_SDK_HEADERS=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX10.10.sdk/usr/include
GRCC_MACOSX_SDK_CC=/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin14-cc

GRCC_EXPORT_DIR=export
GRCC_EXPORT_WINDOWS_PKG=$(GRCC_GAME_PKG_NAME)-windows-v$(GRCC_GAME_PKG_VERSION)
GRCC_EXPORT_ANDROID_PKG=$(GRCC_GAME_PKG_NAME)-android-v$(GRCC_GAME_PKG_VERSION)
GRCC_EXPORT_MACOSX_PKG=$(GRCC_GAME_PKG_NAME)-macosx-v$(GRCC_GAME_PKG_VERSION)
GRCC_EXPORT_LINUX_PKG=$(GRCC_GAME_PKG_NAME)-linux-v$(GRCC_GAME_PKG_VERSION)

grcc-test:
	cd rust && cargo test

grcc-debug:
	cd rust && cargo build

grcc-release:
	cd rust && cargo build --release

grcc-clean:
	rm -rf $(GRCC_GODOT_GDNATIVE_DIR)
	rm -rf export
	cd rust && (cargo clean || rm -rf ./target)
	rm -rf $(GRCC_CROSS_COMPILER_CACHE_DIR)

grcc-lib-all: grcc-lib-windows grcc-lib-android grcc-lib-macosx grcc-lib-linux

grcc-lib-windows: grcc-lib-windows-i64

grcc-lib-windows-i64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) -e C_INCLUDE_PATH=$(GRCC_WINDOWS_MINGW_HEADERS) ufoot/godot-rust-cross-compiler cargo build --release --target $(GRCC_WINDOWS_I64_TARGET)
else
	export C_INCLUDE_PATH=$(GRCC_WINDOWS_MINGW_HEADERS) && cd rust && cargo build --release --target $(GRCC_WINDOWS_I64_TARGET)
endif

grcc-lib-android: grcc-lib-android-arm64 grcc-lib-android-arm32 grcc-lib-android-i64 grcc-lib-android-i32

grcc-lib-android-arm64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) ufoot/godot-rust-cross-compiler cargo build --release --target $(GRCC_ANDROID_ARM64_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_ANDROID_ARM64_TARGET)
endif

grcc-lib-android-arm32:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) ufoot/godot-rust-cross-compiler cargo build --release --target $(GRCC_ANDROID_ARM32_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_ANDROID_ARM32_TARGET)
endif

grcc-lib-android-i64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) ufoot/godot-rust-cross-compiler cargo build --release --target $(GRCC_ANDROID_I64_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_ANDROID_I64_TARGET)
endif

grcc-lib-android-i32:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) ufoot/godot-rust-cross-compiler cargo build --release --target $(GRCC_ANDROID_I32_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_ANDROID_I32_TARGET)
endif

grcc-lib-macosx: grcc-lib-macosx-i64

grcc-lib-macosx-i64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) -e CC=$(GRCC_MACOSX_SDK_CC) -e C_INCLUDE_PATH=$(GRCC_MACOSX_SDK_HEADERS) ufoot/godot-rust-cross-compiler cargo build --release --target $(GRCC_MACOSX_I64_TARGET)
else
	export CC=$(GRCC_MACOSX_SDK_CC) C_INCLUDE_PATH=$(GRCC_MACOSX_SDK_HEADERS) && cd rust && cargo build --release --target $(GRCC_MACOSX_I64_TARGET)
endif

grcc-lib-linux: grcc-lib-linux-i64 grcc-lib-linux-i32

grcc-lib-linux-i64:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) ufoot/godot-rust-cross-compiler cargo build --release --target $(GRCC_LINUX_I64_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_LINUX_I64_TARGET)
endif

grcc-lib-linux-i32:
ifeq (yes,$(GRCC_USE_DOCKER))
	cd rust && $(GRCC_INVOKE_DOCKER_RUST) ufoot/godot-rust-cross-compiler cargo build --release --target $(GRCC_LINUX_I32_TARGET)
else
	cd rust && cargo build --release --target $(GRCC_LINUX_I32_TARGET)
endif

grcc-copy-local:
	if (uname -a | grep -i darwin) && (uname -a | grep -i x86_64); then install -d $(GRCC_MACOSX_I64_DST) && cp $(GRCC_NATIVE_DEBUG_SRC) $(GRCC_MACOSX_I64_DST) ; fi
	if (uname -a | grep -i linux) && (uname -a | grep -i x86_64); then install -d $(GRCC_LINUX_I64_DST) && cp $(GRCC_NATIVE_DEBUG_SRC) $(GRCC_LINUX_I64_DST) ; fi

grcc-copy-if-exists:
	if test -f $(GRCC_WINDOWS_I64_SRC) ; then install -d $(GRCC_WINDOWS_I64_DST) && cp $(GRCC_WINDOWS_I64_SRC) $(GRCC_WINDOWS_I64_DST) ; fi
	if test -f $(GRCC_ANDROID_ARM64_SRC) ; then install -d $(GRCC_ANDROID_ARM64_DST) && cp $(GRCC_ANDROID_ARM64_SRC) $(GRCC_ANDROID_ARM64_DST) ; fi
	if test -f $(GRCC_ANDROID_ARM32_SRC) ; then install -d $(GRCC_ANDROID_ARM32_DST) && cp $(GRCC_ANDROID_ARM32_SRC) $(GRCC_ANDROID_ARM32_DST) ; fi
	if test -f $(GRCC_ANDROID_I64_SRC) ; then install -d $(GRCC_ANDROID_I64_DST) && cp $(GRCC_ANDROID_I64_SRC) $(GRCC_ANDROID_I64_DST) ; fi
	if test -f $(GRCC_ANDROID_I32_SRC) ; then install -d $(GRCC_ANDROID_I32_DST) && cp $(GRCC_ANDROID_I32_SRC) $(GRCC_ANDROID_I32_DST) ; fi
	if test -f $(GRCC_MACOSX_I64_SRC) ; then install -d $(GRCC_MACOSX_I64_DST) && cp $(GRCC_MACOSX_I64_SRC) $(GRCC_MACOSX_I64_DST) ; fi
	if test -f $(GRCC_LINUX_I64_SRC) ; then install -d $(GRCC_LINUX_I64_DST) && cp $(GRCC_LINUX_I64_SRC) $(GRCC_LINUX_I64_DST) ; fi
	if test -f $(GRCC_LINUX_I32_SRC) ; then install -d $(GRCC_LINUX_I32_DST) && cp $(GRCC_LINUX_I32_SRC) $(GRCC_LINUX_I32_DST) ; fi

grcc-copy-all: grcc-copy-windows grcc-copy-android grcc-copy-macosx grcc-copy-linux

grcc-copy-windows: grcc-lib-windows-i64
	install -d $(GRCC_WINDOWS_I64_DST) && cp $(GRCC_WINDOWS_I64_SRC) $(GRCC_WINDOWS_I64_DST)

grcc-copy-android: grcc-lib-android-arm64 grcc-lib-android-arm32 grcc-lib-android-i64 grcc-lib-android-i32
	install -d $(GRCC_ANDROID_ARM64_DST) && cp $(GRCC_ANDROID_ARM64_SRC) $(GRCC_ANDROID_ARM64_DST)
	install -d $(GRCC_ANDROID_ARM32_DST) && cp $(GRCC_ANDROID_ARM32_SRC) $(GRCC_ANDROID_ARM32_DST)
	install -d $(GRCC_ANDROID_I64_DST) && cp $(GRCC_ANDROID_I64_SRC) $(GRCC_ANDROID_I64_DST)
	install -d $(GRCC_ANDROID_I32_DST) && cp $(GRCC_ANDROID_I32_SRC) $(GRCC_ANDROID_I32_DST)

grcc-copy-macosx: grcc-lib-macosx-i64
	install -d $(GRCC_MACOSX_I64_DST) && cp $(GRCC_MACOSX_I64_SRC) $(GRCC_MACOSX_I64_DST)

grcc-copy-linux: grcc-lib-linux-i64 grcc-lib-linux-i32
	install -d $(GRCC_LINUX_I64_DST) && cp $(GRCC_LINUX_I64_SRC) $(GRCC_LINUX_I64_DST)
	install -d $(GRCC_LINUX_I32_DST) && cp $(GRCC_LINUX_I32_SRC) $(GRCC_LINUX_I32_DST)

grcc-pkg-all: grcc-pkg-windows grcc-pkg-android grcc-pkg-macosx grcc-pkg-linux

# [TODO] report this bug, need to launch the export twice for it to work, else complains about missing lib
GRCC_PKG_BUILDX2=godot/buildx2.sh

grcc-pkg-windows: grcc-copy-windows
	rm -f $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_PKG).zip godot/$(GRCC_GAME_PKG_NAME).exe godot/$(GRCC_GODOT_RUST_LIB_NAME).dll
	echo 'for i in warmup real ; do godot_headless --path godot --export "Windows Desktop" $(GRCC_GAME_PKG_NAME).exe ; done' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_PKG)
	mv godot/$(GRCC_GAME_PKG_NAME).exe godot/$(GRCC_GODOT_RUST_LIB_NAME).dll $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_WINDOWS_PKG)
	cd $(GRCC_EXPORT_DIR) && zip -r $(GRCC_EXPORT_WINDOWS_PKG).zip $(GRCC_EXPORT_WINDOWS_PKG) && rm -rf $(GRCC_EXPORT_WINDOWS_PKG)

grcc-pkg-android: grcc-copy-android
	rm -f $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_ANDROID_PKG).apk godot/$(GRCC_EXPORT_ANDROID_PKG).apk
	echo 'for i in warmup real ; do godot_headless --path godot --export "Android" $(GRCC_EXPORT_ANDROID_PKG).apk ; done' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR) && mv godot/$(GRCC_EXPORT_ANDROID_PKG).apk $(GRCC_EXPORT_DIR)

grcc-pkg-macosx: grcc-copy-macosx
	rm -f $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_MACOSX_PKG).zip godot/$(GRCC_EXPORT_MACOSX_PKG).zip
	echo 'for i in warmup real ; do godot_headless --path godot --export "Mac OSX" $(GRCC_EXPORT_MACOSX_PKG).zip ; done' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR) && mv godot/$(GRCC_EXPORT_MACOSX_PKG).zip $(GRCC_EXPORT_DIR)

grcc-pkg-linux: grcc-copy-linux
	rm -f $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_LINUX_PKG).zip godot/lib
	echo 'for i in warmup real ; do godot_headless --path godot --export "Linux/X11" $(GRCC_GAME_PKG_NAME).bin ; done' > $(GRCC_PKG_BUILDX2) && chmod a+x $(GRCC_PKG_BUILDX2) && $(GRCC_INVOKE_DOCKER_GODOT_EXPORT) sh $(GRCC_PKG_BUILDX2) && rm $(GRCC_PKG_BUILDX2)
	install -d $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_LINUX_PKG)
	mv godot/$(GRCC_GAME_PKG_NAME).bin godot/lib$(GRCC_GODOT_RUST_LIB_NAME).so $(GRCC_EXPORT_DIR)/$(GRCC_EXPORT_LINUX_PKG)
	cd $(GRCC_EXPORT_DIR) && tar czf $(GRCC_EXPORT_LINUX_PKG).tar.gz $(GRCC_EXPORT_LINUX_PKG) && rm -rf $(GRCC_EXPORT_LINUX_PKG)
