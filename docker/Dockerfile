# Godot Rust Cross Compiler
# -------------------------
#
# See https://github.com/ufoot/godot-rust-cross-compiler for details

FROM ubuntu:noble

LABEL maintainer="Christian Mauduit <ufoot@ufoot.org>"
ENV GRCC_VERSION=0.3.0
LABEL package="godot-rust-cross-compiler" version="$GRCC_VERSION" description="An image to cross-compile to Windows, Android, Mac OS X and Linux your godot-rust based libraries for Godot 4."

# Prepare the system, install Debian packages
# -------------------------------------------
# Combined into single RUN to reduce layers and clean apt cache

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata && \
    apt-get install -yq --no-install-recommends \
    sudo curl wget git zip unzip xz-utils \
    file g++ cmake pkg-config \
    libasound2-dev bison flex \
    openjdk-17-jre-headless \
    libssl-dev python3 python-is-python3 \
    llvm-dev libclang-dev clang \
    libncurses-dev \
    binutils-mingw-w64 gcc-mingw-w64 g++-mingw-w64 \
    libxml2-dev zlib1g-dev \
    ca-certificates \
    xvfb \
    gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Android command line tools and NDK
# ------------------------------------------

ARG ANDROID_BUILD_TOOLS_PATH=/opt/android-build-tools
ARG ANDROID_BASE_URL=https://dl.google.com/android/repository
ARG ANDROID_CMDLINE_TOOLS_VERSION=11076708
ARG ANDROID_CMDLINE_TOOLS_FILENAME=commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip
ARG ANDROID_CMDLINE_TOOLS_URL=$ANDROID_BASE_URL/$ANDROID_CMDLINE_TOOLS_FILENAME

ENV ANDROID_HOME=$ANDROID_BUILD_TOOLS_PATH/android-sdk
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

WORKDIR $ANDROID_BUILD_TOOLS_PATH

# Install SDK, NDK, then clean up unused NDK components to save ~1GB
RUN wget -nc -nv $ANDROID_CMDLINE_TOOLS_URL && \
    unzip -q $ANDROID_CMDLINE_TOOLS_FILENAME && \
    rm $ANDROID_CMDLINE_TOOLS_FILENAME && \
    mkdir -p android-sdk/cmdline-tools && \
    mv cmdline-tools android-sdk/cmdline-tools/latest && \
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) && \
    yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses && \
    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "ndk;23.2.8568313" "cmdline-tools;latest" && \
    # Remove unused NDK toolchains (keep only linux-x86_64 host) \
    rm -rf $ANDROID_HOME/ndk/23.2.8568313/toolchains/llvm/prebuilt/darwin-x86_64 2>/dev/null || true && \
    rm -rf $ANDROID_HOME/ndk/23.2.8568313/toolchains/llvm/prebuilt/windows-x86_64 2>/dev/null || true && \
    rm -rf $ANDROID_HOME/ndk/23.2.8568313/toolchains/llvm/prebuilt/windows 2>/dev/null || true && \
    # Remove NDK simpleperf, shader-tools, renderscript (not needed for Rust) \
    rm -rf $ANDROID_HOME/ndk/23.2.8568313/simpleperf 2>/dev/null || true && \
    rm -rf $ANDROID_HOME/ndk/23.2.8568313/shader-tools 2>/dev/null || true && \
    rm -rf $ANDROID_HOME/ndk/23.2.8568313/sources/third_party/shaderc 2>/dev/null || true && \
    rm -rf $ANDROID_HOME/ndk/23.2.8568313/sources/cxx-stl/llvm-libc++/test 2>/dev/null || true && \
    # Clean up zip cache \
    rm -rf /root/.android/cache/*

ENV PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH
ENV ANDROID_NDK_ROOT=$ANDROID_HOME/ndk/23.2.8568313
ENV NDK_HOME=$ANDROID_NDK_ROOT

# Install bundletool for AAB support
ARG BUNDLETOOL_VERSION=1.17.2
RUN wget -nc -nv https://github.com/google/bundletool/releases/download/$BUNDLETOOL_VERSION/bundletool-all-$BUNDLETOOL_VERSION.jar -O /opt/bundletool.jar

# Install Rust
# ------------

RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y --profile minimal
ENV PATH=/root/.cargo/bin:$PATH

RUN rustup target add \
    x86_64-pc-windows-gnu \
    aarch64-pc-windows-gnullvm \
    aarch64-linux-android \
    armv7-linux-androideabi \
    x86_64-linux-android \
    i686-linux-android \
    x86_64-apple-darwin \
    aarch64-apple-darwin \
    x86_64-unknown-linux-gnu \
    i686-unknown-linux-gnu \
    aarch64-unknown-linux-gnu

RUN mkdir -p /root/.cargo/git /root/.cargo/registry

# Configure Rust for Android cross-compiling
# ------------------------------------------

ARG ANDROID_API_LEVEL=21
ARG NDK_TOOLCHAIN=$ANDROID_HOME/ndk/23.2.8568313/toolchains/llvm/prebuilt/linux-x86_64/bin

RUN echo "[target.aarch64-linux-android]" >> /root/.cargo/config.toml && \
    echo "linker = \"$NDK_TOOLCHAIN/aarch64-linux-android${ANDROID_API_LEVEL}-clang\"" >> /root/.cargo/config.toml && \
    echo "" >> /root/.cargo/config.toml && \
    echo "[target.armv7-linux-androideabi]" >> /root/.cargo/config.toml && \
    echo "linker = \"$NDK_TOOLCHAIN/armv7a-linux-androideabi${ANDROID_API_LEVEL}-clang\"" >> /root/.cargo/config.toml && \
    echo "" >> /root/.cargo/config.toml && \
    echo "[target.x86_64-linux-android]" >> /root/.cargo/config.toml && \
    echo "linker = \"$NDK_TOOLCHAIN/x86_64-linux-android${ANDROID_API_LEVEL}-clang\"" >> /root/.cargo/config.toml && \
    echo "" >> /root/.cargo/config.toml && \
    echo "[target.i686-linux-android]" >> /root/.cargo/config.toml && \
    echo "linker = \"$NDK_TOOLCHAIN/i686-linux-android${ANDROID_API_LEVEL}-clang\"" >> /root/.cargo/config.toml && \
    echo "" >> /root/.cargo/config.toml && \
    echo "[target.aarch64-unknown-linux-gnu]" >> /root/.cargo/config.toml && \
    echo "linker = \"aarch64-linux-gnu-gcc\"" >> /root/.cargo/config.toml && \
    echo "" >> /root/.cargo/config.toml

# Install llvm-mingw for Windows ARM64 cross-compiling
# Only keep aarch64 toolchain, remove others to save ~800MB
ARG LLVM_MINGW_VERSION=20241119
ARG LLVM_MINGW_URL=https://github.com/mstorsjo/llvm-mingw/releases/download/$LLVM_MINGW_VERSION/llvm-mingw-$LLVM_MINGW_VERSION-ucrt-ubuntu-20.04-x86_64.tar.xz
RUN wget -nc -nv $LLVM_MINGW_URL -O /tmp/llvm-mingw.tar.xz && \
    tar -xf /tmp/llvm-mingw.tar.xz -C /opt && \
    rm /tmp/llvm-mingw.tar.xz && \
    mv /opt/llvm-mingw-$LLVM_MINGW_VERSION-ucrt-ubuntu-20.04-x86_64 /opt/llvm-mingw && \
    # Remove i686 and x86_64 toolchains (we use mingw-w64 for x86_64, llvm-mingw only for aarch64) \
    rm -rf /opt/llvm-mingw/i686-w64-mingw32 && \
    rm -rf /opt/llvm-mingw/x86_64-w64-mingw32 && \
    rm -rf /opt/llvm-mingw/armv7-w64-mingw32 && \
    # Remove lib directories for removed targets \
    find /opt/llvm-mingw/lib -name '*i686*' -delete 2>/dev/null || true && \
    find /opt/llvm-mingw/lib -name '*x86_64*' -delete 2>/dev/null || true

ENV PATH=/opt/llvm-mingw/bin:$PATH

# Configure Windows ARM64 cross-compiling
RUN echo "[target.aarch64-pc-windows-gnullvm]" >> /root/.cargo/config.toml && \
    echo "linker = \"/opt/llvm-mingw/bin/aarch64-w64-mingw32-clang\"" >> /root/.cargo/config.toml && \
    echo "" >> /root/.cargo/config.toml

# Install OSX cross build env
# ---------------------------

ARG MACOSX_BUILD_TOOLS_PATH=/opt/macosx-build-tools
ARG OSXCROSS_PATH=$MACOSX_BUILD_TOOLS_PATH/osxcross
ARG MACOSX_CROSS_COMPILER_PATH=$MACOSX_BUILD_TOOLS_PATH/cross-compiler

ARG MACOSX_SDK_BASE_URL=https://github.com/joseluisq/macosx-sdks/releases/download/14.5
ENV MACOSX_SDK_VERSION=14.5
ARG MACOSX_SDK_FILENAME=MacOSX$MACOSX_SDK_VERSION.sdk.tar.xz

WORKDIR $MACOSX_BUILD_TOOLS_PATH

# Build osxcross, then remove source and build artifacts to save ~500MB
RUN git clone --depth 1 https://github.com/tpoechtrager/osxcross && \
    cd osxcross && \
    wget -nc -nv $MACOSX_SDK_BASE_URL/$MACOSX_SDK_FILENAME && \
    mv $MACOSX_SDK_FILENAME tarballs/ && \
    UNATTENDED=yes OSX_VERSION_MIN=11.0 TARGET_DIR=$MACOSX_CROSS_COMPILER_PATH ./build.sh && \
    cd .. && \
    rm -rf osxcross

ENV PATH=$MACOSX_CROSS_COMPILER_PATH/bin:$PATH

# Configure Rust for Mac OS X cross-compiling
RUN echo "[target.x86_64-apple-darwin]" >> /root/.cargo/config.toml && \
    echo "linker = \"$MACOSX_CROSS_COMPILER_PATH/bin/x86_64-apple-darwin23-clang\"" >> /root/.cargo/config.toml && \
    echo "" >> /root/.cargo/config.toml && \
    echo "[target.aarch64-apple-darwin]" >> /root/.cargo/config.toml && \
    echo "linker = \"$MACOSX_CROSS_COMPILER_PATH/bin/aarch64-apple-darwin23-clang\"" >> /root/.cargo/config.toml && \
    echo "" >> /root/.cargo/config.toml

# Install Godot 4
# ---------------

ENV GODOT_VERSION=4.3
ARG GODOT_BASE_URL=https://github.com/godotengine/godot/releases/download
ENV GODOT_DIR=/opt/godotengine

WORKDIR $GODOT_DIR

RUN wget -nc -nv $GODOT_BASE_URL/$GODOT_VERSION-stable/Godot_v$GODOT_VERSION-stable_linux.x86_64.zip && \
    unzip -q Godot_v$GODOT_VERSION-stable_linux.x86_64.zip && \
    rm Godot_v$GODOT_VERSION-stable_linux.x86_64.zip && \
    ln -s Godot_v$GODOT_VERSION-stable_linux.x86_64 godot4 && \
    ln -s Godot_v$GODOT_VERSION-stable_linux.x86_64 godot

ENV PATH=$GODOT_DIR:$PATH

# Install Godot 4 export templates
# --------------------------------

ARG GODOT_TEMPLATE_DIR=/root/.local/share/godot/export_templates

WORKDIR $GODOT_TEMPLATE_DIR

RUN wget -nc -nv $GODOT_BASE_URL/$GODOT_VERSION-stable/Godot_v$GODOT_VERSION-stable_export_templates.tpz && \
    unzip -q Godot_v$GODOT_VERSION-stable_export_templates.tpz && \
    rm Godot_v$GODOT_VERSION-stable_export_templates.tpz && \
    mv templates $GODOT_VERSION.stable

# Setup editor defaults so that export works
# ------------------------------------------

ARG ANDROID_KEYSTORE_DIR=/root/.android
WORKDIR $ANDROID_KEYSTORE_DIR
RUN keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12

ARG GODOT_EDITOR_CONFIG_DIR=/root/.config/godot
ARG GODOT_EDITOR_CONFIG_FILENAME=editor_settings-4.tres
WORKDIR $GODOT_EDITOR_CONFIG_DIR
RUN echo '[gd_resource type="EditorSettings" format=3]' >> $GODOT_EDITOR_CONFIG_FILENAME && \
    echo '' >> $GODOT_EDITOR_CONFIG_FILENAME && \
    echo '[resource]' >> $GODOT_EDITOR_CONFIG_FILENAME && \
    echo 'export/android/java_sdk_path = "/usr/lib/jvm/java-17-openjdk-amd64"' >> $GODOT_EDITOR_CONFIG_FILENAME && \
    echo 'export/android/android_sdk_path = "/opt/android-build-tools/android-sdk"' >> $GODOT_EDITOR_CONFIG_FILENAME && \
    echo 'export/android/debug_keystore = "/root/.android/debug.keystore"' >> $GODOT_EDITOR_CONFIG_FILENAME && \
    echo 'export/android/debug_keystore_user = "androiddebugkey"' >> $GODOT_EDITOR_CONFIG_FILENAME && \
    echo 'export/android/debug_keystore_pass = "android"' >> $GODOT_EDITOR_CONFIG_FILENAME

# Mark the system as being a godot-rust-cross-compiler image
# ----------------------------------------------------------

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
# docker run -v $(pwd):/build -v /tmp/.cargo/git:/root/.cargo/git -v /tmp/.cargo/registry:/root/.cargo/registry ufoot/godot-rust-cross-compiler cargo build --release --target aarch64-linux-android
