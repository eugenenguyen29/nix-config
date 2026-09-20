#!/bin/bash

sudo nixos-rebuild switch --flake .#$1 --show-trace --impure ${@:2}
