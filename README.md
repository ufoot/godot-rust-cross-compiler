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

[TODO...]

Cross Compiler Docker Image
---------------------------

[TODO...]
