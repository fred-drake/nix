#!/usr/bin/env bash

if [ ! -z "$1" ]; then
    export HOST="$1"
else
    export HOST=$(hostname --short)
fi

if [ "$(uname -s)" = "Darwin" ]; then
    if [ "$HOST" = "freds-macbook-pro" ] || [ "$HOST" = "fred-macbook-pro-wireless" ]; then
        darwin-rebuild --flake .#macbook-pro switch
    else
        darwin-rebuild --flake .#"$HOST" switch
    fi
else
    sudo nixos-rebuild --flake .#"$HOST" switch
fi
