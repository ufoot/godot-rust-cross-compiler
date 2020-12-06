#!/bin/sh

docker build . -t ufoot/godot-rust-cross-compile:0.2.2
docker build . -t ufoot/godot-rust-cross-compile:latest
