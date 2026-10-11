#!/usr/bin/env bash
# Sourced by the tool scripts: sets GODOT to this OS's 4.7.2 binary unless already set.
# On Windows the _console build is used so headless output reaches the terminal.
_GODOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/godot"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) GODOT="${GODOT:-$_GODOT_DIR/Godot_v4.7.2-stable_win64_console.exe}" ;;
  *) GODOT="${GODOT:-$_GODOT_DIR/Godot_v4.7.2-stable_linux.x86_64}" ;;
esac
