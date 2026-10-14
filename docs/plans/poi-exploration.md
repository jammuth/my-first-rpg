# Plan: POI exploration on foot

Status: **In progress**. Steps 1–5, 7 and 9 are done. Step 6 is cut down to an Unlock button for now, and step 8 (random encounters) is next. This is roadmap milestone 2 and comes before battles.

## Goal
Entering a POI switches from the truck to a masked explorer on foot. The explorer searches the POI's level for scrap, gets into locked loot rooms with keys or by hacking, and survives random encounters. Loot only counts once it's carried back to the truck. There it breaks down over time into the elements that will later build drone parts.

## Decided
- **Level:** each POI has a fixed level built from its existing `PoiData.layout`, so it matches what you saw while driving. The same seed always gives the same level.
- **Start and extraction:** the run starts at the parked truck, and the truck is also the extraction point.
- **Explorer:** masked, and **chosen on the main menu**. All options wear the Hoarder's face mask and scarf, recoloured khaki (sand protection). Options:
  - **Survivalist:** the Survivalist with the grafted mask and scarf.
  - **Head swap:** the Survivalist body (same outfit) with the Hoarder's head.
  - **Hoarder:** the Hoarder with no sword and no bag (`Hoarder_FrontPouch_Sword` and `Hoarder_Backpack` hidden). The shoulder straps are part of her body mesh, so they stay.
  The choice is saved. All options share one skeleton and animation set, so swapping or adding options later only adds a definition.
- **Exploration drone:** follows the explorer and does the hacking and scanning. In v1 it has fixed abilities and no stats.
- **Combat:** the explorer never attacks. Encounters are drone battles, handled by a placeholder screen until milestone 3.
- **Buildings are not walk-in.** A locked door opens a **loot window** listing the container's contents, extraction-shooter style.
- **Bag:** 8 slots in 2 rows of 4 (changed 2026-10-14 from 15), with item stacks and colour-coded rarity, similar to Arc Raiders. No grid packing (it's awkward on a gamepad). The drone adds no slots. A weight limit is parked for later.
- **Searching (step 4):** press E / A once and the bar fills by itself. Moving, pressing again or losing the target cancels it. Unlocking a door works the same way. Interacting with the truck opens a menu: Unload / Unload and drive away / Cancel.
- **Loot window (step 5):**
  - Containers hold 1–4 stacks by kind, and a loot room holds 4–6.
  - Items left behind stay in the container, are saved with the POI, and are reset by a defeat like the rest of the run.
  - Drop only works while a loot window is open: it moves a bag stack into that container.
  - I / Y opens the bag on its own to look at it and swap slots (Select is the debug overlay).
- **Search time:** searching a container takes 1–3 s while the encounter meter keeps running.
- **Camera:** a centred third-person chase camera, slightly high, with a SpringArm so walls don't clip it. The over-the-shoulder offset is a setting to try in-game.
- **Loot economy:** loot is scrap. At the truck, scrap breaks down into elements over time. Elements build drone parts in milestone 4.
- **Banking:** walking back to the truck mid-run unloads the bag and queues the breakdown. Then you can head back in.
- **Defeat:**
  - The explorer respawns at the truck and loses everything in the bag.
  - The POI resets to its state as of your last unload at the truck.
  - For now, the placeholder battle screen automatically loses the 3rd encounter of a run, so this path can be tested.
- **Looted POIs** stay looted in v1. The save stores *when* each container was looted, so the later refill (bandits move back in) only needs a rule, not a new save format.
- **Doors for now (2026-10-13):** keys and the hacking minigame are put off. A locked door opens a popup with an **Unlock** button, which goes straight to the loot window. Keys and the drone's hack slot into that popup later; the minigame design below stays as the plan for then.
- **Workshop and refining (step 9, 2026-10-13):**
  - A full-screen 2D workshop, with no 3D truck interior. It sits over a background image at `game/assets/ui/workshop_background.png`, or a plain dark fill until that exists.
  - It shows the stash, **one refining slot** fed by a queue, and the element totals. Upgrades will add slots later (`Refinery.set_slot_count`).
  - It opens with Tab / Start in the overworld, or from the truck menu in a POI.
  - Each item takes 10 / 20 / 45 / 90 s of play time by rarity, counted per item.
  - Each item's yield follows its material and rarity: its main element gives 2 / 4 / 7 / 12, a secondary element gives half, and epics add 1 core.
  - The 5 elements stay: metal, circuitry, polymer, power, core.
- **Hacking (temporary minigame, kept simple, deferred):**
  - The target code is shown at the top of the puzzle screen, with a row of symbols below it.
  - Mouse: click the button above or below a symbol to cycle it.
  - Controller: left/right selects a symbol, up/down cycles it.
  - It opens when the symbols match the code.
  - **Cost: time.** The encounter meter keeps filling while the minigame is open. There's no alarm and no failure state.
- **Encounter types:** rogue drones, raiders and mutated wildlife. Placeholder enemies are invented for now (see step 8) and get fleshed out with battles.
- **Exploration drone abilities:** scan and (later) hack. No bag slots.
- **Drone scan and minimap (step 7, 2026-10-14):**
  - The scan is always on, with no button.
  - A container or loot-room door lights up with a pulsing glow while it's on screen, within 25 m and in line of sight. Line of sight casts three rays from the camera, at the centre and at either side of the object.
  - Emptied ones stop lighting up.
  - Loot-room doors get a door frame on their wall, which glows the same way.
  - A round minimap in the top right turns with the camera. It shows buildings, the truck and the explorer, and pins everything seen, with a ping the first time.
  - Sightings are saved per POI straight away and kept after a defeat. Emptied pins go grey.
  - The drone is a placeholder quadcopter made from primitives, beside the explorer's right shoulder.
- **Truck workbench (breaking scrap down)** is in scope.

## Proposed defaults (change them if you disagree)
- **Breakdown timer:** runs on in-game play time (overworld and exploration), not real time while the game is closed. That rules out clock-change exploits.
- **Elements v1:** metal, circuitry, polymer, power cells, and a rare "core" element. Yields follow each item's material and rarity (see Workshop and refining above).
- **Rarity tiers:** common, uncommon, rare, epic, with Arc Raiders-like colours.

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
- **Character options (tested 2026-10-11, T-pose):** the head swap needs no adjustment (hide `Survivalist_Head`, graft `Hoarder_Head`, and the native mask and scarf fit). Khaki is a small luminance-to-tint shader on the mask and scarf, so the texture's shading is kept. The Hoarder's alternate texture (`hoarder_texture_B`, dark hair) could be a later hair option.
- **Main menu (new):** there's no main menu yet. Add a minimal one: New game / Continue, a character picker with a rotating 3D preview of the 3 options, and Quit. Gamepad-first.
- Build the explorer from a `CharacterOption` definition: base glb, hidden meshes, grafted meshes with scale and offset, and tinted meshes. The same code builds the menu preview and the in-game explorer.
- **Tests:** movement direction relative to camera yaw, input mapping, every `CharacterOption` building without missing meshes or bones, and saving and loading the chosen character.

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

### 6. Puzzles: keys and hacking (deferred; an Unlock button stands in)
- Loot-room doors are locked. Each one gets a key in a container elsewhere in the POI. The generator guarantees the key is reachable without opening the door it unlocks (a dependency graph with no cycles).
- Hacking: the drone runs the symbol minigame described under Decided. The code and the starting symbols are deterministic per door, and the starting symbols never already match the code.
- **Tests:** the key–door graph is always solvable over many seeds; cycling symbols wraps around; the code check; the starting symbols never match; the meter keeps filling while hacking.

### 7. Exploration drone ✅
- Follows the explorer with simple steering (NavigationAgent if needed) and hovers with a bob.
- Abilities: scan (highlights containers and loot-room doors in view, pinned on a minimap), hack (step 6, deferred).
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

### 9. Truck stash and breakdown ✅
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
