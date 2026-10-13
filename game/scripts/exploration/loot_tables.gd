class_name LootTables
extends RefCounted

## Deterministic container contents: the same seed, POI and container always roll the same stacks.

const SALT := 0x1007
## Stacks rolled per container kind, [min, max].
const STACKS := {
	"barrel": [1, 2], "trash": [1, 3], "furniture": [1, 2], "crate": [2, 3], "wreck": [2, 4],
	"loot_room": [4, 6],
}
## Rarity weights (common, uncommon, rare, epic) per container kind.
const RARITY_WEIGHTS := {
	"barrel": [70, 25, 5, 0], "trash": [80, 18, 2, 0], "furniture": [70, 25, 5, 0],
	"crate": [55, 33, 10, 2], "wreck": [50, 35, 12, 3], "loot_room": [25, 40, 25, 10],
}
## Items a POI type turns up more often (weight ×3 within their rarity).
const POI_FAVOURS := {
	"scrapyard": ["scrap_metal", "rusted_bolts", "alloy_plating", "servo_motor"],
	"factory": ["circuit_board", "servo_motor", "sensor_module", "wiring"],
	"settlement": ["battery", "plastic_scraps", "rubber_hose", "power_cell"],
	"homestead": ["plastic_scraps", "wiring", "battery", "rubber_hose"],
	"water_tower": ["rusted_bolts", "rubber_hose", "battery", "power_cell"],
}
const FAVOUR_WEIGHT := 3
## Stack count range by rarity, [min, max]; capped by the item's stack size.
const COUNTS := [[1, 4], [1, 2], [1, 1], [1, 1]]


static func roll(world_seed: int, poi: PoiData, container_id: String, kind: String) -> Array[Dictionary]:
	var rng := WorldHash.rng_for(world_seed, poi.cell.x, poi.cell.y, SALT ^ (hash(container_id) & 0x7fffffff))
	var span: Array = STACKS.get(kind, STACKS.crate)
	var weights: Array = RARITY_WEIGHTS.get(kind, RARITY_WEIGHTS.crate)
	var favoured: Array = POI_FAVOURS.get(poi.type_id, [])
	var out: Array[Dictionary] = []
	for i in rng.randi_range(span[0], span[1]):
		var r := _pick_weighted(rng, weights)
		var id := _pick_item(rng, ItemCatalog.ids_of(r), favoured)
		var counts: Array = COUNTS[r]
		var count := mini(rng.randi_range(counts[0], counts[1]), ItemCatalog.stack_size(id))
		var existing := ItemStacks.find(out, id)
		if not existing.is_empty() and existing.count + count <= ItemCatalog.stack_size(id):
			existing.count += count
		else:
			out.append({"id": id, "count": count})
	return out


static func _pick_weighted(rng: RandomNumberGenerator, weights: Array) -> int:
	var total := 0
	for w: int in weights:
		total += w
	var pick := rng.randi_range(0, total - 1)
	for i in weights.size():
		pick -= weights[i]
		if pick < 0:
			return i
	return 0


static func _pick_item(rng: RandomNumberGenerator, ids: Array[String], favoured: Array) -> String:
	var weights: Array = []
	for id in ids:
		weights.append(FAVOUR_WEIGHT if id in favoured else 1)
	return ids[_pick_weighted(rng, weights)]
