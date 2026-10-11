#!/usr/bin/env bash
# Runs the headless GDScript test suite. Optional arg: substring filter on "file::test_name".
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/tools/godot_bin.sh"
# Import first so class_name globals and asset imports exist on a fresh checkout.
"$GODOT" --headless --path "$ROOT/game" --import >/dev/null 2>&1 || true
"$GODOT" --headless --path "$ROOT/game" -s res://tests/run_tests.gd -- "${1:-}"
