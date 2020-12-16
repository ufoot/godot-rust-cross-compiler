#!/bin/sh

docker build . -t ufoot/godot-rust-cross-compiler:0.2.4
docker build . -t ufoot/godot-rust-cross-compiler:latest
