# Overworld: world generation and driving (milestone 1, done)

Decisions made for the overworld MVP. These still hold.

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
