Godot Rust Cross Compiler
=========================

Status
------

[![Build Status](https://travis-ci.org/ufoot/godot-rust-cross-compiler.svg?branch=master)](https://travis-ci.org/ufoot/godot-rust-cross-compiler/branches)

What is this?
-------------

This is just a toy project to show how to cross-compile programs
on different platforms using [Godot](https://godotengine.org)
and [Rust](https://www.rust-lang.org). This is possible with the help
of [godot-rust](https://godot-rust.github.io/).

There are already plenty of resources on the Internet, to learn
how to do this yourself, included, but not limited to:

- https://godot-rust.github.io/book/exporting/android.html
- https://ghotiphud.github.io/rust/android/cross-compiling/2016/01/06/compiling-rust-to-android.html
- https://github.com/tpoechtrager/osxcross
- https://doc.rust-lang.org/cargo/reference/config.html
- https://gist.github.com/extrawurst/ae3fd3ef152a878acfdc860db025e886
- https://github.com/godotengine/godot/blob/3.2/misc/dist/docker/scripts/install-android-tools
- https://wapl.es/rust/2019/02/17/rust-cross-compile-linux-to-macos.html
- https://github.com/godot-rust/godot-rust/issues/647
- ...

However, cross-compiling is hard, a lot of things can go wrong, it
involves programs and coding standards from different worlds, the
possible combination of software versions is litterally infinite,
and fine-tuning the whole process so that "it compiles" is not trivial.

So this project exposes:

* a dummy toy Godot application making use of the Godot rust bindings.
* a [docker image](https://hub.docker.com/repository/docker/ufoot/godot-rust-cross-compiler) which can be used to compile the rust libraries on several platforms:
  * `x86_64-pc-windows-gnu`: MS-Windows, 64-bit Intel (standard Windows computers)
  * `aarch64-linux-android`: Android, 64-bit ARM (standard Android phones)
  * `armv7-linux-androideabi`: Android, 32-bit ARM (older Android phones)
  * `x86_64-linux-android`: Android, 64-bit Intel
  * `i686-linux-android`: Android, 32-bit Intel
  * `x86_64-apple-darwin`: Mac OS X, 64-bit Intel (standard Mac computers)
  * `x86_64-unknown-linux-gnu`: Linux, 64-bit Intel (standard Linux computers)
  * `i686-unknown-linux-gnu`: Linux, 32-bit Intel
  * `wasm32-unknown-emscripten`: WebAssembly, 32-bit

The toy app can serve as an example on how to build an app with Godot and Rust. When you launch it it shoud say something about a `msg from Rust`.

The [docker image](https://hub.docker.com/repository/docker/ufoot/godot-rust-cross-compiler) can be used to build your own projects, without having to setup the whole toolchain. It is huge, about 4Gb compressed, and 10Gb once installed. However, please consider that if you wanted to install an equivalent, complete local toolchain, it would very likely be as big.

Cross Compiler Toy
------------------

The project is super simple, it is not even a game, it just links to
Rust and ensures the Rust code is actually called, for real. This is it.

The Godot project is in [./godot/](https://github.com/ufoot/godot-rust-cross-compiler/tree/master/godot) while the Rust source code is in [./rust/](https://github.com/ufoot/godot-rust-cross-compiler/tree/master/rust).

Also, the library itself it separated into 3 sub libraries:

* [cctoy](https://github.com/ufoot/godot-rust-cross-compiler/tree/master/rust/cctoy): this is the main library, the one which should be imported in the final Godot project. It is named `cctoy.dll`, `libcctoy.dylib`, `cctoy.wasm` or `libcctoy.so` depending on the platform.
* [withgdnative](https://github.com/ufoot/godot-rust-cross-compiler/tree/master/rust/withgdnative): this library links on [gdnative](https://docs.rs/gdnative) but it is still a standard rust library. More precisely it does not have the `crate-type = ["cdylib"]` attribute in its `Cargo.toml` file. So it can happen that this builds but `cctoy` does not build. Problems typically happen at link time. As this one, contrary to `cctoy`, does not actually link with Godot code, it is easier to build. Very likely, in this code, you can use objects sur as Godot Nodes, but you can not instanciate and test them for real, as they might need some runtime context, which is only available withing Godot itself.
* [purelib](https://github.com/ufoot/godot-rust-cross-compiler/tree/master/rust/purelib): this library does not link on anything Godot specific, either native or not. This way it is easier to test if your Rust cross-compiler is working. It might happen that this builds, but `withgdnative` fails, typically because of a native compiler issue.

Of course, your own project does not need to replicate this specific setup.
I tend to like it because it is easier to spot problems when they appear,
and it encourages a minimal use of dependencies, avoiding that `import the world` hell.

Since the Godot project and the Rust source code are in different folders,
at some point, some magic is needed to tell Godot where the Rust libraries are.
There are many ways to do this, I chose to rely on a [Makefile](https://github.com/ufoot/godot-rust-cross-compiler/blob/master/grcc.mk) and copy
the files from one place to the other.

Long story made short: any time you make a change in the Rust code,
you need to issue a `make` command at the root of the repo.

This is tested under Linux and Mac OS X, I have no idea how it would
work for MS-Windows (help needed, I was not able to setup a working
environnement on MS-Windows).

Cross Compiler Docker Image
---------------------------

The [docker image](https://hub.docker.com/repository/docker/ufoot/godot-rust-cross-compiler) is defined in
this [Dockerfile](https://github.com/ufoot/godot-rust-cross-compiler/blob/master/docker/Dockerfile)

Quick usage:

```sh
# cd to your Rust source tree, where you would run `cargo build`
docker run -v $(pwd):/build ufoot/godot-rust-cross-compiler cargo build --release --target aarch64-linux-android
```

This will build an arm64 build of a Rust library,
suitable for use on a typical Android phone.

Explanation:

* `docker run`: that runs [Docker](https://www.docker.com/)
* `-v $(pwd):/build`: this mounts the current work directory into `/build`. The image expects the code to be in `/build` so this is how your host communicates with the container. In other words anything which is in `./` on your computer will end up in `/build/` on the container, and this is where the compiler in invoked, within the container.
* `ufoot/godot-rust-cross-compiler`: this is the name of the Docker image to call.
* `cargo build`: this is the standard [cargo](https://doc.rust-lang.org/cargo/) command used to build Rust programes. You could also issue `cargo test` or anything.
* `--release`: when cross-compiling, most of the time, you want to release something, debug mode is (usually) more for local testing. So a typical cross build has `--release` as flag, to tell the compiler to build the optimized version.
* `--target aarch64-linux-android`: this tells the compiler to compile for an Arm64 processor, running a Linux kernel, with an Android system. This is what you want to target recent Android phones.

But... wait, why do I need a dedicated image to do this? This simple command should do the job:

```sh
rustup target add aarch64-linux-android     # should be done just once
cargo build --target aarch64-linux-android  # use standard toolchain, plain simple
```

Well, if you just want to build some *pure Rust* code, this is all it takes.
Indeed Rust cross-platform support is amazing, and the above works,
on any platform able to run Rust.

However, in the specific case of [godot-rust](https://godot-rust.github.io/)
you need to compile and link a few bits of native code. Long story made short,
this is because Godot is not a pure Rust program, rather a C++ program
which supports Rust as an extension language.

Anyway, on top of being able to produce Rust compiled code for your target
platform, you also need to have a working standard C compiler,
typically [GCC](https://gcc.gnu.org/) or [Clang](https://clang.llvm.org/).
And *THIS* is where things get complex. Because there is no such thing
as a universal, easy-to-install, cross-platform compiler, with working
headers and libraries, which compiles
from Linux to Linux, Windows, Android, WebAssembly and Mac OS X.

As a side note, it is exactly because this is so hard that languages such
as [Rust](https://www.rust-lang.org) or [Go](https://golang.org/)
did invest so much energy into standard build toolchains.

So the docker image provided here just bundles, together on a single
image, some working cross-compilers, which options, headers and libraries
set up the right way to properly build your Godot + Rust application.

As a good side effect of using a Docker image, this can be re-used
in most CI systems such as [Travis](https://www.travis-ci.org) or
or [Gitlab](https://gitlab.com).

Building for Windows
--------------------

To build from the container to Windows, you need to specify
where the Windows specific headers are:

```sh
docker run -v $(pwd):/build -e C_INCLUDE_PATH=/usr/x86_64-w64-mingw32/include ufoot/godot-rust-cross-compiler cargo build --release --target x86_64-pc-windows-gnu
```

Please note that `-e C_INCLUDE_PATH=/usr/x86_64-w64-mingw32/include` option
which tells Docker to set the `C_INCLUDE_PATH` env var to the correct
path of `/usr/x86_64-w64-mingw32/include`, which in turns contains the
platform specific headers. Those are shipped with [mingw](http://mingw-w64.org)
so it is just a matter of installing the right `.deb` or `.rpm` package
and then setting this include path correctly.

Only 64-bit is supported for now, 32-bit linking raised errors.
Any help welcome.

Building for Android
--------------------

Initially, this is what motivated that image, as in practice for Android
cross-compiling is not an option, but a requirement.

Hopefully, the docker image makes it simple:

```sh
docker run -v $(pwd):/build cargo build ufoot/godot-rust-cross-compiler --release --target aarch64-linux-android
```

For Android, 4 architectures are supported:

  * `aarch64-linux-android`: Android, 64-bit ARM (standard Android phones)
  * `armv7-linux-androideabi`: Android, 32-bit ARM (older Android phones)
  * `x86_64-linux-android`: Android, 64-bit Intel
  * `i686-linux-android`: Android, 32-bit Intel

Under the hood, the Docker image does a few things:

* install the [Android SDK](https://developer.android.com/studio), which is not even that easy, as now it is supposed to be part of the Android Studio, but we have no interest in that fancy UI, just need a few core components.
* install the [Android NDK](https://developer.android.com/ndk), which is possibly the most important component as it contains the actual C compiler. *IMPORTANT NOTE* I spent a crazy amount of time trying to have GCC work, in the end I used Clang and it worked much more smoothly. I suspect GCC needs a bit of love and special options to properly find its headers and libraries.
* define the `JAVA_HOME` and `ANDROID_SDK_ROOT` env var.
* override the Rust linker so that it uses `clang` from the NDK, and not the default `ld` of the system. This is possibly the hardest step, as it is not very intuitive and examples are rare on the web. Basically what it amounts to is put in the file `$HOME/.cargo/config` a content like:

```toml
[target.aarch64-linux-android]
linker = "/opt/android-build-tools/android-ndk-r21d/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang++"

[target.armv7-linux-androideabi]
linker = "/opt/android-build-tools/android-ndk-r21d/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang++"

[target.x86_64-linux-android]
linker = "/opt/android-build-tools/android-ndk-r21d/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android21-clang++"

[target.i686-linux-android]
linker = "/opt/android-build-tools/android-ndk-r21d/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-clang++"
```

Note that depending on the versions, the NDK are organized in radically
different ways, so any change in the NDK version might require some
heavylifting change in all those scripts.

Building for Mac OS X
---------------------

In theory this should be simple, in practice it is hard because Apple
development toolkits are proprietary and uneasy to install outside OS X.

```sh
docker run -v $(pwd):/build -e CC=/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin14-cc -e C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX10.10.sdk/usr/include ufoot/godot-rust-cross-compiler cargo build --release --target x86_64-apple-darwin
```

So here, two overrides are needed:

* `-e CC=/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin14-cc`: this tells the system to use a specific, dedicated cross-compiler. Your standard GCC or Clang will not work.
* `-e C_INCLUDE_PATH=/opt/macosx-build-tools/cross-compiler/SDK/MacOSX10.10.sdk/usr/include`: gives the compiler a place to search for specific OS X headers. This solves the dreaded `fatal error: 'TargetConditionals.h' file not found` error.

Only 64-bit Intels are supported, 32-bit hardware are too old anyway
and backward compatibility does not even make sense for them, Apple
dropped any kind of practical support for them. No clue on how easy
or hard it will be to support the upcoming ARM architectures.

Under the hood, the Docker image does a few things:

* use [osxcross](https://github.com/tpoechtrager/osxcross) to install the cross-compiler. Without this, nothing would work.
* override the Rust linker so that it uses the linker provided by `osxcross`, and not the default `ld` of the system. Typically, `$HOME/.cargo/config` should contain:

```toml
[target.x86_64-apple-darwin]
linker = "/opt/macosx-build-tools/cross-compiler/bin/x86_64-apple-darwin14-cc"
```

The current build uses a SDK from [Mac OS X 10.10](https://en.wikipedia.org/wiki/OS_X_Yosemite) (Yosemite, 2014).

Building for Linux
------------------

Similar to other platforms:

```sh
docker run -v $(pwd):/build cargo build ufoot/godot-rust-cross-compiler --release --target x86_64-unknown-linux-gnu
```

Only Intel 64-bit and 32-bit are supported, mostly because those are
the only choices offered by the Godot Linux export template. But in theory,
any architecture should work, only the Rust toolchain bundled in the
containter does not support them as is.

Building for WebAssembly
--------------------

To build the library for WebAssembly:

```sh
docker run -v $(pwd):/build -e EMMAKEN_CFLAGS="-O1 -s STRICT=1 -s SIDE_MODULE=1" -e C_INCLUDE_PATH=/opt/emscripten-build-tools/emsdk/upstream/emscripten/cache/sysroot/include/ ufoot/godot-rust-cross-compiler -e RUSTFLAGS="-C link-args=-fPIC -C relocation-model=pic -C target-feature=+mutable-globals" cargo build --release --target wasm32-unknown-emscripten
```

Underneath it does a few things for you:

* git clone the [Emscripten SDK](https://github.com/emscripten-core/emsdk) repository.
* install and activate version 2.0.17 of the SDK.
* copy the `emcc-mod` script to be used as the linker.
* it also overrides the linker with the one found on the wasm toolchain directory in your `$HOME/.cargo/config` file:

```toml
[target.wasm32-unknown-emscripten]
linker = "/opt/emscripten-build-tools/bin/emcc-mod"
```

Example Makefile
----------------

While using the [docker image](https://hub.docker.com/repository/docker/ufoot/godot-rust-cross-compiler) saves time, in practice, on a real-world project,
manually giving options for compilers (think of Mac OS X or Windows which
require compiler or headers overrides) is tiring and error-prone.

Also most of the time once the library is compiled it is convenient to
have it installed in the right place within your Godot project.

To automate this, on the toy project, I have set up:

* a very simple [Makefile](https://github.com/ufoot/godot-rust-cross-compiler/blob/master/Makefile)
* which includes another Makefile named [grcc.mk](https://github.com/ufoot/godot-rust-cross-compiler/blob/master/grcc.mk)

Use at your own risk, I know Makefiles are not trendy, there are many
other tools such as [SCons](https://www.scons.org/), [Ninja](https://ninja-build.org/), [Rake](http://docs.seattlerb.org/rake/), [Gradle](https://gradle.org/), [Bazel](https://bazel.build/), etc. I have used those, some of them with "professional proficiency" but for the sake of building small Godot Rust apps, I think good old [GNU Make](https://www.gnu.org/software/make/) is good enough.

Think of this as [an example](https://github.com/ufoot/godot-rust-cross-compiler/blob/master/grcc.mk) of how to use the docker image. A typical usage would beto put in your main `Makefile`:

```mk
# replace cctoy with the name of your package
GRCC_GAME_PKG_NAME=cctoy
include grcc.mk
```

Another feature of this `Makefile`: it detects whether `/opt/godot-rust-cross-compiler.txt` is present,
and if it is there, it does not launch docker but builds natively. This way, a CI script can invoke
the targets as you would locally, without "running docker within docker".

It also has some basic packaging, making `.zip`, `.apk` or `.tar.gz` files
which are hopefully "ready to distribute". A few caveats though:

* projects are expected to embed the `.pck` within the executable (relevant for Windows and Linux).
* android packages are not signed.

Caching builds
--------------

Using the docker image, a fresh `$HOME` directory is used at each start,
and this causes `cargo` to actually pull dependencies and rebuild them
at each build. This slows down things, especially when your project
grows in size and deps.

A workaround (used in the [example Makefile](https://github.com/ufoot/godot-rust-cross-compiler/blob/master/grcc.mk) is to mount `$HOME/.cargo/git` and `$HOME/.cargo/registry` to local folders on your host. For example:

```sh
install -d /tmp/.cargo/git       # run this only once
install -d /tmp/.cargo/registry  # run this only once
docker run -v $(pwd):/build ufoot/godot-rust-cross-compiler -v/tmp/.cargo/git:/root/.cargo/git -v/tmp/.cargo/registry:/root/.cargo/registry ufoot/godot-rust-cross-compiler cargo build --release --target aarch64-linux-android
```

Extra bounties
--------------

On top of the C cross-compilers, the [docker image](https://hub.docker.com/repository/docker/ufoot/godot-rust-cross-compiler) bundles a few tools which can
prove useful:

* [mono](https://www.mono-project.com/): this way you can compile [C#](https://docs.microsoft.com/en-us/dotnet/csharp/) code.
* [nunit](https://nunit.org/): this is a standard unit test framework, having it installed makes it possible to test [C#](https://docs.microsoft.com/en-us/dotnet/csharp/) code which does not need the whole Godot context.
* [Xvfb](https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml): this is a virtual framebuffer X server, it can be used to actually launch a real Godot program on a CI server. Sometimes running headless is enough, but sometimes you want to test the real thing. Xvfb makes this possible.
* [uber-apk-signer](https://github.com/patrickfav/uber-apk-signer): this tool helps signing Android APKs. While it is not strictly required to build and even sign a package, it is lightweight and really handy to have.
* [vim](https://www.vim.org/): because being stuck in a container with no proper editor is no fun.
* [Godot](https://godotengine.org) in 6 flavors (with/without Mono support, and with default, headless and server variants), so that you can easily run tests, export builds, etc.
* [Godot export templates](https://docs.godotengine.org/en/stable/getting_started/workflow/export/exporting_projects.html), so that you can run `godot_headless --export` and build final end-user friendly packages from CI.

Bugs and limitations
--------------------

* only a few archs supported, more specifically:
  * no iOS support
  * 32-bit support not working on Windows
* everything runs as `root` in the container, consequently some files might be generated as `user:root` on your system, cleaning them requires `sudo` or other inconvenient hacks
* `[YOUR BUG HERE]`

License
-------

[MIT](https://github.com/ufoot/godot-rust-cross-compiler/blob/master/LICENSE.txt)

```
Copyright (c) 2020 Christian Mauduit <ufoot@ufoot.org>

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
