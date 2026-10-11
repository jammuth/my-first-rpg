# Plan: POI exploration on foot

Status: **Planned** (2026-10-11). This is roadmap milestone 2 and comes before battles.

## Goal
Entering a POI switches from the truck to a masked explorer on foot. The explorer searches the POI's level for scrap, gets into locked loot rooms with keys or by hacking, and survives random encounters. Loot only counts once it's carried back to the truck. There it breaks down over time into the elements that will later build drone parts.

## Decided
- **Level:** each POI has a fixed level built from its existing `PoiData.layout`, so it matches what you saw while driving. The same seed always gives the same level.
- **Start and extraction:** the run starts at the parked truck, and the truck is also the extraction point.
- **Explorer:** masked. The KayKit Survivalist wearing the Hoarder's face mask and scarf is preferred (see step 2), with the Hoarder as fallback. Female is fine. The model must be swappable.
- **Exploration drone:** follows the explorer and does the hacking and scanning. In v1 it has fixed abilities and no stats.
- **Combat:** the explorer never attacks. Encounters are drone battles, handled by a placeholder screen until milestone 3.
- **Buildings are not walk-in.** A locked door opens a **loot window** listing the container's contents, extraction-shooter style.
- **Bag:** 15 slots in 3 rows of 5, with item stacks and colour-coded rarity, similar to Arc Raiders. No grid packing (it's awkward on a gamepad). The exploration drone adds extra slots on top (see Proposed defaults). A weight limit is parked for later.
- **Search time:** searching a container takes 1–3 s while the encounter meter keeps running.
- **Camera:** a centred third-person chase camera, slightly high, with a SpringArm so walls don't clip it. The over-the-shoulder offset is a setting to try in-game.
- **Loot economy:** loot is scrap. At the truck, scrap breaks down into elements over time. Elements build drone parts in milestone 4.
- **Banking:** walking back to the truck mid-run unloads the bag and queues the breakdown. Then you can head back in.
- **Defeat:**
  - The explorer respawns at the truck and loses everything in the bag.
  - The POI resets to its state as of your last unload at the truck.
  - For now, the placeholder battle screen automatically loses the 3rd encounter of a run, so this path can be tested.
- **Looted POIs** stay looted in v1. The save stores *when* each container was looted, so the later refill (bandits move back in) only needs a rule, not a new save format.
- **Hacking (temporary minigame, kept simple):**
  - The target code is shown at the top of the puzzle screen, with a row of symbols below it.
  - Mouse: click the button above or below a symbol to cycle it.
  - Controller: left/right selects a symbol, up/down cycles it.
  - It opens when the symbols match the code.
  - **Cost: time.** The encounter meter keeps filling while the minigame is open. There's no alarm and no failure state.
- **Encounter types:** rogue drones, raiders and mutated wildlife. Placeholder enemies are invented for now (see step 8) and get fleshed out with battles.
- **Exploration drone abilities:** scan (highlights containers and keys), hack, and extra bag slots.
- **Truck workbench (breaking scrap down)** is in scope.

## Proposed defaults (change them if you disagree)
- **Breakdown timer:** runs on in-game play time (overworld and exploration), not real time while the game is closed. That rules out clock-change exploits.
- **Elements v1:** metal, circuitry, polymer, power cells, and a rare "core" element. Each scrap item has a fixed yield table. Rarer scrap gives more of the rarer elements.
- **Rarity tiers:** common, uncommon, rare, epic, with Arc Raiders-like colours.
- **Drone bag slots:** +5, as one extra row below the 15-slot bag.

## Where things stand today
| Area | Current implementation |
|---|---|
| POI data | `PoiData`: id, type, name, position, yaw, plaza radius, and `layout` (catalogue pieces placed by `PoiPlanner` from `DesertPoiLayouts`) |
| POI types | Scrapyard, Factory, Settlement, Homestead, Water Tower (`DesertBiome`) |
| Entering a POI | `hud.gd` prompt "Press E/A to enter <name>", then a placeholder panel with a Leave button. `GameState.mark_visited` |
| State/save | `GameState` autoload: seed, visited POIs, truck position and yaw, floating origin. JSON save |
| Assets | Explorer: KayKit Hoarder (Series 6 #8, Rig_Medium, separate `Hoarder_FaceMask` mesh). Animations: Series 6 `Rig_Medium_General` and `Rig_Medium_MovementBasic`. Crates: KayKit Resource Bits. Keys: KayKit RPG Tools Bits. Doors: KayKit Prototype Bits. Drone placeholder: KayKit Robot or a simple mesh. All CC0 and already in `art_source/` |

## Steps (each its own PR, tests written alongside)

### 1. Scene flow and exploration state
- "Enter" on the POI panel starts an exploration of that POI. A new `ExplorationSession` (pure state) holds the POI id, bag, encounter count and run seed.
- The overworld is swapped out or paused during the run and comes back exactly as it was: truck position, yaw, floating origin and chunks.
- Save format: add `poi_states[poi_id]` (looted containers with timestamps, unlocked doors), `truck_stash`, `elements` and `breakdown_queue`. Old saves must still load.
- **Tests:** state transitions (enter, bank, defeat, extract), save round-trip, loading an old save.

### 2. Explorer on foot
- Character scene built from the Hoarder: mask on, backpack shown. The character is loaded through one scene/resource so the model can be swapped.
- Animations: idle, walk, run and interact from the shared Rig_Medium packs.
- Movement relative to the camera, with no physics beyond `CharacterBody3D`. Keyboard, mouse and gamepad all work.
- Chase camera with a SpringArm, plus the shoulder-offset setting.
- **Survivalist + Hoarder mask (requested experiment):** move `Hoarder_FaceMask` and the `Hoarder_CollarArmor` scarf (protection from sand) onto the Survivalist's skeleton. Both use the same Rig_Medium bone names, so the skin can be remapped by name. **Tested on 2026-10-11 (T-pose only):** the swap works with no Blender. Each skin bind is remapped by bone name, and the mask is scaled 1.15× and moved 0.04 m forward in head-bone space, done in the skin's bind poses. That fully covers the beard and the larger nose. The scarf fits unchanged, and looks clean from behind, which is the angle the chase camera uses. Still to check in-game: clipping in the run and idle animations. The fallback is the Hoarder.
- **Tests:** movement direction relative to camera yaw, input mapping.

### 3. Building the level from a POI
- `ExplorationLevelBuilder` (pure, deterministic): takes `PoiData` and the seed, and returns a level description:
  - walkable ground and blocking volumes for buildings and props
  - truck parking spot and extraction zone at the road entrance
  - container spots (crates, wrecks, trash piles)
  - loot-room doors on some building faces
- Built from the existing catalogue footprints. The scale can grow so it feels right on foot (tuned in-game).
- The scene builder instances it, reusing MultiMesh and prop libraries where possible.
- **Tests:** same seed gives the same level; no spawn point inside a footprint; every container and door can be reached from the truck (flood fill on a coarse grid).

### 4. Interactables
- One `Interactable` base: prompt text ("Press E/A to search", "…unlock", "…hack", "…unload"), range, and a hold-to-search progress bar.
- Kinds: container, loot-room door, truck.
- Picks the nearest interactable the explorer is facing.
- **Tests:** target selection (nearest, facing, out of range).

### 5. Loot, bag and loot window
- Item definitions (resource or dictionary): id, name, rarity, stack size, element yield.
- Loot tables per POI type and container kind. Rolls are deterministic per container (seed + POI + container index).
- Bag: slots and stacking, plus take, take all, drop and swap.
- Loot window UI: container contents on one side, bag on the other. Works on gamepad first.
- **Tests:** loot rolls are deterministic, rarity weights add up, stacking and overflow rules, rejecting items when the bag is full.

### 6. Puzzles: keys and hacking
- Loot-room doors are locked. Each one gets a key in a container elsewhere in the POI. The generator guarantees the key is reachable without opening the door it unlocks (a dependency graph with no cycles).
- Hacking: the drone runs the symbol minigame described under Decided. The code and the starting symbols are deterministic per door, and the starting symbols never already match the code.
- **Tests:** the key–door graph is always solvable over many seeds; cycling symbols wraps around; the code check; the starting symbols never match; the meter keeps filling while hacking.

### 7. Exploration drone
- Follows the explorer with simple steering (NavigationAgent if needed) and hovers with a bob.
- Abilities: scan (highlights containers and keys within a radius), hack (step 6), +5 bag slots.
- **Tests:** follow and steering maths (pure parts).

### 8. Random encounters
- An encounter meter that fills with distance walked and time spent searching or hacking. The rate depends on POI type. The encounter type is a weighted roll.
- Placeholder enemies (temporary, to test exploration):
  - **Rogue drones:** Scrap Hound, Sentry Unit.
  - **Raiders:** Dust Raider, Raider Gunner.
  - **Mutated wildlife:** Glass Scorpion, Dune Crawler.
  - Each has a name, a weight per POI type and a placeholder threat level.
- Placeholder battle screen: shows the enemy, with Win and Lose buttons. It automatically loses the 3rd encounter of a run. This is the hook for milestone 3.
- Defeat flow as described under Decided.
- **Tests:** meter accumulation, deterministic encounter rolls, the 3rd-encounter loss, POI reset to the last unload.

### 9. Truck stash and breakdown
- Unloading at the truck moves bag items into the truck stash and queues their breakdown.
- The breakdown timer runs on play time and turns scrap into elements.
- A minimal truck panel (also reachable from the overworld) shows the stash, queue and element totals.
- **Tests:** queue timing, element yields, saving and loading a queue that's partway through.

### 10. Polish and Deck pass
- The compass during exploration points to the truck and to found keys.
- The overworld POI marker shows visited or looted status.
- Steam Deck performance check (draw calls, MultiMesh), and controller check across all the new UI.
- Run the full test suite.

## Out of scope
- Real battles (milestone 3).
- Building and upgrading drone parts (milestone 4).
- POIs refilling over time.
- Walk-in building interiors.
- A final design for the hacking minigame.
- A weight limit.

## Risks and open questions
- **Scale:** the overworld buildings aren't to scale. Footprints may need scaling up, or extra props, for the levels to feel worth exploring. Tune in step 3.
- **Drone model:** no clean flying-drone model has been found in `art_source/` yet. The plan starts with a placeholder, and any download asks first (CC0 only).
- **Animation rig:** the Hoarder's 23-bone rig should work with the Series 6 animation packs. Confirm at import in step 2.
