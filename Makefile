# Project Makefile: only settings, everything else comes from grcc.mk
# (copied verbatim from godot-rust-cross-compiler, update with `make sync`).

# replace those with your game name/version
GRCC_GAME_PKG_NAME=crosscompilertoy
GRCC_GAME_PKG_VERSION=0.3.1
# replace cctoy with the name of your rust library
GRCC_GODOT_RUST_LIB_NAME=cctoy
# replace godot-rust-cross-compiler by your repo name
GRCC_GAME_REPO_NAME=godot-rust-cross-compiler
# publisher name for Windows installers
GRCC_GAME_PUBLISHER=ufoot

# Android signing keys (git-ignored). The release key is used only when its
# password is in the environment: GRCC_ANDROID_RELEASE_KEYSTORE_PASSWORD=...
GRCC_ANDROID_DEBUG_KEYSTORE=.keystore/godot-debug.keystore
GRCC_ANDROID_RELEASE_KEYSTORE=.keystore/ufoot.keystore
# Key alias inside the release keystore (not secret)
GRCC_ANDROID_RELEASE_KEYSTORE_USER=upload

# Short target names: make native, lint, test, build, export, aab, sync...
GRCC_ALIASES=yes

include grcc.mk
