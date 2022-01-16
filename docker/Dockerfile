# Godot Rust Cross Compiler
# -------------------------
#
# See https://github.com/ufoot/godot-rust-cross-compiler for details

FROM ubuntu:focal

MAINTAINER Christian Mauduit "ufoot@ufoot.org"
ENV GRCC_VERSION=0.2.3
LABEL package="godot-rust-cross-compiler" version="$GRCC_VERSION" description="An image to cross-compile to Windows, Android, Mac OS X and Linux your godot-rust based libraries."

# Prepare the system, install Debian packages
# -------------------------------------------

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt-get install -yq \
    sudo curl wget git zip unzip \
    file g++ cmake pkg-config \
    libasound2-dev bison flex \
    ant openjdk-8-jdk adb \
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
#    binutils build-essential \
#    python3 python3-pip \
    && apt-get clean

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Install android SDK
# -------------------

ARG ANDROID_BUILD_TOOLS_PATH=/opt/android-build-tools
WORKDIR $ANDROID_BUILD_TOOLS_PATH

ARG ANDROID_BASE_URL=https://dl.google.com/android

ENV ANDROID_SDK_RELEASE=android-sdk_r24.4.1
ARG ANDROID_SDK_DIR=android-sdk-linux
ARG ANDROID_SDK_FILENAME=$ANDROID_SDK_RELEASE-linux.tgz
ARG ANDROID_SDK_URL=$ANDROID_BASE_URL/$ANDROID_SDK_FILENAME
ARG ANDROID_SDK_PATH=$ANDROID_BUILD_TOOLS_PATH/$ANDROID_SDK_DIR

RUN wget -nc -nv $ANDROID_SDK_URL && tar -xzf $ANDROID_SDK_FILENAME && rm $ANDROID_SDK_FILENAME

# Install android NDK
# -------------------

ENV ANDROID_NDK_RELEASE=android-ndk-r21d
ARG ANDROID_NDK_DIR=$ANDROID_NDK_RELEASE
ARG ANDROID_NDK_FILENAME=$ANDROID_NDK_RELEASE-linux-x86_64.zip
ARG ANDROID_NDK_URL=$ANDROID_BASE_URL/repository/$ANDROID_NDK_FILENAME
ARG ANDROID_NDK_PATH=$ANDROID_BUILD_TOOLS_PATH/$ANDROID_NDK_DIR
ARG ANDROID_NDK_GCC_VERSION=4.9

RUN wget -nc -nv $ANDROID_NDK_URL && unzip -q $ANDROID_NDK_FILENAME && rm $ANDROID_NDK_FILENAME && rm -rf $ANDROID_NDK_PATH/toolchains/*-$ANDROID_NDK_GCC_VERSION

RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
ENV PATH /root/.cargo/bin:$PATH

# Install uber APK signer
# -----------------------

ARG UBER_APK_SIGNER_VERSION=1.2.1
ARG UBER_APK_SIGNER_BASE_URL=https://github.com/patrickfav/uber-apk-signer/releases/download/v$UBER_APK_SIGNER_VERSION
ARG UBER_APK_SIGNER_FILENAME=uber-apk-signer-$UBER_APK_SIGNER_VERSION.jar
ARG UBER_APK_SIGNER_URL=$UBER_APK_SIGNER_BASE_URL/$UBER_APK_SIGNER_FILENAME
WORKDIR $ANDROID_BUILD_TOOLS_PATH
RUN wget -nc -nv $UBER_APK_SIGNER_URL && ln -s $UBER_APK_SIGNER_FILENAME uber-apk-signer.jar

# Install Rust
# ------------

RUN rustup target add \
    x86_64-pc-windows-gnu \
    aarch64-linux-android \
    armv7-linux-androideabi \
    x86_64-linux-android \
    i686-linux-android \
    x86_64-apple-darwin \
    x86_64-unknown-linux-gnu \
    i686-unknown-linux-gnu \
    wasm32-unknown-emscripten

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

# Install OSX cross build env
# ---------------------------

ARG MACOSX_BUILD_TOOLS_PATH=/opt/macosx-build-tools
ARG OSXCROSS_PATH=$MACOSX_BUILD_TOOLS_PATH/osxcross
ARG OSXCROSS_COMMIT=7c090bd8cd4ad28cf332f1d02267630d8f333c19
ARG MACOSX_CROSS_COMPILER_PATH=$MACOSX_BUILD_TOOLS_PATH/cross-compiler
ARG MACOSX_SDK_BASE_URL=https://s3.dockerproject.org/darwin/v2
ENV MACOSX_SDK_VERSION=10.10
ARG MACOSX_SDK_FILENAME=MacOSX$MACOSX_SDK_VERSION.sdk.tar.xz
WORKDIR $MACOSX_BUILD_TOOLS_PATH
RUN git clone https://github.com/tpoechtrager/osxcross
WORKDIR $OSXCROSS_PATH
RUN git checkout $OSXCROSS_COMMIT
RUN echo install $MACOSX_SDK_BASE_URL/$MACOSX_SDK_FILENAME
RUN wget -nc -nv $MACOSX_SDK_BASE_URL/$MACOSX_SDK_FILENAME
RUN mv $MACOSX_SDK_FILENAME tarballs/
RUN UNATTENDED=yes OSX_VERSION_MIN=10.7 TARGET_DIR=$MACOSX_CROSS_COMPILER_PATH ./build.sh 2>&1 | tee build.log

# Configure Rust for Mac OS X cross-compiling
# -------------------------------------------

RUN echo "[target.x86_64-apple-darwin]" >> /root/.cargo/config
RUN find $MACOSX_CROSS_COMPILER_PATH -name x86_64-apple-darwin14-cc -printf 'linker = "%p"\n' >> /root/.cargo/config
RUN echo >> /root/.cargo/config

# Install Emscripten SDK
# ----------------------

ARG EMSCRIPTEN_VERSION=2.0.17
ARG EMSCRIPTEN_BUILD_TOOLS_PATH=/opt/emscripten-build-tools
ARG EMSCRIPTEN_SDK_PATH=${EMSCRIPTEN_BUILD_TOOLS_PATH}/emsdk
WORKDIR $EMSCRIPTEN_BUILD_TOOLS_PATH
RUN git clone https://github.com/emscripten-core/emsdk.git
WORKDIR $EMSCRIPTEN_SDK_PATH
RUN ./emsdk install ${EMSCRIPTEN_VERSION}
RUN ./emsdk activate ${EMSCRIPTEN_VERSION}
RUN chmod 777 ${EMSCRIPTEN_SDK_PATH}/upstream/emscripten
RUN chmod -R 777 ${EMSCRIPTEN_SDK_PATH}/upstream/emscripten/cache
ENV PATH="${EMSCRIPTEN_SDK_PATH}:${EMSCRIPTEN_SDK_PATH}/upstream/emscripten:${EMSCRIPTEN_SDK_PATH}/upstream/bin:${EMSCRIPTEN_SDK_PATH}/node/14.18.2_64bit/bin:${PATH}"
ENV EMSDK=${EMSCRIPTEN_SDK_PATH}
ENV EM_CONFIG=${EMSCRIPTEN_SDK_PATH}/.emscripten
ENV EMSDK_NODE=${EMSCRIPTEN_SDK_PATH}/node/14.18.2_64bit/bin/node

# Cleanup Emscripten installation by removing debugging symbols
# -------------------------------------------------------------

RUN echo "## Aggressive optimization: Remove debug symbols" \
    && cd ${EMSCRIPTEN_SDK_PATH} && . ./emsdk_env.sh \
    # Remove debugging symbols from embedded node (extra 7MB)
    && strip -s `which node` \
    # Tests consume ~80MB disc space
    && rm -fr ${EMSCRIPTEN_SDK_PATH}/upstream/emscripten/tests \
    # Fastcomp is not supported
    && rm -fr ${EMSCRIPTEN_SDK_PATH}/upstream/fastcomp \
    # strip out symbols from clang (~extra 50MB disc space)
    && find ${EMSCRIPTEN_SDK_PATH}/upstream/bin -type f -exec strip -s {} + || true \
    && echo "## Done"

# Copy emcc-mod script
# --------------------

RUN mkdir -p /opt/emscripten-build-tools/bin
COPY ./emcc-mod /opt/emscripten-build-tools/bin
RUN chmod +x /opt/emscripten-build-tools/bin/emcc-mod
ENV PATH=/opt/emscripten-build-tools/bin:$PATH

# Configure Rust for Emscripten cross-compiling
# ---------------------------------------------

RUN echo "[target.wasm32-unknown-emscripten]" >> /root/.cargo/config
RUN find /opt/emscripten-build-tools/bin -name emcc-mod -printf 'linker = "%p"\n' >> /root/.cargo/config
RUN echo >> /root/.cargo/config

RUN cat /root/.cargo/config

# Install all flavors of Godot
# ----------------------------

ENV GODOT_VERSION=3.2.3
ARG GODOT_BASE_URL=https://downloads.tuxfamily.org/godotengine
ENV GODOT_DIR=/opt/godotengine
WORKDIR $GODOT_DIR
RUN for i in x11 linux_headless linux_server ; do wget -nc -nv $GODOT_BASE_URL/$GODOT_VERSION/Godot_v$GODOT_VERSION-stable_$i.64.zip ; done && for i in *.zip ; do unzip -q $i ; done && rm *.zip
RUN for i in x11 linux_headless linux_server ; do wget -nc -nv $GODOT_BASE_URL/$GODOT_VERSION/mono/Godot_v$GODOT_VERSION-stable_mono_${i}_64.zip ; done && for i in *.zip ; do unzip -q $i ; done && rm *.zip
RUN ln -s Godot_v$GODOT_VERSION-stable_x11.64 godot3 && \
    ln -s Godot_v$GODOT_VERSION-stable_x11.64 godot && \
    ln -s Godot_v$GODOT_VERSION-stable_linux_headless.64 godot3_headless && \
    ln -s Godot_v$GODOT_VERSION-stable_linux_headless.64 godot_headless && \
    ln -s Godot_v$GODOT_VERSION-stable_linux_server.64 godot3_server && \
    ln -s Godot_v$GODOT_VERSION-stable_linux_server.64 godot_server && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_x11_64 godot3_mono && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_x11_64 godot_mono && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_linux_headless_64 godot3_mono_headless && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_linux_headless_64 godot_mono_headless && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_linux_server_64 godot3_mono_server && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_linux_server_64 godot_mono_server && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_x11.64 godot3_mono/godot3_mono && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_x11.64 godot_mono/godot_mono && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_linux_headless.64 godot3_mono_headless/godot3_mono_headless && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_linux_headless.64 godot_mono_headless/godot_mono_headless && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_linux_server.64 godot3_mono_server/godot3_mono_server && \
    ln -s Godot_v$GODOT_VERSION-stable_mono_linux_server.64 godot_mono_server/godot_mono_server
ENV PATH=$GODOT_DIR:$GODOT_DIR/godot3_mono:$GODOT_DIR/godot3_mono_headless:$GODOT_DIR/godot3_mono_server:$PATH

# Install Godot export templates
# ------------------------------

ARG GODOT_TEMPLATE_DIR=/root/.local/share/godot/templates
WORKDIR $GODOT_TEMPLATE_DIR
RUN wget -nc -nv $GODOT_BASE_URL/$GODOT_VERSION/Godot_v$GODOT_VERSION-stable_export_templates.tpz && unzip -q Godot_v$GODOT_VERSION-stable_export_templates.tpz && rm Godot_v$GODOT_VERSION-stable_export_templates.tpz && mv templates $GODOT_VERSION.stable
RUN wget -nc -nv $GODOT_BASE_URL/$GODOT_VERSION/mono/Godot_v$GODOT_VERSION-stable_mono_export_templates.tpz && unzip -q Godot_v$GODOT_VERSION-stable_mono_export_templates.tpz && rm Godot_v$GODOT_VERSION-stable_mono_export_templates.tpz && mv templates $GODOT_VERSION.stable.mono

# Setup editor defaults so that export works
# ------------------------------------------

ARG ANDROID_KEYSTORE_DIR=/root/.android
WORKDIR $ANDROID_KEYSTORE_DIR
RUN keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
ARG GODOT_EDITOR_CONFIG_DIR=/root/.config/godot
ARG GODOT_EDITOR_CONFIG_FILENAME=editor_settings-3.tres
WORKDIR $GODOT_EDITOR_CONFIG_DIR
RUN echo '[gd_resource type="EditorSettings" format=2]' >> $GODOT_EDITOR_CONFIG_FILENAME
RUN echo >> $GODOT_EDITOR_CONFIG_FILENAME
RUN echo '[resource]' >> $GODOT_EDITOR_CONFIG_FILENAME
RUN echo 'export/android/adb = "/usr/bin/adb"' >> $GODOT_EDITOR_CONFIG_FILENAME
RUN echo 'export/android/jarsigner = "/usr/bin/jarsigner"' >> $GODOT_EDITOR_CONFIG_FILENAME
RUN echo 'export/android/debug_keystore = "/root/.android/debug.keystore"' >> $GODOT_EDITOR_CONFIG_FILENAME
RUN echo 'export/android/debug_keystore_user = "androiddebugkey"' >> $GODOT_EDITOR_CONFIG_FILENAME
RUN echo 'export/android/debug_keystore_pass = "android"' >> $GODOT_EDITOR_CONFIG_FILENAME

# Mark the sytem as being a godot-run-cross-compiler image
# --------------------------------------------------------

WORKDIR /opt
RUN echo $GRCC_VERSION > godot-rust-cross-compiler.txt

# Work in /build
# --------------

WORKDIR /build

# Example usage:
# docker run -v $(pwd):/build ufoot/godot-rust-cross-compiler cargo build --release --target aarch64-linux-android
#
# Using a cache:
# install -d /tmp/.cargo/git
# install -d /tmp/.cargo/registry
# docker run -v $(pwd):/build ufoot/godot-rust-cross-compiler -v/tmp/.cargo/git:/root/.cargo/git -v/tmp/.cargo/registry:/root/.cargo/registry ufoot/godot-rust-cross-compiler cargo build --release --target aarch64-linux-android
