#!/bin/sh

docker build . -t ufoot/godot-rust-cross-compiler:0.3.1
docker build . -t ufoot/godot-rust-cross-compiler:latest
