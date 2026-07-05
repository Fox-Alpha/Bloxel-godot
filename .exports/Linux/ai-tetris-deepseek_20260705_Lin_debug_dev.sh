#!/bin/sh
printf '\033c\033]0;%s\a' Bloxel
base_path="$(dirname "$(realpath "$0")")"
"$base_path/ai-tetris-deepseek_20260705_Lin_debug_dev.x86_64" "$@"
