# Running and measuring on the Steam Deck

## Graphics presets
- `high`: the default on desktop.
- `deck`: picked automatically on a Deck. It uses Steam's `SteamDeck=1` variable, or the Deck's APU/GPU name when running outside Steam.

Ways to choose:
- Force a preset with `--graphics=high` or `--graphics=deck` after `--`.
- Press **F4** in game to cycle between presets.

What the `deck` preset changes is listed in `game/scripts/graphics_settings.gd`:
- 85% render scale with FSR 1 upscaling
- shorter, lower-resolution shadows
- terrain view distance of 3 chunks, with fog ending at 380 m
- 65% of decorative props, with shorter draw distance and no shadows
- 60% of the particles

## Debug overlay
Press **F3**, or **Select/View** on a gamepad, to show:
- FPS, and frame times (average, p99, max)
- draw calls and triangles
- video memory
- active preset
- loaded chunks
- world position and floating origin

## Benchmark
```bash
<godot binary> --path game -- --benchmark --graphics=deck
```
The benchmark:
- drives a fixed 60 s route from spawn, after a 3 s warm-up, with vsync off;
- prints frame-time stats, peak draw calls and triangles, and missed 60 fps frames;
- saves the same report to `user://benchmark-<preset>-<time>.txt` (on Linux: `~/.local/share/godot/app_userdata/My First RPG/`).

It ignores and never writes the save game.

On a Deck with no exported build yet, use Desktop Mode:
1. Copy the repo and the Godot 4.7.2 Linux binary across.
2. Run the command above from Konsole.

## Reference results (2026-10-11, 1280x800, same route)
| GPU | preset | avg ms | p99 ms | missed 60 fps frames |
|---|---|---|---|---|
| RTX 4060 Laptop | high | 1.05 | 1.21 | — |
| RTX 4060 Laptop | deck | 0.92 | 1.15 | — |
| Radeon 780M (iGPU) | high | 2.55 | 2.97 | — |
| Radeon 780M (iGPU) | deck | 2.15 | 2.60 | 1 |

The Radeon 780M is the closest stand-in available here: same RDNA family as the Deck, roughly 2–4× faster. The deck preset should therefore land around 5–8 ms on a real Deck. **Not yet measured on hardware.**
