#!/usr/bin/env bash

if [ ! -z $1 ]; then
    export HOST=$1
else
    export HOST=$(hostname --short)
fi

if [ "$(uname -s)" = "Darwin" ]; then
    darwin-rebuild --flake .#$HOST switch
else
    nixos-rebuild --flake .#$HOST switch
fi
