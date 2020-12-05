#!/bin/sh

docker build . -t ufoot/godot-rust-cross-compile:latest
docker build . -t ufoot/godot-rust-cross-compile:0.2.1
