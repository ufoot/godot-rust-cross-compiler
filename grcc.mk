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
.PHONY: grcc-target-all
.PHONY: grcc-target-windows
.PHONY: grcc-target-windows-i64
.PHONY: grcc-target-android
.PHONY: grcc-target-android-arm64
.PHONY: grcc-target-android-arm32
.PHONY: grcc-target-android-i64
.PHONY: grcc-target-android-i32
.PHONY: grcc-target-macosx
.PHONY: grcc-target-macosx-i64
.PHONY: grcc-target-linux
.PHONY: grcc-target-linux-i64
.PHONY: grcc-target-linux-i32
.PHONY: grcc-native
.PHONY: grcc-cross
.PHONY: grcc-copy-local
.PHONY: grcc-copy-if-exists
.PHONY: grcc-copy-all

grcc-all: grcc-native

grcc-native: grcc-test grcc-debug grcc-release grcc-copy-local

grcc-cross: grcc-target-all grcc-copy-all

grcc-target-all: grcc-target-windows grcc-target-android grcc-target-macosx grcc-target-linux

GRCC_WINDOWS_I64_TARGET=x86_64-pc-windows-gnu
GRCC_ANDROID_ARM64_TARGET=aarch64-linux-android
GRCC_ANDROID_ARM32_TARGET=armv7-linux-androideabi
GRCC_ANDROID_I64_TARGET=x86_64-linux-android
GRCC_ANDROID_I32_TARGET=i686-linux-android
GRCC_MACOSX_I64_TARGET=x86_64-apple-darwin
GRCC_LINUX_I64_TARGET=x86_64-unknown-linux-gnu
GRCC_LINUX_I32_TARGET=i686-unknown-linux-gnu

ifeq (X,X$(GRCC_GODOT_RUST_LIB_NAME))
GRCC_GODOT_RUST_LIB_NAME=please-define-GRCC_GODOT_RUST_LIB_NAME
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

GRCC_CROSS_COMPILE_CACHE_DIR=./rust/cross-compile-cache
GRCC_CROSS_COMPILE_CACHE_WINDOWS_I64_DIR=$(GRCC_CROSS_COMPILE_CACHE_DIR)/$(GRCC_WINDOWS_I64_TARGET)
GRCC_CROSS_COMPILE_CACHE_ANDROID_ARM64_DIR=$(GRCC_CROSS_COMPILE_CACHE_DIR)/$(GRCC_ANDROID_ARM64_TARGET)
GRCC_CROSS_COMPILE_CACHE_ANDROID_ARM32_DIR=$(GRCC_CROSS_COMPILE_CACHE_DIR)/$(GRCC_ANDROID_ARM32_TARGET)
GRCC_CROSS_COMPILE_CACHE_ANDROID_I64_DIR=$(GRCC_CROSS_COMPILE_CACHE_DIR)/$(GRCC_ANDROID_I64_TARGET)
GRCC_CROSS_COMPILE_CACHE_ANDROID_I32_DIR=$(GRCC_CROSS_COMPILE_CACHE_DIR)/$(GRCC_ANDROID_I32_TARGET)
GRCC_CROSS_COMPILE_CACHE_MACOSX_I64_DIR=$(GRCC_CROSS_COMPILE_CACHE_DIR)/$(GRCC_MACOSX_I64_TARGET)
GRCC_CROSS_COMPILE_CACHE_LINUX_I64_DIR=$(GRCC_CROSS_COMPILE_CACHE_DIR)/$(GRCC_LINUX_I64_TARGET)
GRCC_CROSS_COMPILE_CACHE_LINUX_I32_DIR=$(GRCC_CROSS_COMPILE_CACHE_DIR)/$(GRCC_LINUX_I32_TARGET)

grcc-test:
	cd rust && cargo test

grcc-debug:
	cd rust && cargo build

grcc-release:
	cd rust && cargo build --release

grcc-clean:
	rm -rf $(GRCC_GODOT_GDNATIVE_DIR)
	cd rust && (cargo clean || rm -rf ./target)
	rm -rf $(GRCC_CROSS_COMPILE_CACHE_DIR)

grcc-target-all: grcc-target-windows grcc-target-android grcc-target-macosx grcc-target-linux

grcc-target-windows: grcc-target-windows-i64

grcc-target-windows-i64:
	install -d $(GRCC_CROSS_COMPILE_CACHE_WINDOWS_I64_DIR)/git
	install -d $(GRCC_CROSS_COMPILE_CACHE_WINDOWS_I64_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_WINDOWS_I64_DIR)/git):/root/.cargo/git -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_WINDOWS_I64_DIR)/registry):/root/.cargo/registry -e C_INCLUDE_PATH=/usr/x86_64-w64-mingw32/include ufoot/godot-rust-cross-compile cargo build --release --target $(GRCC_WINDOWS_I64_TARGET)

grcc-target-android: grcc-target-android-arm64 grcc-target-android-arm32 grcc-target-android-i64 grcc-target-android-i32

grcc-target-android-arm64:
	install -d $(GRCC_CROSS_COMPILE_CACHE_ANDROID_ARM64_DIR)/git
	install -d $(GRCC_CROSS_COMPILE_CACHE_ANDROID_ARM64_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_ANDROID_ARM64_DIR)/git):/root/.cargo/git -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_ANDROID_ARM64_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(GRCC_ANDROID_ARM64_TARGET)

grcc-target-android-arm32:
	install -d $(GRCC_CROSS_COMPILE_CACHE_ANDROID_ARM32_DIR)/git
	install -d $(GRCC_CROSS_COMPILE_CACHE_ANDROID_ARM32_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_ANDROID_ARM32_DIR)/git):/root/.cargo/git -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_ANDROID_ARM32_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(GRCC_ANDROID_ARM32_TARGET)

grcc-target-android-i64:
	install -d $(GRCC_CROSS_COMPILE_CACHE_ANDROID_I64_DIR)/git
	install -d $(GRCC_CROSS_COMPILE_CACHE_ANDROID_I64_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_ANDROID_I64_DIR)/git):/root/.cargo/git -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_ANDROID_I64_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(GRCC_ANDROID_I64_TARGET)

grcc-target-android-i32:
	install -d $(GRCC_CROSS_COMPILE_CACHE_ANDROID_I32_DIR)/git
	install -d $(GRCC_CROSS_COMPILE_CACHE_ANDROID_I32_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_ANDROID_I32_DIR)/git):/root/.cargo/git -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_ANDROID_I32_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(GRCC_ANDROID_I32_TARGET)

grcc-target-macosx: grcc-target-macosx-i64

grcc-target-macosx-i64:
	install -d $(GRCC_CROSS_COMPILE_CACHE_MACOSX_I64_DIR)/git
	install -d $(GRCC_CROSS_COMPILE_CACHE_MACOSX_I64_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_MACOSX_I64_DIR)/git):/root/.cargo/git -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_MACOSX_I64_DIR)/registry):/root/.cargo/registry -e CC=/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin14-cc -e C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX10.10.sdk/usr/include ufoot/godot-rust-cross-compile cargo build --release --target $(GRCC_MACOSX_I64_TARGET)

grcc-target-linux: grcc-target-linux-i64 grcc-target-linux-i32

grcc-target-linux-i64:
	install -d $(GRCC_CROSS_COMPILE_CACHE_LINUX_I64_DIR)/git
	install -d $(GRCC_CROSS_COMPILE_CACHE_LINUX_I64_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_LINUX_I64_DIR)/git):/root/.cargo/git -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_LINUX_I64_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(GRCC_LINUX_I64_TARGET)

grcc-target-linux-i32:
	install -d $(GRCC_CROSS_COMPILE_CACHE_LINUX_I32_DIR)/git
	install -d $(GRCC_CROSS_COMPILE_CACHE_LINUX_I32_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_LINUX_I32_DIR)/git):/root/.cargo/git -v$$(realpath ../$(GRCC_CROSS_COMPILE_CACHE_LINUX_I32_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(GRCC_LINUX_I32_TARGET)

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

grcc-copy-all:
	install -d $(GRCC_WINDOWS_I64_DST) && cp $(GRCC_WINDOWS_I64_SRC) $(GRCC_WINDOWS_I64_DST)
	install -d $(GRCC_ANDROID_ARM64_DST) && cp $(GRCC_ANDROID_ARM64_SRC) $(GRCC_ANDROID_ARM64_DST)
	install -d $(GRCC_ANDROID_ARM32_DST) && cp $(GRCC_ANDROID_ARM32_SRC) $(GRCC_ANDROID_ARM32_DST)
	install -d $(GRCC_ANDROID_I64_DST) && cp $(GRCC_ANDROID_I64_SRC) $(GRCC_ANDROID_I64_DST)
	install -d $(GRCC_ANDROID_I32_DST) && cp $(GRCC_ANDROID_I32_SRC) $(GRCC_ANDROID_I32_DST)
	install -d $(GRCC_MACOSX_I64_DST) && cp $(GRCC_MACOSX_I64_SRC) $(GRCC_MACOSX_I64_DST)
	install -d $(GRCC_LINUX_I64_DST) && cp $(GRCC_LINUX_I64_SRC) $(GRCC_LINUX_I64_DST)
	install -d $(GRCC_LINUX_I32_DST) && cp $(GRCC_LINUX_I32_SRC) $(GRCC_LINUX_I32_DST)