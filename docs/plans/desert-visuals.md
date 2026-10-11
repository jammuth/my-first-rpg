# Plan: Desert visual upgrade (atmosphere, blowing sand, heightmap terrain, cliffs)

Status: **in progress** on `feat/desert-visuals` (2026-10-11).

**Decided:**
- Tinted PBR textures.
- The truck follows sampled terrain height, with no physics.
- Procedural sky.
- Impassable mesas.
- View distance about 500 m, tuned after measuring.
- Approved downloads: ambientCG Ground093C (sand) and Poly Haven cliff_side (cliff), 1K maps.

## Goal
Make the overworld feel less flat and dull:
- warm yellow haze instead of the current beige fog
- a sky
- faint sand blowing in the wind
- gentle rolling terrain whose shape reads clearly at distance
- cliffs or mesas
- desert-appropriate sand and cliff textures

## Where things stand today
| Area | Current implementation |
|---|---|
| Fog / sky | `scripts/main.gd` `_make_environment()`: flat background colour, depth fog `(0.86, 0.76, 0.62)` from 150 m to 290 m |
| Ground | One 1200 m plane that follows the truck (`scripts/world/ground.gd`), noise-coloured by `shaders/ground.gdshader`. Flat at y = 0 |
| Chunks | `ChunkGenerator` (pure, worker-thread) → `ChunkManager` builds nodes. 128 m chunks, load radius 2, unload radius 3 |
| Truck | `CharacterBody3D` in floating motion mode, `y` forced to 0 |
| Roads / plazas | Flat ribbons at y = 0.06; plaza discs at POIs |
| Camera | `FollowCamera` at 45°, 36 m, with orbit. Has no terrain awareness |

## Proposed phases (each its own PR)

### Phase A: Atmosphere (small, independent)
- **Yellow fog:** depth fog tinted warm yellow, roughly `(0.93, 0.80, 0.52)`. Add `fog_sun_scatter` so the haze glows toward the sun, and height fog (`fog_height`, `fog_height_density`) so low ground sits in haze. Avoid volumetric fog because of its Steam Deck cost.
- **Sky:** see decision 3. Either:
  - `ProceduralSkyMaterial` or `PhysicalSkyMaterial` tuned dusty (no download, matches the fog, cheap), or
  - a Poly Haven HDRI at 2K.
- **Lighting:** warmer sun colour, and sky-sourced ambient light instead of a flat colour.
- **Tests:** none needed beyond a smoke run (config only).

### Phase B: Blowing sand (small)
- **Global wind:** a single wind direction and strength, exposed as a shader global uniform so every effect agrees.
- **Ground drift:** scrolling, low-contrast streaks in the terrain/ground shader, moving with the wind. Very cheap and gives most of the effect.
- **Particles:** a `GPUParticles3D` volume that follows the camera. About 200–400 small, soft, faint billboards streaming with the wind. The texture can be generated in-engine (`NoiseTexture2D` or a radial gradient), so no download.
- **Deck risk:** overdraw, so keep particles small and sparse.
- **Optional:** occasional larger dust gusts or dust devils.
- **Tests:** none needed beyond a smoke run.

### Phase C: Heightmap terrain without cliffs (large; the core change)
1. **Height function** (pure, deterministic, thread-safe): `TerrainHeight.height_at(seed, x, z)`.
   - Built on `WorldHash`-based value or simplex noise rather than `FastNoiseLite`, to guarantee cross-platform determinism and no shared state between threads.
   - Gentle dunes: about 4–12 m amplitude over 300–600 m wavelengths, plus small ripples.
   - The biome supplies the parameters, so future biomes differ.
2. **Flattening:**
   - POIs: terrain blends to the plaza height within the plaza radius plus a falloff ring.
   - Roads: terrain blends toward a smoothed road profile inside a corridor. The road profile is the terrain low-passed along the segment, with grade capped at about 8%.
3. **Terrain mesh per chunk:**
   - Built in the worker thread: a grid at 2 m spacing (65×65 vertices, about 8k triangles).
   - Normals come from the height function, not the mesh, so they match across chunk seams.
   - LOD rings: 4 m and 8 m spacing farther out, with skirts to hide cracks.
   - The following ground plane goes away.
4. **Longer view distance:** "noticeable in the distance" needs a terrain-only outer ring. For example, chunks out to radius 4–5 at low LOD with no props. Fog end moves to roughly 450–550 m.
5. **Collision:** a `HeightMapShape3D` per chunk, built from the same samples.
6. **Truck on terrain:** see decision 2. Either way the body tilts smoothly to match the slope.
7. **Placement on terrain:**
   - Roads become ribbons draped on the terrain, sampled every ~4 m along the segment at the road-profile height plus a small offset.
   - Props and POIs are placed at the terrain height; rocks are partly aligned to the slope.
8. **Camera:** keep it a minimum height above the terrain beneath it, so orbiting low can't push it into a hill.
9. **Tests:**
   - Height determinism.
   - Chunk seams agree: identical heights and normals on shared edges.
   - Flatness inside plazas.
   - Road grade under the cap.
   - Props and POIs sit on the surface.
   - The LOD skirt covers the maximum height error.

### Phase D: Cliffs / mesas (medium)
- **Cliff layer:** a second, low-frequency mask noise. Where it passes a threshold, height is pushed through a terrace function, producing steep risers between flat tiers. This reads as mesas and plateaus.
- **Keeping it drivable:** cliffs are suppressed inside road corridors, POI plazas and the spawn clearing, so every road stays drivable. Roads route through natural "passes".
- **Collision:** steep risers block the truck: walls under physics, or a slope check under sampled height.
- **Texturing:** the terrain shader blends sand on flat ground with cliff rock where the slope is steep, using the normal's `y` component. Rock is triplanar-mapped on steep faces only, to avoid stretching while keeping cost down.
- **Tests:**
  - No cliff-grade slopes inside road corridors or plazas.
  - The cliff mask is deterministic.
  - Every POI stays reachable by road. Re-run the existing road tests with the terrain in place.

### Phase E: Textures (small once the decisions are made)
Download 1K or 2K sets into `art_source/`, copy only the maps used into `game/`, and wire them into the terrain shader:
- albedo, normal and roughness
- AO optional
- displacement unused

## Candidate CC0 assets (verified CC0 sources; not downloaded)

**Sand**
| Asset | Why | Link |
|---|---|---|
| ambientCG **Ground093C** (also 093B) | Tagged desert, dune, accumulation; beige rippled sand | https://ambientcg.com/view?id=Ground093C |
| ambientCG **Ground096A** | Desert, dry, eroded, granular; good for hardpan between dunes | https://ambientcg.com/view?id=Ground096A |
| Poly Haven **sandy_gravel_02** | Tagged desert/dusty, Namaqualand collection, 2.5 m tile | https://polyhaven.com/a/sandy_gravel_02 |
| Poly Haven **aerial_beach_01** | 30 m tile of wavy sand; useful as a macro variation layer to break tiling | https://polyhaven.com/a/aerial_beach_01 |

**Cliff / rock**
| Asset | Why | Link |
|---|---|---|
| Poly Haven **cliff_side** | Stratified, orange, sedimentary canyon rock. **Top pick** for mesas | https://polyhaven.com/a/cliff_side |
| ambientCG **Rock029** | Tagged cliff, desert, orange/red | https://ambientcg.com/view?id=Rock029 |
| Poly Haven **worn_rock_natural_01** | Yellow weathered sandstone | https://polyhaven.com/a/worn_rock_natural_01 |
| Poly Haven **rock_06** | Yellow, striated cliff face | https://polyhaven.com/a/rock_06 |

**Sky (HDRI; only if we don't go procedural)**
| Asset | Why | Link |
|---|---|---|
| Poly Haven **goegap** | Clear midday desert, high contrast | https://polyhaven.com/a/goegap |
| Poly Haven **valley_of_desolation** | Clear, desert canyon and mesa; matches cliffs | https://polyhaven.com/a/valley_of_desolation |
| Poly Haven **rogland_sunset** | Clear arid sunset, if we want a warmer, moodier time of day | https://polyhaven.com/a/rogland_sunset |

HDRIs include the photographed ground in their lower half. With our high camera, the fog and terrain mostly hide it, but expect a seam at the horizon when orbiting low.

## Decisions to make when picking this up
1. **Art direction.** The props and buildings are stylised low-poly (Kenney/KayKit, flat colours). Photoreal PBR textures can clash with them. Options:
   - Use the textures, but tinted, desaturated and low-res toward the palette (recommended middle ground).
   - Use only their normal and roughness maps, over a stylised colour ramp.
   - Go fully photoreal and accept the mismatch.
2. **How the truck follows the terrain.**
   - **(a) Physics:** grounded `CharacterBody3D` with gravity, floor snap and `HeightMapShape3D`. Cliffs block naturally via `floor_max_angle`, but there's some physics jitter and tuning.
   - **(b) Sampled height:** set `y` from `height_at` and tilt from sampled normals, keeping the "no real driving physics" feel. Cheap and deterministic, but needs a manual slope check to stop the truck at cliffs.
   - Leaning (b), to match the original "moves like a walking character" brief.
3. **Sky:** procedural (no download, tunable to match the fog) or an HDRI from the list above.
4. **Cliffs:**
   - Impassable mesas only, with roads routing around them (recommended for the MVP)?
   - Or also drivable ramps up onto plateaus? That needs ramp generation and more road logic.
5. **View distance vs Steam Deck budget.** How far should the terrain silhouette be visible? This sets the LOD ring count and fog distances. Plan to measure on a Deck (or a Deck-like profile) after Phase C.

## Suggested order
A → B (quick visible wins, no risk) → C → D → E. E can be done alongside C/D once decision 1 is made.
