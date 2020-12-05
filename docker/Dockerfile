# Inspired from:
# https://gist.github.com/extrawurst/ae3fd3ef152a878acfdc860db025e886
# https://github.com/godotengine/godot/blob/3.2/misc/dist/docker/scripts/install-android-tools

FROM ubuntu:focal

MAINTAINER Christian Mauduit "ufoot@ufoot.org"
LABEL package="godot-rust-cross-compile" version="0.2.1" description="An image to cross-compile to Android, Mac OS, etc. your Godot Rust-based libraries."

# Prepare the system, install Debian packages
# -------------------------------------------

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt-get install -yq \
    sudo curl wget git zip unzip \
    file g++ cmake pkg-config \
    libasound2-dev bison flex ant openjdk-8-jdk \
    lib32stdc++6 lib32z1 libssl-dev python \
    g++-multilib gcc-multilib libc6-dev-i386 \
    llvm-dev libclang-dev clang \
    libncurses5 libncurses5-dev \
    binutils-mingw-w64 gcc-mingw-w64 g++-mingw-w64 \
    libxml2-dev libz-dev \
    ca-certificates default-jre-headless \
    godot3 mono-devel \
    libsaxon-java nunit xvfb \
    vim \
    && apt-get clean

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Install android SDK
# -------------------

ARG ANDROID_BUILD_TOOLS_PATH=/opt/android-build-tools
WORKDIR $ANDROID_BUILD_TOOLS_PATH

ARG ANDROID_BASE_URL=https://dl.google.com/android

ARG ANDROID_SDK_RELEASE=android-sdk_r24.4.1
ARG ANDROID_SDK_DIR=android-sdk-linux
ARG ANDROID_SDK_FILENAME=$ANDROID_SDK_RELEASE-linux.tgz
ARG ANDROID_SDK_URL=$ANDROID_BASE_URL/$ANDROID_SDK_FILENAME
ARG ANDROID_SDK_PATH=$ANDROID_BUILD_TOOLS_PATH/$ANDROID_SDK_DIR

# https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz
RUN echo install $ANDROID_SDK_URL
RUN wget -q $ANDROID_SDK_URL && tar -xzf $ANDROID_SDK_FILENAME && rm $ANDROID_SDK_FILENAME

# Install android NDK
# -------------------

ARG ANDROID_NDK_RELEASE=android-ndk-r21d
ARG ANDROID_NDK_DIR=$ANDROID_NDK_RELEASE
ARG ANDROID_NDK_FILENAME=$ANDROID_NDK_RELEASE-linux-x86_64.zip
ARG ANDROID_NDK_URL=$ANDROID_BASE_URL/repository/$ANDROID_NDK_FILENAME
ARG ANDROID_NDK_PATH=$ANDROID_BUILD_TOOLS_PATH/$ANDROID_NDK_DIR

# https://dl.google.com/android/repository/android-ndk-r21d-linux-x86_64.zip
RUN echo install $ANDROID_NDK_URL
RUN wget -q $ANDROID_NDK_URL && unzip -q $ANDROID_NDK_FILENAME && rm $ANDROID_NDK_FILENAME

RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
ENV PATH /root/.cargo/bin:$PATH

# Install Rust
# ------------

RUN rustup target add \
    x86_64-pc-windows-gnu \
    i686-pc-windows-gnu \
    aarch64-linux-android \
    armv7-linux-androideabi \
    x86_64-linux-android \
    i686-linux-android \
    x86_64-apple-darwin \
    x86_64-unknown-linux-gnu \
    i686-unknown-linux-gnu

RUN mkdir /root/.cargo/git
RUN mkdir /root/.cargo/registry

# Configure Rust for Android cross-compiling
# ------------------------------------------

RUN echo "[target.aarch64-linux-android]" >> /root/.cargo/config
RUN find $ANDROID_NDK_PATH -name aarch64-linux-android21-clang++ -printf 'linker = "%p"\n' >> /root/.cargo/config
RUN echo >> /root/.cargo/config

RUN echo "[target.armv7-linux-androideabi]" >> /root/.cargo/config
RUN find $ANDROID_NDK_PATH -name armv7a-linux-androideabi21-clang++ -printf 'linker = "%p"\n' >> /root/.cargo/config
RUN echo >> /root/.cargo/config

RUN echo "[target.x86_64-linux-android]" >> /root/.cargo/config
RUN find $ANDROID_NDK_PATH -name x86_64-linux-android21-clang++ -printf 'linker = "%p"\n' >> /root/.cargo/config
RUN echo >> /root/.cargo/config

RUN echo "[target.i686-linux-android]" >> /root/.cargo/config
RUN find $ANDROID_NDK_PATH -name i686-linux-android21-clang++ -printf 'linker = "%p"\n' >> /root/.cargo/config
RUN echo >> /root/.cargo/config

ENV ANDROID_SDK_ROOT=$ANDROID_NDK_PATH
ENV PATH=$PATH:$ANDROID_SDK_PATH/tools:$ANDROID_NDK_PATH/build/tools

# Install OSX cross build env
# ---------------------------

ARG MACOSX_BUILD_TOOLS_PATH=/opt/macosx-build-tools
ARG OSXCROSS_PATH=$MACOSX_BUILD_TOOLS_PATH/osxcross
ARG OSXCROSS_COMMIT=7c090bd8cd4ad28cf332f1d02267630d8f333c19
ARG MACOSX_CROSS_COMPILER_PATH=$MACOSX_BUILD_TOOLS_PATH/cross-compiler
ARG MACOSX_SDK_BASE_URL=https://s3.dockerproject.org/darwin/v2
ARG MACOSX_SDK_FILENAME=MacOSX10.10.sdk.tar.xz
WORKDIR $MACOSX_BUILD_TOOLS_PATH
RUN git clone https://github.com/tpoechtrager/osxcross
WORKDIR $OSXCROSS_PATH
RUN git checkout $OSXCROSS_COMMIT
RUN echo install $MACOSX_SDK_BASE_URL/$MACOSX_SDK_FILENAME
RUN wget -q $MACOSX_SDK_BASE_URL/$MACOSX_SDK_FILENAME
RUN mv $MACOSX_SDK_FILENAME tarballs/
RUN UNATTENDED=yes OSX_VERSION_MIN=10.7 TARGET_DIR=$MACOSX_CROSS_COMPILER_PATH ./build.sh 2>&1 | tee build.log

# Configure Rust for Mac OS X cross-compiling
# -------------------------------------------

RUN echo "[target.x86_64-apple-darwin]" >> /root/.cargo/config
RUN find $MACOSX_CROSS_COMPILER_PATH -name x86_64-apple-darwin14-cc -printf 'linker = "%p"\n' >> /root/.cargo/config
RUN echo >> /root/.cargo/config

# Work in /build
# --------------

WORKDIR /build

# Example usage:
# docker run -v $(pwd):/build godot-rust-cross-compile cargo build --release --target aarch64-linux-android
# docker run -v $(pwd):/build godot-rust-cross-compile cargo build -v/tmp/.cargo/git:/root/.cargo/git -v/tmp/.cargo/registry:/root/.cargo/registry --release --target aarch64-linux-android
