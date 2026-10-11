#!/usr/bin/env bash
# Bakes plant/cactus props from art_source/ into game/assets/models/plants/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT:-$ROOT/tools/godot/Godot_v4.7.2-stable_linux.x86_64}"
G=("$GODOT" --headless --path "$ROOT/game")
"${G[@]}" -s res://tools/bake_plants.gd -- textures
"${G[@]}" --import >/dev/null 2>&1 || true
"$ROOT/tools/set_texture_imports.sh" "$ROOT/game/assets/models/plants/textures"
"${G[@]}" --import >/dev/null 2>&1 || true
"${G[@]}" -s res://tools/bake_plants.gd -- meshes
