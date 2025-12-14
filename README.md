Godot Rust Cross Compiler
=========================

A Docker-based cross-compilation toolchain for building [Godot 4](https://godotengine.org) games with [Rust](https://www.rust-lang.org) using [godot-rust (gdext)](https://godot-rust.github.io/).

Version 0.3.0 - Godot 4 + GDExtension

What is this?
-------------

Cross-compiling Rust code that links with native libraries (like Godot's GDExtension) is notoriously difficult. You need working C/C++ cross-compilers with proper headers and libraries for each target platform.

This project provides:

1. **A Docker image** ([ufoot/godot-rust-cross-compiler](https://hub.docker.com/repository/docker/ufoot/godot-rust-cross-compiler)) with all cross-compilation toolchains pre-configured
2. **A toy Godot + Rust project** demonstrating the setup
3. **A reusable Makefile** (`grcc.mk`) to automate builds and exports

Supported Platforms
-------------------

The Docker image supports **11 build targets** across 4 platforms:

| Platform | Architecture | Rust Target | Notes |
|----------|-------------|-------------|-------|
| **Windows** | x86_64 | `x86_64-pc-windows-gnu` | Standard Windows PCs |
| **Windows** | ARM64 | `aarch64-pc-windows-gnullvm` | Windows on ARM (Surface Pro X, etc.) |
| **macOS** | x86_64 | `x86_64-apple-darwin` | Intel Macs |
| **macOS** | ARM64 | `aarch64-apple-darwin` | Apple Silicon (M1/M2/M3) |
| **Linux** | x86_64 | `x86_64-unknown-linux-gnu` | Standard Linux PCs |
| **Linux** | x86 (32-bit) | `i686-unknown-linux-gnu` | Legacy 32-bit Linux |
| **Linux** | ARM64 | `aarch64-unknown-linux-gnu` | Raspberry Pi 4, Linux ARM servers |
| **Android** | ARM64 | `aarch64-linux-android` | Modern Android phones/tablets |
| **Android** | ARM32 | `armv7-linux-androideabi` | Older Android devices |
| **Android** | x86_64 | `x86_64-linux-android` | Android emulators, Chromebooks |
| **Android** | x86 (32-bit) | `i686-linux-android` | Older Android emulators |

All targets are officially supported by Godot 4 export templates.

### Not Currently Supported

- **iOS**: Requires Xcode on macOS (cannot cross-compile from Linux)
- **Web/WASM**: Experimental in gdext, requires Rust code changes (`#[cfg]` attributes for WASM compatibility)

Quick Start
-----------

### Building for Android (ARM64)

```sh
cd your-rust-project
docker run -v $(pwd):/build ufoot/godot-rust-cross-compiler \
    cargo build --release --target aarch64-linux-android
```

### Building for Windows (x86_64)

```sh
docker run -v $(pwd):/build \
    -e C_INCLUDE_PATH=/usr/x86_64-w64-mingw32/include \
    ufoot/godot-rust-cross-compiler \
    cargo build --release --target x86_64-pc-windows-gnu
```

### Building for macOS (Apple Silicon)

```sh
docker run -v $(pwd):/build \
    -e CC=/opt/macosx-build-tools/cross-compiler/bin/aarch64-apple-darwin23-clang \
    -e C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX14.5.sdk/usr/include \
    ufoot/godot-rust-cross-compiler \
    cargo build --release --target aarch64-apple-darwin
```

Docker Image Details
--------------------

The image is based on **Ubuntu Noble (24.04)** and includes:

### Core Tools
- Rust stable with all 11 target toolchains
- GCC and Clang for native compilation
- MinGW-w64 for Windows x86_64 cross-compilation
- [llvm-mingw](https://github.com/mstorsjo/llvm-mingw) for Windows ARM64 cross-compilation
- `gcc-aarch64-linux-gnu` for Linux ARM64 cross-compilation

### Android SDK/NDK
- Android SDK with platform-tools and build-tools 34.0.0
- **Android NDK 23.2.8568313** (recommended by Godot 4)
- Android API level 21 minimum
- [bundletool](https://github.com/google/bundletool) for AAB (Android App Bundle) support
- Pre-configured debug keystore for development builds

### macOS Cross-Compilation
- [osxcross](https://github.com/tpoechtrager/osxcross) cross-compiler
- **macOS SDK 14.5** (supports both x86_64 and ARM64)
- Minimum deployment target: macOS 11.0

### Godot 4
- **Godot 4.3** (headless mode for CI)
- Export templates for all platforms
- Pre-configured editor settings for Android export

### Image Size
The image is large (~4GB compressed, ~10GB uncompressed) because it contains complete toolchains for all platforms. This is comparable to installing equivalent tools locally.

The Toy Project
---------------

The included toy project demonstrates a minimal Godot 4 + Rust setup:

```
godot-rust-cross-compiler/
├── godot/                    # Godot 4 project
│   ├── project.godot
│   ├── cctoy.gdextension     # GDExtension configuration
│   └── scenes/
├── rust/                     # Rust workspace
│   ├── Cargo.toml
│   ├── purelib/              # Pure Rust library (no Godot deps)
│   ├── withgodot/            # Uses gdext types (not cdylib)
│   └── cctoy/                # The actual GDExtension library
├── grcc.mk                   # Reusable Makefile
└── Makefile                  # Project-specific config
```

### Rust Library Structure

The Rust code is split into three crates to isolate potential build issues:

1. **purelib**: Pure Rust with no dependencies. If this fails, your Rust cross-compiler is broken.

2. **withgodot**: Uses `godot` crate types but is a regular library (not `cdylib`). If this fails but purelib succeeds, the issue is with godot-rust bindings.

3. **cctoy**: The actual GDExtension (`cdylib`). If this fails but withgodot succeeds, the issue is at link time with platform-specific libraries.

### GDExtension Configuration

The `cctoy.gdextension` file maps Rust targets to Godot platforms:

```ini
[configuration]
entry_symbol = "gdext_rust_init"
compatibility_minimum = 4.1
reloadable = true

[libraries]
macos.debug.arm64 = "res://gdnative/macosx/aarch64-apple-darwin/libcctoy.dylib"
windows.debug.x86_64 = "res://gdnative/windows/x86_64-pc-windows-gnu/cctoy.dll"
linux.debug.x86_64 = "res://gdnative/linux/x86_64-unknown-linux-gnu/libcctoy.so"
android.debug.arm64 = "res://gdnative/android/aarch64-linux-android/libcctoy.so"
# ... (see file for complete list)
```

Using the Makefile
------------------

The `grcc.mk` file automates common tasks. Include it in your project's Makefile:

```makefile
# Your Makefile
GRCC_GAME_PKG_NAME=mygame
GRCC_GAME_PKG_VERSION=1.0.0
GRCC_GODOT_RUST_LIB_NAME=mygame
GRCC_GAME_REPO_NAME=mygame

include grcc.mk

all: grcc-all
test: grcc-test
clean: grcc-clean
native: grcc-native
cross: grcc-cross
export: grcc-export
```

### Available Targets

| Target | Description |
|--------|-------------|
| `make native` | Build and test locally, copy library for local Godot |
| `make cross` | Build for all cross-compilation targets |
| `make export` | Build and export packages for all platforms |
| `make test` | Run Rust tests |
| `make clean` | Clean all build artifacts |

### Individual Platform Targets

```sh
make grcc-lib-windows        # Windows x64 + ARM64
make grcc-lib-windows-x64    # Windows x64 only
make grcc-lib-windows-arm64  # Windows ARM64 only
make grcc-lib-android        # All Android architectures
make grcc-lib-macosx         # macOS x64 + ARM64
make grcc-lib-linux          # Linux x64 + x32 + ARM64
```

### Docker Detection

The Makefile automatically detects if it's running inside the Docker container (by checking for `/opt/godot-rust-cross-compiler.txt`). This allows CI pipelines to use the same targets whether running locally with Docker or directly in the container.

Caching Builds
--------------

To avoid re-downloading dependencies on every build, mount cargo cache directories:

```sh
install -d /tmp/.cargo/git /tmp/.cargo/registry  # Once

docker run \
    -v $(pwd):/build \
    -v /tmp/.cargo/git:/root/.cargo/git \
    -v /tmp/.cargo/registry:/root/.cargo/registry \
    ufoot/godot-rust-cross-compiler \
    cargo build --release --target aarch64-linux-android
```

The `grcc.mk` Makefile does this automatically using `target/cross-compiler-cache/`.

Rust Configuration
------------------

The Docker image pre-configures `~/.cargo/config.toml` with linkers for all targets:

```toml
[target.aarch64-linux-android]
linker = "/opt/android-build-tools/android-sdk/ndk/23.2.8568313/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang"

[target.x86_64-apple-darwin]
linker = "/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin23-clang"

[target.aarch64-apple-darwin]
linker = "/opt/macosx-build-tools/cross-compiler/bin/aarch64-apple-darwin23-clang"

[target.aarch64-pc-windows-gnullvm]
linker = "/opt/llvm-mingw/bin/aarch64-w64-mingw32-clang"

[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"
```

Environment Variables
---------------------

Some targets require environment variable overrides:

| Target | Required Variables |
|--------|-------------------|
| Windows x64 | `C_INCLUDE_PATH=/usr/x86_64-w64-mingw32/include` |
| macOS x64 | `CC=/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin23-clang`<br>`C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX14.5.sdk/usr/include` |
| macOS ARM64 | `CC=/opt/macosx-build-tools/cross-compiler/bin/aarch64-apple-darwin23-clang`<br>`C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX14.5.sdk/usr/include` |

Android, Linux, and Windows ARM64 targets work without additional environment variables.

CI/CD Integration
-----------------

The Docker image works with any CI system that supports Docker:

```yaml
# GitHub Actions example
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ufoot/godot-rust-cross-compiler
    steps:
      - uses: actions/checkout@v4
      - run: make cross
      - run: make export
```

```yaml
# GitLab CI example
build:
  image: ufoot/godot-rust-cross-compiler
  script:
    - make cross
    - make export
```

Exported Packages
-----------------

The `make export` target creates distribution-ready packages:

| Platform | Output | Format |
|----------|--------|--------|
| Windows | `export/mygame-windows-v1.0.0.zip` | ZIP with .exe and .dll |
| macOS | `export/mygame-macosx-v1.0.0.zip` | ZIP with .app bundle |
| Linux | `export/mygame-linux-v1.0.0.tar.gz` | Tarball with executable and .so |
| Android | `export/mygame-android-v1.0.0.apk` | Unsigned APK |
| Source | `export/mygame-1.0.0.tar.gz` | Source tarball |

**Note**: Android APKs are signed with a debug key. For production releases, you'll need to sign with your own keystore.

Troubleshooting
---------------

### "Can't open GDExtension dynamic library"

The library isn't in the path specified by your `.gdextension` file. Run `make native` to build and copy the library.

### Link errors on macOS targets

Make sure you're setting both `CC` and `C_INCLUDE_PATH` environment variables. The `grcc.mk` Makefile handles this automatically.

### Android NDK version mismatch

The image uses NDK 23.2.8568313, which is the version recommended by Godot 4. Using a different NDK version may cause linker errors.

### "TargetConditionals.h not found"

You're missing the macOS SDK headers. Set `C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX14.5.sdk/usr/include`.

### Files owned by root

Docker runs as root, so generated files may be owned by root on your host. Use `sudo chown -R $(whoami) .` or run Docker with `--user $(id -u):$(id -g)`.

Migration from Godot 3
----------------------

This version (0.3.0) targets Godot 4. Key changes from the Godot 3 version:

1. **GDNative → GDExtension**: Replace `.gdnlib` files with `.gdextension`
2. **gdnative crate → godot crate**: Update Rust dependencies
3. **API changes**: `#[derive(NativeClass)]` → `#[derive(GodotClass)]`, etc.
4. **Export commands**: `--export` → `--export-release`, `godot_headless` → `godot --headless`

See the [godot-rust book](https://godot-rust.github.io/book/gdext/intro/migration.html) for detailed migration guidance.

Building the Docker Image
-------------------------

To build the image locally:

```sh
cd docker
./build.sh
```

The build takes significant time (30-60 minutes) as it compiles osxcross and downloads all SDKs.

Bugs and Limitations
--------------------

- No iOS support (requires Xcode)
- No Web/WASM support (experimental in gdext)
- Runs as root in container
- Android APKs are debug-signed only

Resources
---------

- [godot-rust book](https://godot-rust.github.io/book/)
- [Godot GDExtension docs](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/index.html)
- [osxcross](https://github.com/tpoechtrager/osxcross)
- [Android NDK](https://developer.android.com/ndk)
- [llvm-mingw](https://github.com/mstorsjo/llvm-mingw)

License
-------

[MIT](https://github.com/ufoot/godot-rust-cross-compiler/blob/master/LICENSE.txt)

```
Copyright (c) 2020-2024 Christian Mauduit <ufoot@ufoot.org>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
