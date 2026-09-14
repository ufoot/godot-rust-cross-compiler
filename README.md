Godot Rust Cross Compiler
=========================

A Docker-based cross-compilation toolchain for building [Godot 4](https://godotengine.org) games with [Rust](https://www.rust-lang.org) using [godot-rust (gdext)](https://godot-rust.github.io/).

Version 0.3.1 - Godot 4 + GDExtension

What is this?
-------------

Cross-compiling Rust code that links with native libraries (like Godot's GDExtension) is notoriously difficult. You need working C/C++ cross-compilers with proper headers and libraries for each target platform.

This project provides:

1. **A Docker image** ([ufoot/godot-rust-cross-compiler](https://hub.docker.com/repository/docker/ufoot/godot-rust-cross-compiler)) with all cross-compilation toolchains pre-configured
2. **A toy Godot + Rust project** demonstrating the setup
3. **A reusable Makefile** (`grcc.mk`) to automate builds and exports

Supported Platforms
-------------------

The Docker image supports **11 build targets** across 5 platforms:

| Platform | Architecture | Rust Target | Notes |
|----------|-------------|-------------|-------|
| **Windows** | x86_64 | `x86_64-pc-windows-gnullvm` | Standard Windows PCs |
| **Windows** | ARM64 | `aarch64-pc-windows-gnullvm` | Windows on ARM (Surface Pro X, etc.) |
| **macOS** | x86_64 | `x86_64-apple-darwin` | Intel Macs |
| **macOS** | ARM64 | `aarch64-apple-darwin` | Apple Silicon (M1/M2/M3) |
| **Linux** | x86_64 | `x86_64-unknown-linux-gnu` | Standard Linux PCs |
| **Linux** | ARM64 | `aarch64-unknown-linux-gnu` | Raspberry Pi 4, Linux ARM servers |
| **Android** | ARM64 | `aarch64-linux-android` | Modern Android phones/tablets |
| **Android** | x86_64 | `x86_64-linux-android` | Android emulators, Chromebooks |
| **Android** | ARM32 | `armv7-linux-androideabi` | Older Android devices |
| **Android** | x86 (32-bit) | `i686-linux-android` | Older Android emulators |
| **Web** | WASM32 | `wasm32-unknown-emscripten` | Browsers (threads and nothreads builds) |

All targets are officially supported by Godot 4 export templates.

### Not Currently Supported

- **iOS**: Requires Xcode on macOS (cannot cross-compile from Linux)

Quick Start
-----------

The image is published per host architecture: use `:0.3.1-amd64` on x86_64
machines and `:0.3.1-arm64` on arm64 ones (Apple Silicon, ARM Linux). Both
provide the same targets; `grcc.mk` picks the right tag automatically.

### Building for Android (ARM64)

```sh
cd your-rust-project
docker run -v $(pwd):/build ufoot/godot-rust-cross-compiler:0.3.1-amd64 \
    cargo build --release --target aarch64-linux-android
```

### Building for Windows (x86_64)

```sh
docker run -v $(pwd):/build ufoot/godot-rust-cross-compiler:0.3.1-amd64 \
    cargo build --release --target x86_64-pc-windows-gnullvm
```

### Building for macOS (Apple Silicon)

```sh
docker run -v $(pwd):/build \
    -e CC=/opt/macosx-build-tools/cross-compiler/bin/aarch64-apple-darwin25.1-clang \
    -e C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX26.1.sdk/usr/include \
    ufoot/godot-rust-cross-compiler:0.3.1-amd64 \
    cargo build --release --target aarch64-apple-darwin
```

Docker Image Details
--------------------

The image is based on **Ubuntu Resolute (26.04)** and includes:

### Architectures
- `linux/amd64` and `linux/arm64` images, built natively and tagged
  `<version>-amd64` / `<version>-arm64` (plus `latest-amd64` / `latest-arm64`)
- Same cross targets on both; host-specific tools (llvm-mingw, Godot, Emscripten,
  JDK) are the native builds for each architecture

### Core Tools
- Rust stable with the 10 native cross targets, plus Rust `nightly-2026-06-01` (pinned, see `GRCC_WASM_NIGHTLY`) with `rust-src` and `wasm32-unknown-emscripten`
- [Emscripten](https://emscripten.org) 4.0.11 (the version Godot 4.7 web templates are built with)
- GCC and Clang for native compilation
- [llvm-mingw](https://github.com/mstorsjo/llvm-mingw) for Windows cross-compilation (x86_64 and ARM64)
- `gcc-aarch64-linux-gnu` for Linux ARM64 cross-compilation
- [binaryen](https://github.com/WebAssembly/binaryen) (`wasm-opt`) for WASM optimization

### Android SDK/NDK
- Android SDK with platform-tools, platform android-36 and build-tools 36.1.0
- **Android NDK r29 (29.0.14206865)** - the version Godot 4.7 Android templates are built with
- Android API level 24 minimum (Godot 4.7 `minSdk`)
- On arm64, where Google ships no NDK host toolchain, the NDK target files
  (sysroot, `libunwind.a`, compiler-rt builtins) are used with Ubuntu's clang/lld
  of the same LLVM major version (21) through `<triple><api>-clang` wrappers in
  `toolchains/llvm/prebuilt/linux-aarch64/bin` (see `docker/android-ndk-arm64-host.sh`)
- [bundletool](https://github.com/google/bundletool) for AAB (Android App Bundle) support
- Pre-configured debug keystore for development builds

### macOS Cross-Compilation
- [osxcross](https://github.com/tpoechtrager/osxcross) cross-compiler, `llvm` flavor (Ubuntu clang, llvm tools and `ld64.lld`; no cctools/ld64 build), same on amd64 and arm64
- `SDKROOT` points at the SDK so rustc does not try `xcrun`
- **macOS SDK 26.1** (supports both x86_64 and ARM64)
- Minimum deployment target: macOS 11.0
- `genisoimage` and `dmg` ([libdmg-hfsplus](https://github.com/mozilla/libdmg-hfsplus), Mozilla fork, built from source) for creating DMG disk images

### Windows Packaging
- [NSIS](https://nsis.sourceforge.io/) for creating Windows installers (.exe)

### Godot 4
- **Godot 4.7.2** (headless mode for CI)
- Export templates for all platforms (including Web/WASM)
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
macos.debug = "res://gdnative/macosx/universal/libcctoy.dylib"  # lipo of x86_64 + arm64
windows.debug.x86_64 = "res://gdnative/windows/x86_64-pc-windows-gnullvm/cctoy.dll"
linux.debug.x86_64 = "res://gdnative/linux/x86_64-unknown-linux-gnu/libcctoy.so"
android.debug.arm64 = "res://gdnative/android/aarch64-linux-android/libcctoy.so"
web.debug.wasm32 = "res://gdnative/web/wasm32-unknown-emscripten/cctoy.wasm"
web.debug.threads.wasm32 = "res://gdnative/web/wasm32-unknown-emscripten/cctoy.threads.wasm"
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
| `make grcc-sign-android-aab` | Google Play bundle: unsigned AAB via Gradle, then upload-key signature (amd64 image) |
| `make clean` | Clean all build artifacts |

### Individual Platform Targets

```sh
make grcc-lib-windows        # Windows x64 + ARM64
make grcc-lib-windows-x64    # Windows x64 only
make grcc-lib-windows-arm64  # Windows ARM64 only
make grcc-lib-android        # All Android architectures
make grcc-lib-macosx         # macOS x64 + ARM64, merged into a universal dylib with lipo
make grcc-lib-linux          # Linux x64 + x32 + ARM64
make grcc-lib-wasm           # Web: threaded + nothreads Emscripten side modules
```

### Overridable settings

Set these in your Makefile *before* `include grcc.mk`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `GRCC_DOCKER_ARCH` | `arm64` on aarch64/arm64 hosts, else `amd64` | image flavor; set `amd64` on an arm64 host to force emulation |
| `GRCC_DOCKER_VERSION` | `0.3.1` | image version |
| `GRCC_DOCKER_IMAGE` | `ufoot/godot-rust-cross-compiler:$(GRCC_DOCKER_VERSION)-$(GRCC_DOCKER_ARCH)` | image used for cross builds and exports |
| `GRCC_GODOT_HEADLESS` | `godot --headless` | Godot command used for exports |
| `GRCC_EXPORT_PRESET_WINDOWS_X64` … `_LINUX_ARM64` | `Windows Desktop x64`, `Windows Desktop arm64`, `Android`, `macOS`, `Linux x64`, `Linux arm64` | export preset names |
| `GRCC_GAME_PUBLISHER` | `Unknown Publisher` | NSIS installer publisher |
| `GRCC_KEYSTORE_DIR` | `.keystore` | project directory holding signing keys (keep it git-ignored; excluded from source packages, untouched by `make clean`) |
| `GRCC_ANDROID_DEBUG_KEYSTORE` | `$(GRCC_KEYSTORE_DIR)/debug.keystore` | debug key (`androiddebugkey`/`android`); falls back to the image's own if missing |
| `GRCC_ANDROID_RELEASE_KEYSTORE` | `$(GRCC_KEYSTORE_DIR)/release.keystore` | release/upload key, used only when `GRCC_ANDROID_RELEASE_KEYSTORE_PASSWORD` is set (environment only) and `GRCC_ANDROID_RELEASE_KEYSTORE_USER` gives the alias |
| `GODOT_ANDROID_KEYSTORE_{RELEASE,DEBUG}_{PATH,USER,PASSWORD}` | computed from the above | what Godot reads; set them yourself to bypass the logic (paths as seen in the container, project on `/build`) |

### macOS universal library

A macOS "universal" export copies every matching GDExtension library into the
app bundle by file name, so separate x86_64 and arm64 dylibs with the same name
clash. `grcc-lib-macosx` therefore merges them with `lipo` into
`godot/gdnative/macosx/universal/lib<name>.dylib`; reference that file from
`macos.debug` / `macos.release` without an architecture tag. `make native` on a
Mac also copies the local debug build there.

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
    ufoot/godot-rust-cross-compiler:0.3.1-amd64 \
    cargo build --release --target aarch64-linux-android
```

The `grcc.mk` Makefile does this automatically using `target/cross-compiler-cache/`.

Rust Configuration
------------------

The Docker image pre-configures `~/.cargo/config.toml` with linkers for all targets
(amd64 image shown; the arm64 image uses `prebuilt/linux-aarch64` for Android and
`x86_64-linux-gnu-gcc` for `x86_64-unknown-linux-gnu` instead):

```toml
[target.aarch64-linux-android]
linker = "/opt/android-build-tools/android-sdk/ndk/29.0.14206865/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android24-clang"

[target.x86_64-apple-darwin]
linker = "/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin25.1-clang"

[target.aarch64-apple-darwin]
linker = "/opt/macosx-build-tools/cross-compiler/bin/aarch64-apple-darwin25.1-clang"

[target.x86_64-pc-windows-gnullvm]
linker = "/opt/llvm-mingw/bin/x86_64-w64-mingw32-clang"

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
| macOS x64 | `CC=/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin25.1-clang`<br>`C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX26.1.sdk/usr/include` |
| macOS ARM64 | `CC=/opt/macosx-build-tools/cross-compiler/bin/aarch64-apple-darwin25.1-clang`<br>`C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX26.1.sdk/usr/include` |

Android, Linux and Windows targets work without additional environment variables.

### Web (WASM)

Web builds follow the [godot-rust web export guide](https://godot-rust.github.io/book/toolchain/export-web.html):

- target `wasm32-unknown-emscripten`, built with `cargo +nightly-2026-06-01 build -Zbuild-std`
- `emcc` on the `PATH`, same version as Godot's web templates (4.0.11 for Godot 4.7)
- `grcc-lib-wasm` builds the crate twice, into separate target dirs:
  - threaded (`-C link-args=-pthread -C target-feature=+atomics`), copied as `lib.threads.wasm`
  - nothreads (`--features nothreads`), copied as `lib.wasm`
- every crate depending on `godot` must enable `experimental-wasm` (an empty
  opt-in flag, harmless on other targets; `experimental-wasm-nothreads` does
  not imply it), and your GDExtension crate must declare `nothreads`:
  ```toml
  [dependencies]
  godot = { version = "0.5.5", features = ["experimental-wasm"] }

  [features]
  nothreads = ["godot/experimental-wasm-nothreads"]
  ```
  (forward `nothreads` to other workspace crates that depend on `godot`)
- the Web export preset needs *Extensions Support* on. With *Thread Support*
  off (recommended) the game runs on any static host; with it on, the server
  must send cross-origin isolation headers (itch.io does).

CI/CD Integration
-----------------

The Docker image works with any CI system that supports Docker:

```yaml
# GitHub Actions example
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ufoot/godot-rust-cross-compiler:0.3.1-amd64
    steps:
      - uses: actions/checkout@v4
      - run: make cross
      - run: make export
```

```yaml
# GitLab CI example
build:
  image: ufoot/godot-rust-cross-compiler:0.3.1-amd64
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
| Windows | `export/mygame-windows-v1.0.0-installer.exe` | NSIS installer |
| macOS | `export/mygame-macosx-v1.0.0.zip` | ZIP with .app bundle |
| macOS | `export/mygame-macosx-v1.0.0.dmg` | DMG disk image |
| Linux | `export/mygame-linux-v1.0.0.tar.gz` | Tarball with executable and .so |
| Android | `export/mygame-android-v1.0.0.apk` | Unsigned APK |
| Web | `export/mygame-web-v1.0.0.zip` | HTML5/WASM package |
| Source | `export/mygame-1.0.0.tar.gz` | Source tarball |

### Google Play (Android App Bundle)

Play takes an AAB, not an APK. `grcc-pkg-android-aab` exports
`export/<game>-android-v<version>-unsigned.aab` with an **"Android AAB"** preset
(*Use Gradle Build* on, *Export Format* AAB, *Signed* off), reinstalling Godot's
Android build template on each export (`godot/android/`, keep it git-ignored),
then checks it with `bundletool validate`. `grcc-sign-android-aab` adds the
**upload signature** with `jarsigner`, producing
`export/<game>-android-v<version>.aab`; Google Play App Signing then signs what
devices receive.

- Signing uses the release keystore (`.keystore/release.keystore` by default):
  `GRCC_ANDROID_RELEASE_KEYSTORE_USER=<alias> GRCC_ANDROID_RELEASE_KEYSTORE_PASSWORD=... make grcc-sign-android-aab`.
  Without the password the debug key is used, and the AAB is left unsigned
  (`CN=Android Debug` certificates are rejected by Play). `make grcc-check-android-signing`
  prints which key applies.
- Gradle's `aapt2` exists for x86_64 Linux only: AAB targets need the amd64
  image (`GRCC_DOCKER_ARCH=amd64` on arm64 hosts, emulated). `grcc-pkg-all`
  includes the AAB only on amd64.
- The Gradle home is cached in `target/cross-compiler-cache/gradle`; the first
  build downloads Gradle and its dependencies (network needed).

**Note**: Android APKs are signed with the release keystore when its password is set, else with the project (or image) debug keystore. In CI, write the keystore from a protected variable into `.keystore/` and set the password variables as protected variables too.

Troubleshooting
---------------

### "Can't open GDExtension dynamic library"

The library isn't in the path specified by your `.gdextension` file. Run `make native` to build and copy the library.

### Link errors on macOS targets

Make sure you're setting both `CC` and `C_INCLUDE_PATH` environment variables. The `grcc.mk` Makefile handles this automatically.

### Android NDK version mismatch

The image uses NDK r29 (29.0.14206865), the version Godot 4.7 is built against. Using a significantly older NDK version may cause linker errors.

### "TargetConditionals.h not found"

You're missing the macOS SDK headers. Set `C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX26.1.sdk/usr/include`.

### "Cannot export for universal or x86_64 if S3TC BPTC texture format is disabled"

Godot only imports the VRAM texture format preferred by the machine running the
editor unless told otherwise: the arm64 image cannot export macOS/Windows/Linux
x86_64, the amd64 image cannot export Android. Enable both in `project.godot`:

```ini
[rendering]

textures/vram_compression/import_s3tc_bptc=true
textures/vram_compression/import_etc2_astc=true
```

### Files owned by root

Commands in the image run as root. On Linux hosts the image entrypoint hands
files created under `/build` back to the owner of the mounted directory once the
command ends, so `make clean` works without sudo. Files left by older images (or
by a killed container) can be fixed with:

```sh
docker run --rm -v $(pwd):/build ufoot/godot-rust-cross-compiler:0.3.1-amd64 true
```

(use the `-arm64` tag on arm64; `true` does nothing, the entrypoint fixes ownership).

Migration from Godot 3
----------------------

This version (0.3.1) targets Godot 4. Key changes from the Godot 3 version:

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
./build.sh          # host architecture, tags 0.3.1-<arch> and latest-<arch>
./build.sh amd64    # or force one (non-native goes through QEMU: very slow)
./push.sh           # push the tags for the host architecture
```

Build each architecture on a native machine, then push from each.

The build takes significant time (30-60 minutes) as it compiles osxcross and downloads all SDKs.

Bugs and Limitations
--------------------

- No iOS support (requires Xcode)
- Web support in godot-rust is experimental; Rust panics abort the game in the browser
- Runs as root in container
- Android APKs are debug-signed unless a release keystore is provided
- Windows installers and macOS DMGs are unsigned
- On arm64 images, Godot Android exports with *Use Gradle Build* fail: Gradle's `aapt2` (and SDK `platform-tools`/`zipalign`) only exist for x86_64 Linux. Rust builds work; non-Gradle APK exports only need Java tools (`apksigner`) and are expected to work.

### Android on ARM64 Hosts

Google does not provide Android NDK toolchains for arm64 Linux hosts
([android/ndk#1440](https://github.com/android/ndk/issues/1440)). The arm64
image works around it by keeping only the NDK's target files and driving them
with Ubuntu's clang/lld, which must share the NDK's LLVM major version (21 for
NDK r29). When bumping the NDK or the base image, the build fails early if the
matching `clang-<major>`/`lld-<major>` is not installed.

If an arm64 build misbehaves, compare with the amd64 image under emulation:
`make cross GRCC_DOCKER_ARCH=amd64` (acceptable with Rosetta on macOS, slow
with QEMU on Linux).

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
Copyright (c) 2020-2025 Christian Mauduit <ufoot@ufoot.org>

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
