# Art sources

`art_source/` is gitignored. It holds the original downloads, and only the files the game needs are copied into `game/assets/`. Use this list to rebuild it on a new machine. Every pack is CC0.

| Pack | Used for | Download | Into `art_source/` |
|---|---|---|---|
| Kenney City Kit (Commercial) 2.1 | POI buildings | https://kenney.nl/assets/city-kit-commercial | `kenney_city-kit-commercial_2.1/` |
| Kenney City Kit (Industrial) 2.0 | POI buildings | https://kenney.nl/assets/city-kit-industrial | `kenney_city-kit-industrial_2.0/` |
| Kenney City Kit (Suburban) 2.0 | POI buildings | https://kenney.nl/assets/city-kit-suburban | `kenney_city-kit-suburban_20/` |
| Kenney Car Kit | Truck (`delivery`), debris | https://kenney.nl/assets/car-kit | `kenney_car-kit/` |
| Quaternius Farm Buildings | Farm POIs | https://quaternius.com/packs/farmbuildings.html (Google Drive folder) | `quaternius_farm_buildings/` |
| Quaternius Zombie Apocalypse Kit | Wrecked vehicles/props | https://quaternius.com/packs/zombieapocalypsekit.html (Google Drive folder) | `quaternius_zombie_apocalypse_kit/` |
| Quaternius Ultimate Nature Pack | Cactus_1–4 | https://quaternius.com/packs/ultimatenature.html (Google Drive folder) | `quaternius_ultimate_nature/` (Cactus_1–4 `.fbx` at the top level, read by `game/tools/bake_plants.gd`) |
| Poly Haven dry_branches_medium_01 (1K glTF) | Dry branches | https://polyhaven.com/a/dry_branches_medium_01 | `polyhaven_dry_branches_medium_01/dry_branches_medium_01.gltf` (+ `textures/`) |
| Poly Haven namaqualand_boulder_02/04/05 (1K glTF) | Boulders | https://polyhaven.com/a/namaqualand_boulder_02 (and _04, _05) | `polyhaven_namaqualand_boulder_0X/namaqualand_boulder_0X.gltf` (read by `game/tools/bake_rocks.gd`) |
| Poly Haven asphalt_04 (1K) | Roads | https://polyhaven.com/a/asphalt_04 | `polyhaven_asphalt_04/` |
| Poly Haven cliff_side (1K) | Mesa cliffs | https://polyhaven.com/a/cliff_side | `polyhaven_cliff_side/` |
| ambientCG Ground093C (1K JPG) | Sand | https://ambientcg.com/view?id=Ground093C | `ambientcg_Ground093C_1K-JPG/` |
| The Complete KayKit Collection v7 | Explorer characters, Rig_Medium animations, Resource/RPG Tools/Prototype/Halloween Bits | Patreon / itch.io (needs your login): https://kaylousberg.itch.io | `kaykit/` |

Add a row here whenever a new pack is downloaded.
