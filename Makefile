# replace those with your game name/version
GRCC_GAME_PKG_NAME=crosscompilertoy
GRCC_GAME_PKG_VERSION=0.1.0
# replace cctoy with the name of your rust library
GRCC_GODOT_RUST_LIB_NAME=cctoy
# replace godot-rust-cross-compiler by your repo name
GRCC_GAME_REPO_NAME=godot-rust-cross-compiler

include grcc.mk

all: grcc-all

test: grcc-test

clean: grcc-clean

native: grcc-native

cross: grcc-cross

export: grcc-export
