#!/usr/bin/env bash
# Exports release builds into builds/ (Linux x86_64 — also the Steam Deck — and Windows x86_64).
# Needs the Godot 4.7.2 export templates installed; see CLAUDE.md > Tooling setup.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tools/godot_bin.sh"
mkdir -p "$ROOT/builds/linux" "$ROOT/builds/windows"
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$ROOT/game" --export-release "Linux" "$ROOT/builds/linux/my-first-rpg.x86_64"
"$GODOT" --headless --path "$ROOT/game" --export-release "Windows" "$ROOT/builds/windows/my-first-rpg.exe"
ls -la "$ROOT/builds/linux" "$ROOT/builds/windows"
