# CLAUDE.md

Project-specific context for Claude Code. Shared rules (guardrails, TDD workflow, git, commits, secrets, reporting, tech-stack defaults) live in the global `~/.claude/CLAUDE.md`.

---

## Project Overview

A 3D game using the Godot engine using the MCP server. The game will be an rpg that has turn-based combat. 

The protaganist, a scientist/engineer who builds and repairs the unmanned drones controlled to fight and scavenge for parts to build and upgrade drones. 

Drones will be robots that are built from different components (left arm might be a machine gun, the right a grenade launcher, the head could have enhanced scanners that grant the ability to scan for weaknesses increasing hit chance for the next few turns, or the head could have a smoke launcher that could decrease the enemies hit chance, etc.), I am taking inspiration from Medabots heavily.

The protaganist drives around in his mobile workshop, scavenging parts from wrecked cities. A world ending event has left the planet in a ruin where Humans are a dying breed. Small cities exist but are far apart that they all need to be self-suficient. 

There will be a story mode later, however the MVP is a driving around from point of interest to point of interest and fighting battle to upgrade drones.

### Tools
- **Renderer:** Forward+ (3D). Targets: Linux, Windows and the Steam Deck.
- **Assets:** keep downloaded packs in `art_source/` (CC0 rules are in the global CLAUDE.md).

### Tooling setup
- **Godot 4.7.2-stable** (latest stable as of 2026-10-11) lives in `tools/godot/`: `Godot_v4.7.2-stable_linux.x86_64` on Linux, `Godot_v4.7.2-stable_win64.exe` (+ `_console.exe` for headless runs) on Windows. It runs in self-contained mode (`tools/godot/_sc_`), so editor settings live in `tools/godot/editor_data/`. The binaries are gitignored; to re-download, grab `Godot_v4.7.2-stable_linux.x86_64.zip` or `Godot_v4.7.2-stable_win64.exe.zip` from https://github.com/godotengine/godot/releases/tag/4.7.2-stable, verify against the tracked `tools/godot/SHA512-SUMS.txt`, unzip into `tools/godot/`, and `touch tools/godot/_sc_`. The `.sh` scripts pick the right binary via `tools/godot_bin.sh` (on Windows run them from Git Bash); override with `GODOT=<path>`.
- **Godot MCP server** is configured in `.mcp.json` (`@coding-solo/godot-mcp@0.1.1`). It uses `$GODOT_PATH`, defaulting to the Linux binary path. On Windows, `GODOT_PATH` is set in the gitignored `.claude/settings.local.json` to the `_console.exe`. Prefer it for launching/running the project and inspecting scenes; fall back to the CLI binary headless (`--headless --path <project>`) for imports and test runs.
- **Art sources:** `art_source/` is gitignored. `docs/art-sources.md` lists every pack and where to download it.
- **Tests:** no test framework dependency. Use a small custom headless runner (`test_*.gd` files + assert helpers), run via the Godot binary with `--headless`. Cover pure logic (chunk math, deterministic generation, POI/road placement, nearest-POI selection).
  Run with `tools/run_tests.sh [filter]` (runner: `game/tests/run_tests.gd`, tests extend `TestCase` in `game/tests/`). The Godot project lives in `game/`.
- **Exports:** `tools/export.sh` builds Linux x86_64 (also the Steam Deck) and Windows x86_64 into `builds/` (gitignored), using `game/export_presets.cfg`. Needs the 4.7.2 export templates in `tools/godot/editor_data/export_templates/4.7.2.stable/` (gitignored): download `Godot_v4.7.2-stable_export_templates.tpz` from the same release page, verify it against `tools/godot/SHA512-SUMS.txt`, and extract the Linux/Windows x86_64 templates plus `version.txt` there. Steam Deck notes and the `--benchmark` mode are in `docs/steam-deck.md`.

---

## Roadmap
See `docs/roadmap.md`: Overworld ✅ → **POI exploration (current)** → Battles → Drone building → Story.

## Current Task — POI Exploration on foot (milestone 2)

The full plan and decisions are in `docs/plans/poi-exploration.md`. Don't re-ask anything listed there under "Decided". Real battles and drone-part building are **out of scope**.
- Each POI gets a fixed level built from its layout, the same for a given seed. The run starts at the parked truck, which is also the extraction point.
- A masked explorer, chosen on a new main menu: the Survivalist, a head swap (Survivalist body with the Hoarder's head) or the Hoarder with no sword and no bag, all wearing the Hoarder's mask and scarf recoloured khaki. The explorer moves in third person and never attacks. An exploration drone follows and does the scanning and hacking.
- No walk-in buildings: locked doors (key or hack) open a loot window. The bag is slot-based with rarities, like Arc Raiders.
- Loot only counts once it's unloaded at the truck. There it breaks down over time into elements.
- Random encounters open a placeholder battle screen that automatically loses the 3rd encounter. On defeat you respawn at the truck, the bag is lost, and the POI resets to its state at your last unload.

Milestone 1 (overworld) is done; its decisions still hold and are in [docs/plans/overworld.md](docs/plans/overworld.md).
