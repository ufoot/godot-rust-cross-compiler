How does this work?
===================

Read carefully [the godot-rust on how to export to android](https://godot-rust.github.io/book/exporting/android.html).

It should just work. However it involves Rust, part of your system C headers and compiler,
as well as the version of the Android SDK and NDK you are using. All these components are
moving ground and evolving fast with time. So it is possible that you get errors due
to the many possible combinations here.

To help with this, I provide a Docker image, heavily inspired from
[this gist](https://gist.github.com/extrawurst/ae3fd3ef152a878acfdc860db025e886).

To use it:

```
# change to your source tree, where you would issue a cargo build, then:
docker run -v $(pwd):/build godot-rust-cross-compile cargo build --release --target aarch64-linux-android
docker run -v $(pwd):/build godot-rust-cross-compile cargo build --release --target arm-linux-androideabi
docker run -v $(pwd):/build godot-rust-cross-compile cargo build --release --target i686-linux-android
docker run -v $(pwd):/build godot-rust-cross-compile cargo build --release --target x86_64-linux-android
```

Image is [published on dockerhub](https://hub.docker.com/repository/docker/ufoot/godot-rust-cross-compile/).
