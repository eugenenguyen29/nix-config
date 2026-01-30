#!/bin/bash

sudo nixos-rebuild switch --accept-flake-config --flake .#$1 --show-trace --impure ${@:2}
