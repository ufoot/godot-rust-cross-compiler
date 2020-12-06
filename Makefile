# replace cctoy with the name of your library
GRCC_GODOT_RUST_LIB_NAME=cctoy
include grcc.mk

all: grcc-all

test: grcc-test

clean: grcc-clean

native: grcc-native

cross: grcc-cross
