# My First RPG

A 3D turn-based RPG built in Godot 4. You play a scientist-engineer who drives a mobile workshop through a ruined, post-apocalyptic world, scavenging parts from wrecked cities to build and upgrade combat drones. The drone design takes its cue from Medabots: each drone is assembled from parts (arms, head, legs) that decide what it can do in battle.

The game targets Linux, Windows and the Steam Deck.

## Current state

- **Overworld (done):** an infinite desert, procedurally generated from a seed and streamed in chunks. You drive a truck between points of interest (POIs) connected by roads, or off-road. A compass bar shows the three nearest POIs.
- **POI exploration on foot (in progress):** entering a POI starts a level built from its layout. A masked explorer, followed by a scanning and hacking drone, loots the area and has to bring the loot back to the truck to keep it.
- **Planned:** turn-based drone battles, drone building and upgrading, then a story mode.

See [docs/roadmap.md](docs/roadmap.md) for the full milestone list.

## Project layout

| Path | Contents |
|---|---|
| `game/` | The Godot project (scenes, scripts, shaders, assets, tests) |
| `docs/` | Roadmap, milestone plans, art sources and Steam Deck notes |
| `tools/` | Scripts for running tests, exporting builds and locating the Godot binary |

## Getting started

1. Download Godot 4.7.2-stable into `tools/godot/` (details in [CLAUDE.md](CLAUDE.md) under "Tooling setup").
2. Open `game/project.godot` in the editor, or run the tests headless:

   ```sh
   tools/run_tests.sh
   ```

3. Build Linux and Windows exports with `tools/export.sh`. Builds go to `builds/`.

Art assets come from free CC0 packs, listed in [docs/art-sources.md](docs/art-sources.md). Performance presets and the debug overlay for the Steam Deck are described in [docs/steam-deck.md](docs/steam-deck.md).
