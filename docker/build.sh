#!/bin/sh

docker build . -t ufoot/godot-rust-cross-compiler:0.3.0
docker build . -t ufoot/godot-rust-cross-compiler:latest
