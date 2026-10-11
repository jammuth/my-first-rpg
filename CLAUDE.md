# CLAUDE.md

This file is read automatically by Claude Code at the start of every session in this repo. It has two kinds of content:

- **Universal** sections — how I work, true across all my projects.
- **Per-project** sections — marked `<!-- FILL IN PER PROJECT -->`, edit these first when you clone this template for a new repo.

---

## Project Overview

A 3D game using the Godot engine using the MCP server. The game will be an rpg that has turn-based combat. 

The protaganist, a scientist/engineer who builds and repairs the unmanned drones controlled to fight and scavenge for parts to build and upgrade drones. 

Drones will be robots that are built from different components (left arm might be a machine gun, the right a grenade launcher, the head could have enhanced scanners that grant the ability to scan for weaknesses increasing hit chance for the next few turns, or the head could have a smoke launcher that could decrease the enemies hit chance, etc.), I am taking inspiration from Medabots heavily.

The protaganist drives around in his mobile workshop, scavenging parts from wrecked cities. A world ending event has left the planet in a ruin where Humans are a dying breed. Small cities exist but are far apart that they all need to be self-suficient. 

There will be a story mode later, however the MVP is a driving around from point of interest to point of interest and fighting battle to upgrade drones.

### Tools
- use the latest Godot engine
- use the MCP server
- as this is a 3d game we will use the forward+ renderer, i plan to release this on Linux/windows and also the SteamDeck
- use the assets from the art_source
- if any asset is needed, it needs to be free to download and also have a cc0 lisence. Ask before downloading, give source and then download it to the art_source folder so it can be kept.
- only copy needed assets to the godot project to keep the project size small.

### Tooling setup
- **Godot 4.7.2-stable** (latest stable as of 2026-10-11) lives at `tools/godot/Godot_v4.7.2-stable_linux.x86_64`. It runs in self-contained mode (`tools/godot/_sc_`), so editor settings live in `tools/godot/editor_data/`. The binary is gitignored; to re-download, grab `Godot_v4.7.2-stable_linux.x86_64.zip` from https://github.com/godotengine/godot/releases/tag/4.7.2-stable, verify against the tracked `tools/godot/SHA512-SUMS.txt`, unzip into `tools/godot/`, and `touch tools/godot/_sc_`.
- **Godot MCP server** is configured in `.mcp.json` (`@coding-solo/godot-mcp@0.1.1`, pointed at the binary above). Prefer it for launching/running the project and inspecting scenes; fall back to the CLI binary headless (`--headless --path <project>`) for imports and test runs.
- **Tests:** no test framework dependency. Use a small custom headless runner (`test_*.gd` files + assert helpers), run via the Godot binary with `--headless`. Cover pure logic (chunk math, deterministic generation, POI/road placement, nearest-POI selection).
  Run with `tools/run_tests.sh [filter]` (runner: `game/tests/run_tests.gd`, tests extend `TestCase` in `game/tests/`). The Godot project lives in `game/`.
- **Exports:** `tools/export.sh` builds Linux x86_64 (also the Steam Deck) and Windows x86_64 into `builds/` (gitignored), using `game/export_presets.cfg`. Needs the 4.7.2 export templates in `tools/godot/editor_data/export_templates/4.7.2.stable/` (gitignored): download `Godot_v4.7.2-stable_export_templates.tpz` from the same release page, verify it against `tools/godot/SHA512-SUMS.txt`, and extract the Linux/Windows x86_64 templates plus `version.txt` there. Steam Deck notes and the `--benchmark` mode are in `docs/steam-deck.md`.

---

## Roadmap
See `docs/roadmap.md`: Overworld ✅ → **POI exploration (current)** → Battles → Drone building → Story.

## Current Task — POI Exploration on foot (milestone 2)

The full plan and decisions are in `docs/plans/poi-exploration.md`. Don't re-ask anything listed there under "Decided". Real battles and drone-part building are **out of scope**.
- Each POI gets a fixed level built from its layout, the same for a given seed. The run starts at the parked truck, which is also the extraction point.
- A masked explorer (KayKit Hoarder, swappable) moves in third person and never attacks. An exploration drone follows and does the scanning and hacking.
- No walk-in buildings: locked doors (key or hack) open a loot window. The bag is slot-based with rarities, like Arc Raiders.
- Loot only counts once it's unloaded at the truck. There it breaks down over time into elements.
- Random encounters open a placeholder battle screen that automatically loses the 3rd encounter. On defeat you respawn at the truck, the bag is lost, and the POI resets to its state at your last unload.

## Done: World Generation & Driving (overworld MVP)

These decisions still hold.

**World**
- Vast, effectively infinite, procedurally generated world. Deterministic from a world seed (same seed → same world).
- **Chunk system**, performance first: stream chunks in/out around the player, generate off the main thread or spread across frames where it helps, keep draw calls low (e.g. MultiMesh for repeated props). Must run well on the Steam Deck.
- **Desert** biome for now; structure the code so more biomes can be added later.
- **Roads** connect the POIs, but the truck can drive **anywhere** off-road too.

**POIs**
- Buildings that can be interacted with. Overworld style, so buildings **don't need to be to scale** (use the Kenney city kits in `art_source/`).
- Interaction: drive near → **"Press E to enter <name>"** prompt → simple **placeholder panel** showing POI name/type with a Leave button. Mark the POI as visited. This panel is the hook point for battles/scavenging later.

**Player vehicle & controls**
- Vehicle: the **green box truck** from the Kenney Car Kit (`art_source/kenney_car-kit/`) — verify which model is green from the previews/textures before using it.
- **No real driving physics** — it moves like a walking character: forward, back, turn left/right (tank controls). Should still collide with buildings.
- Controller support matters (Steam Deck), not just keyboard.

**Camera**
- **Low follow camera** (changed 2026-10-11 from the original 45–55°): sits behind the truck at the lowest orbit pitch (12° down) so the player can see where they are going, and rotates with the truck's heading. Right mouse / right stick orbits; it eases back on release.

**UI**
- **Compass bar at the top of the screen** with indicators for the **3 closest POIs**.

---

## Guardrails — ask before doing these

- **Never commit directly to `main`/`master`.** Always work on a feature branch (see Git Workflow below).
- **Never add a new dependency without asking first.** When proposing one, state *why that specific package* (not just "a dependency is needed") — what it does, why it's a better fit than writing it myself or using an existing dependency, and any notable footprint (native bindings, transitive deps, license).
- **Never push, open a PR, or merge unless explicitly told to.** See Git Workflow below for the full push/PR/cleanup process.

---

## Communication & Working Style

- **Never assume — ask.** For meaningful decisions (approach/architecture, scope, anything with a real tradeoff) that are ambiguous or underspecified, stop and ask a clarifying question or lay out the options rather than picking one silently. This does not apply to small implementation details (variable names, minor formatting, etc.) — use judgment there.

---

## Code Style & Conventions

- **Comments:** no comments explaining *what* code does — only *why*, and only when the logic is genuinely non-obvious (a hidden constraint, a workaround, a subtle invariant).

---

## Testing

- **Always write tests for new logic** as part of implementing it, not as a follow-up.
- **Run the new test immediately after implementation** to confirm it passes before moving on.
- **Run the full test suite before saying a task is done, and before committing.** A task isn't complete if the full suite hasn't been run and passed.

---

## Git Workflow

- **Start of work:** if not already on a feature branch, create one off `main` with a descriptive name (e.g. `feat/add-rate-limiting`, `fix/null-check-in-parser`).
- **"Ship it" / explicit push request:** push the feature branch, open a PR targeting `main`, and give me the PR link. Never merge it myself — I review and merge.
- **"Clean up the repo" (after I've merged the PR):** check out `main`, pull the latest changes, then delete stale branches — both local and remote (the merged feature branch, plus any other branches that are fully merged into `main`). Never delete a branch that has unmerged commits without confirming first.

---

## Commit Conventions

- **Conventional Commits format:** `<type>: <subject>` — e.g. `feat: add rate limiting to auth endpoint`, `fix: handle null user in session middleware`, `chore: bump lodash to 4.17.21`. Common types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`.
- **One commit per logical change** — don't bundle unrelated changes into one commit, and don't leave a string of WIP commits; each commit should stand on its own.
- **Include the `Co-Authored-By: Claude` trailer** on commits (this is this harness's default — no need to suppress it).

---

## Tech Stack Defaults

<!-- Tie-breakers when a project doesn't specify otherwise. Override per-project in that project's own CLAUDE.md section if it needs something different. -->

**JavaScript/TypeScript**
- Language: TypeScript by default for anything beyond a trivial script.
- Package manager: `pnpm`.
- Lint/format: ESLint + Prettier.

**Python**
- Package/env manager: `uv`.
- Lint/format: Ruff.

---

## Progress Reporting

- **Task tracking:** for any multi-step task, maintain a visible task list (create it up front, update status as steps complete) rather than narrating progress in plain text only.
- **In-progress updates:** short update at key moments — found the root cause, changed approach, hit a blocker. Not a running commentary on every action.
- **End-of-task summary — detailed, peer-review style.** Write it as if justifying the change to a senior dev reviewing the PR:
  - What changed and why (the reasoning behind the approach, not just the diff).
  - Files touched, and what changed in each.
  - Alternatives considered and why they were rejected, if any were meaningfully in play.
  - Tradeoffs or known limitations of the approach taken.
  - Test coverage added and results of running the suite.

---

## Security & Secrets

- **Never commit `.env`** (or any file holding real secret values). It must be in `.gitignore` from the start of the project.
- **Always maintain an `example.env`** alongside it — same keys, no real values, with a comment/hint on each line describing what should go there (where to get it, expected format, etc.). Keep it in sync whenever a new env var is introduced.
- **Proactively flag hardcoded secrets** (keys, tokens, passwords, connection strings) whenever encountered — including in pre-existing code, not just new code I write. Flag immediately and note that it needs rotating if it's already been committed.

