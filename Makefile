
.PHONY: all
.PHONY: test
.PHONY: debug
.PHONY: release
.PHONY: target-all
.PHONY: target-windows
.PHONY: target-windows-i64
.PHONY: target-android
.PHONY: target-android-arm64
.PHONY: target-android-arm32
.PHONY: target-android-i64
.PHONY: target-android-i32
.PHONY: target-macosx
.PHONY: target-macosx-i64
.PHONY: target-linux
.PHONY: target-linux-i64
.PHONY: target-linux-i32
.PHONY: native
.PHONY: cross
.PHONY: copy-local
.PHONY: copy-if-exists
.PHONY: copy-all

all: native

native: test debug release copy-local copy-if-exists

cross: target-all copy-all

target-all: target-windows target-android target-macosx target-linux

WINDOWS_I64_TARGET=x86_64-pc-windows-gnu
ANDROID_ARM64_TARGET=aarch64-linux-android
ANDROID_ARM32_TARGET=armv7-linux-androideabi
ANDROID_I64_TARGET=x86_64-linux-android
ANDROID_I32_TARGET=i686-linux-android
MACOSX_I64_TARGET=x86_64-apple-darwin
LINUX_I64_TARGET=x86_64-unknown-linux-gnu
LINUX_I32_TARGET=i686-unknown-linux-gnu

LOCAL_DEBUG_SRC=./rust/target/debug/libcctoy.so
LOCAL_RELEASE_SRC=./rust/target/release/libcctoy.so

WINDOWS_I64_SRC=./rust/target/$(WINDOWS_I64_TARGET)/release/cctoy.dll
WINDOWS_I64_DST=./godot/gdnative/windows/$(WINDOWS_I64_TARGET)/
ANDROID_ARM64_SRC=./rust/target/$(ANDROID_ARM64_TARGET)/release/libcctoy.so
ANDROID_ARM64_DST=./godot/gdnative/android/$(ANDROID_ARM64_TARGET)/
ANDROID_ARM32_SRC=./rust/target/$(ANDROID_ARM32_TARGET)/release/libcctoy.so
ANDROID_ARM32_DST=./godot/gdnative/android/$(ANDROID_ARM32_TARGET)/
ANDROID_I64_SRC=./rust/target/$(ANDROID_I64_TARGET)/release/libcctoy.so
ANDROID_I64_DST=./godot/gdnative/android/$(ANDROID_I64_TARGET)/
ANDROID_I32_SRC=./rust/target/$(ANDROID_I32_TARGET)/release/libcctoy.so
ANDROID_I32_DST=./godot/gdnative/android/$(ANDROID_I32_TARGET)/
MACOSX_I64_SRC=./rust/target/$(MACOSX_I64_TARGET)/release/libcctoy.dylib
MACOSX_I64_DST=./godot/gdnative/macosx/$(MACOSX_I64_TARGET)/
LINUX_I64_SRC=./rust/target/$(LINUX_I64_TARGET)/release/libcctoy.so
LINUX_I64_DST=./godot/gdnative/linux/$(LINUX_I64_TARGET)/
LINUX_I32_SRC=./rust/target/$(LINUX_I32_TARGET)/release/libcctoy.so
LINUX_I32_DST=./godot/gdnative/linux/$(LINUX_I32_TARGET)/

CROSS_COMPILE_DIR=./.cross-compile
CROSS_COMPILE_WINDOWS_I64_DIR=$(CROSS_COMPILE_DIR)/$(WINDOWS_I64_TARGET)
CROSS_COMPILE_ANDROID_ARM64_DIR=$(CROSS_COMPILE_DIR)/$(ANDROID_ARM64_TARGET)
CROSS_COMPILE_ANDROID_ARM32_DIR=$(CROSS_COMPILE_DIR)/$(ANDROID_ARM32_TARGET)
CROSS_COMPILE_ANDROID_I64_DIR=$(CROSS_COMPILE_DIR)/$(ANDROID_I64_TARGET)
CROSS_COMPILE_ANDROID_I32_DIR=$(CROSS_COMPILE_DIR)/$(ANDROID_I32_TARGET)
CROSS_COMPILE_MACOSX_I64_DIR=$(CROSS_COMPILE_DIR)/$(MACOSX_I64_TARGET)
CROSS_COMPILE_LINUX_I64_DIR=$(CROSS_COMPILE_DIR)/$(LINUX_I64_TARGET)
CROSS_COMPILE_LINUX_I32_DIR=$(CROSS_COMPILE_DIR)/$(LINUX_I32_TARGET)

test:
	cd rust && cargo test

debug:
	cd rust && cargo build

release:
	cd rust && cargo build --release

target-all: target-windows target-android target-macosx target-linux

target-windows: target-windows-i64

target-windows-i64:
	install -d $(CROSS_COMPILE_WINDOWS_I64_DIR)/git
	install -d $(CROSS_COMPILE_WINDOWS_I64_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(CROSS_COMPILE_WINDOWS_I64_DIR)/git):/root/.cargo/git -v$$(realpath ../$(CROSS_COMPILE_WINDOWS_I64_DIR)/registry):/root/.cargo/registry -e C_INCLUDE_PATH=/usr/x86_64-w64-mingw32/include ufoot/godot-rust-cross-compile cargo build --release --target $(WINDOWS_I64_TARGET)

target-android: target-android-arm64 target-android-arm32 target-android-i64 target-android-i32

target-android-arm64:
	install -d $(CROSS_COMPILE_ANDROID_ARM64_DIR)/git
	install -d $(CROSS_COMPILE_ANDROID_ARM64_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(CROSS_COMPILE_ANDROID_ARM64_DIR)/git):/root/.cargo/git -v$$(realpath ../$(CROSS_COMPILE_ANDROID_ARM64_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(ANDROID_ARM64_TARGET)

target-android-arm32:
	install -d $(CROSS_COMPILE_ANDROID_ARM32_DIR)/git
	install -d $(CROSS_COMPILE_ANDROID_ARM32_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(CROSS_COMPILE_ANDROID_ARM32_DIR)/git):/root/.cargo/git -v$$(realpath ../$(CROSS_COMPILE_ANDROID_ARM32_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(ANDROID_ARM32_TARGET)

target-android-i64:
	install -d $(CROSS_COMPILE_ANDROID_I64_DIR)/git
	install -d $(CROSS_COMPILE_ANDROID_I64_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(CROSS_COMPILE_ANDROID_I64_DIR)/git):/root/.cargo/git -v$$(realpath ../$(CROSS_COMPILE_ANDROID_I64_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(ANDROID_I64_TARGET)

target-android-i32:
	install -d $(CROSS_COMPILE_ANDROID_I32_DIR)/git
	install -d $(CROSS_COMPILE_ANDROID_I32_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(CROSS_COMPILE_ANDROID_I32_DIR)/git):/root/.cargo/git -v$$(realpath ../$(CROSS_COMPILE_ANDROID_I32_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(ANDROID_I32_TARGET)

target-macosx: target-macosx-i64

target-macosx-i64:
	install -d $(CROSS_COMPILE_MACOSX_I64_DIR)/git
	install -d $(CROSS_COMPILE_MACOSX_I64_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(CROSS_COMPILE_MACOSX_I64_DIR)/git):/root/.cargo/git -v$$(realpath ../$(CROSS_COMPILE_MACOSX_I64_DIR)/registry):/root/.cargo/registry -e CC=/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin14-cc -e C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX10.10.sdk/usr/include ufoot/godot-rust-cross-compile cargo build --release --target $(MACOSX_I64_TARGET)

target-linux: target-linux-i64 target-linux-i32

target-linux-i64:
	install -d $(CROSS_COMPILE_LINUX_I64_DIR)/git
	install -d $(CROSS_COMPILE_LINUX_I64_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(CROSS_COMPILE_LINUX_I64_DIR)/git):/root/.cargo/git -v$$(realpath ../$(CROSS_COMPILE_LINUX_I64_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(LINUX_I64_TARGET)

target-linux-i32:
	install -d $(CROSS_COMPILE_LINUX_I32_DIR)/git
	install -d $(CROSS_COMPILE_LINUX_I32_DIR)/registry
	cd rust && docker run -v $$(pwd):/build -v$$(realpath ../$(CROSS_COMPILE_LINUX_I32_DIR)/git):/root/.cargo/git -v$$(realpath ../$(CROSS_COMPILE_LINUX_I32_DIR)/registry):/root/.cargo/registry ufoot/godot-rust-cross-compile cargo build --release --target $(LINUX_I32_TARGET)

copy-local:
	if (uname -a | grep -i darwin) && (uname -a | grep -i x86_64); then install -d $(MACOSX_I64_DST) && cp $(LOCAL_DEBUG_SRC) $(MACOSX_I64_DST) ; fi
	if (uname -a | grep -i linux) && (uname -a | grep -i x86_64); then install -d $(LINUX_I64_DST) && cp $(LOCAL_DEBUG_SRC) $(LINUX_I64_DST) ; fi

copy-if-exists:
	if test -f $(WINDOWS_I64_SRC) ; then install -d $(WINDOWS_I64_DST) && cp $(WINDOWS_I64_SRC) $(WINDOWS_I64_DST) ; fi
	if test -f $(ANDROID_ARM64_SRC) ; then install -d $(ANDROID_ARM64_DST) && cp $(ANDROID_ARM64_SRC) $(ANDROID_ARM64_DST) ; fi
	if test -f $(ANDROID_ARM32_SRC) ; then install -d $(ANDROID_ARM32_DST) && cp $(ANDROID_ARM32_SRC) $(ANDROID_ARM32_DST) ; fi
	if test -f $(ANDROID_I64_SRC) ; then install -d $(ANDROID_I64_DST) && cp $(ANDROID_I64_SRC) $(ANDROID_I64_DST) ; fi
	if test -f $(ANDROID_I32_SRC) ; then install -d $(ANDROID_I32_DST) && cp $(ANDROID_I32_SRC) $(ANDROID_I32_DST) ; fi
	if test -f $(MACOSX_I64_SRC) ; then install -d $(MACOSX_I64_DST) && cp $(MACOSX_I64_SRC) $(MACOSX_I64_DST) ; fi
	if test -f $(LINUX_I64_SRC) ; then install -d $(LINUX_I64_DST) && cp $(LINUX_I64_SRC) $(LINUX_I64_DST) ; fi
	if test -f $(LINUX_I32_SRC) ; then install -d $(LINUX_I32_DST) && cp $(LINUX_I32_SRC) $(LINUX_I32_DST) ; fi

copy-all:
	install -d $(WINDOWS_I64_DST) && cp $(WINDOWS_I64_SRC) $(WINDOWS_I64_DST)
	install -d $(ANDROID_ARM64_DST) && cp $(ANDROID_ARM64_SRC) $(ANDROID_ARM64_DST)
	install -d $(ANDROID_ARM32_DST) && cp $(ANDROID_ARM32_SRC) $(ANDROID_ARM32_DST)
	install -d $(ANDROID_I64_DST) && cp $(ANDROID_I64_SRC) $(ANDROID_I64_DST)
	install -d $(ANDROID_I32_DST) && cp $(ANDROID_I32_SRC) $(ANDROID_I32_DST)
	install -d $(MACOSX_I64_DST) && cp $(MACOSX_I64_SRC) $(MACOSX_I64_DST)
	install -d $(LINUX_I64_DST) && cp $(LINUX_I64_SRC) $(LINUX_I64_DST)
	install -d $(LINUX_I32_DST) && cp $(LINUX_I32_SRC) $(LINUX_I32_DST)
