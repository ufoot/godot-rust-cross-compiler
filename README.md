Godot Rust Cross Compiler
=========================

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
- ...

However, cross-compiling is hard, a lot of things can go wrong, it
involves programs and coding standards from different worlds, the
possible combination of software versions is litterally infinite,
and fine-tuning the whole process so that "it compiles" is not trivial.

So this project exposes:

* a dummy toy Godot application making use of the Godot rust bindings.
* a [docker image](https://hub.docker.com/repository/docker/ufoot/godot-rust-cross-compile) which can be used to compile the rust libraries on several platforms:
  * `x86_64-pc-windows-gnu`: MS-Windows, 64-bit Intel (standard Windows computers)
  * `aarch64-linux-android`: Android, 64-bit ARM (standard Android phones)
  * `armv7-linux-androideabi`: Android, 32-bit ARM (older Android phones)
  * `x86_64-linux-android`: Android, 64-bit Intel
  * `i686-linux-android`: Android, 32-bit Intel
  * `x86_64-apple-darwin`: Mac OS X, 64-bit Intel (standard Mac computers)
  * `x86_64-unknown-linux-gnu`: Linux, 64-bit Intel (standard Linux computers)
  * `i686-unknown-linux-gnu`: Linux, 32-bit Intel

The toy app can serve as an example on how to build an app with Godot and Rust.

The [docker image](https://hub.docker.com/repository/docker/ufoot/godot-rust-cross-compile) can be used to build your own projects, without having to setup the whole toolchain. It is just there, ready to use.

Cross Compiler Toy
------------------

The project is super simple, it is not even a game, it just links to
Rust and ensures the Rust code is actually called, for real. This is it.

The Godot project is in [./godot/](https://github.com/ufoot/godot-rust-cross-compiler/tree/master/godot) while the Rust source code is in [./rust/](https://github.com/ufoot/godot-rust-cross-compiler/tree/master/rust).

Also, the library itself it separated into 3 sub libraries:

* [cctoy](https://github.com/ufoot/godot-rust-cross-compiler/tree/master/rust/cctoy): this is the main library, the one which should be imported in the final Godot project. It is named `cctoy.dll`, `libcctoy.dylib` or `libcctoy.so` depending on the platform.
* [withgdnative](https://github.com/ufoot/godot-rust-cross-compiler/tree/master/rust/withgdnative): this library links on [gdnative](https://docs.rs/gdnative) but it is still a standard rust library. More precisely it does not have the `crate-type = ["cdylib"]` attribute in its `Cargo.toml` file. So it can happen that this builds but `cctoy` does not build. Problems typically happen at link time. As this one, contrary to `cctoy`, does not actually link with Godot code, it is easier to build. Very likely, in this code, you can use objects sur as Godot Nodes, but you can not instanciate and test them for real, as they might need some runtime context, which is only available withing Godot itself.
* [purelib](https://github.com/ufoot/godot-rust-cross-compiler/tree/master/rust/purelib): this library does not link on anything Godot specific, either native or not. This way it is easier to test if your Rust cross-compiler is working. It might happen that this builds, but `withgdnative` fails, typically because of a native compiler issue.

Of course, your own project does not need to replicate this specific setup.
I tend to like it because it is easier to spot problems when they appear,
and it encourages a minimal use of dependencies, avoiding that `import the world` hell.

Since the Godot project and the Rust source code are in different folders,
at some point, some magic is needed to tell Godot where the Rust libraries are.
There are many ways to do this, I chose to rely on a [Makefile](https://github.com/ufoot/godot-rust-cross-compiler/blob/master/Makefile) and copy
the files from one place to the other.

Long story made short: any time you make a change in the Rust code,
you need to issue a `make` command at the root of the repo.

This is tested under Linux and Mac OS X, I have no idea how it would
work for MS-Windows (help needed, I was not able to setup a working
environnement on MS-Windows).

Cross Compiler Docker Image
---------------------------

The [docker image](https://hub.docker.com/repository/docker/ufoot/godot-rust-cross-compile) is defined in
this [Dockerfile](https://github.com/ufoot/godot-rust-cross-compiler/blob/master/docker/Dockerfile)

Quick usage:

```sh
docker run -v $(pwd):/build ufoot/godot-rust-cross-compile cargo build --release --target aarch64-linux-android
```

This will build an arm64 build of a Rust library,
suitable for use on a typical Android phone.

Explanation:

* `docker run`: that runs [Docker](https://www.docker.com/)
* `-v $(pwd):/build`: this mounts the current work directory into `/build`. The image expects the code to be in `/build` so this is how your host communicates with the container. In other words anything which is in `./` on your computer will end up in `/build/` on the container, and this is where the compiler in invoked, within the container.
* `ufoot/godot-rust-cross-compile`: this is the name of the Docker image to call.
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
from Linux to Windows, Android, and Mac OS X.

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

[TODO...]

Building for Android
--------------------

[TODO...]

Building for Linux
------------------

[TODO...]
