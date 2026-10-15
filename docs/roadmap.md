# Roadmap

Order of milestones for the MVP and beyond. Each milestone gets its own plan in `docs/plans/` when it starts.

| # | Milestone | Status | Plan |
|---|---|---|---|
| 1 | Overworld: world generation and driving | ✅ Done (PRs #1–#5) | [desert-visuals.md](plans/desert-visuals.md) (visuals phase) |
| 2 | POI exploration on foot | 🚧 In progress (steps 1–5, 7 and 9 of 10 done) | [poi-exploration.md](plans/poi-exploration.md) |
| 3 | Turn-based drone battles | ⏳ Not started | — |
| 4 | Drone building and upgrading | ⏳ Not started | — |
| 5 | Story mode | ⏳ Not started | — |

## 1. Overworld ✅
- An infinite desert, the same every time for a given seed, streamed in chunks.
- Roads between POIs; the truck can also drive off-road.
- Tank-control truck with a low follow camera and a compass bar showing the 3 nearest POIs.
- Interact with a POI to open a placeholder panel and mark it visited.
- Linux and Windows export builds. A real Steam Deck benchmark is still outstanding (see [steam-deck.md](steam-deck.md)).

## 2. POI exploration 🚧
- Entering a POI starts a level built from that POI's layout.
- You start at the parked truck, which is also where you extract.
- A masked explorer in third person, followed by an exploration drone.
- Looting uses a slot bag with rarities. Loot only counts once it's back at the truck.
- Locked loot rooms open with a key or a hacking minigame.
- Random encounters open a placeholder battle screen, where the real battle system plugs in later.
- At the truck, scrap breaks down into elements over time, in a workshop with one upgradable refining slot.

## 3. Turn-based drone battles
- Medabots-style drones built from parts. Each part (left arm, right arm, head, legs) gives the drone actions.
- Plugs into the exploration encounter hook and replaces the placeholder screen. Losing a battle keeps the same consequences as in milestone 2.
- Enemy types: rogue drones, raiders, mutated wildlife.

## 4. Drone building and upgrading
- Spend elements at the truck workshop to build and upgrade drone parts.
- The exploration drone gets upgradeable parts too (scan range, hacking).

## 5. Story mode
- Settlements, characters and a narrative layer over the overworld.

## Later / parked
- More biomes beyond the desert.
- Looted POIs refill over time (bandits move back in).
- A final design for the hacking minigame.
- An optional weight limit on top of bag slots.
