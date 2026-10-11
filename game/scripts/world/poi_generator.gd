class_name PoiGenerator
extends RefCounted

const CELL_SIZE := 256.0
## Keeps POIs away from cell edges so neighbours never crowd each other and the world origin
## (a shared corner of four cells) is always clear for spawning.
const EDGE_MARGIN := 48.0
const SALT := 0x501


static func world_to_cell(pos: Vector3) -> Vector2i:
	return ChunkMath.world_to_cell(pos, CELL_SIZE)


## Returns null when the cell has no POI.
static func poi_for_cell(world_seed: int, cell: Vector2i) -> PoiData:
	var rng := WorldHash.rng_for(world_seed, cell.x, cell.y, SALT)
	var biome := BiomeMap.biome_at_cell(world_seed, cell)
	if rng.randf() >= biome.poi_chance:
		return null
	var origin := ChunkMath.cell_origin(cell, CELL_SIZE)
	var poi := PoiData.new()
	poi.cell = cell
	poi.id = "%d_%d" % [cell.x, cell.y]
	poi.position = origin + Vector3(
		rng.randf_range(EDGE_MARGIN, CELL_SIZE - EDGE_MARGIN), 0.0,
		rng.randf_range(EDGE_MARGIN, CELL_SIZE - EDGE_MARGIN))
	poi.yaw = rng.randf() * TAU
	var type := biome.pick_poi_type(rng)
	poi.type_id = type.id
	poi.type_label = type.label
	poi.plaza_radius = type.plaza_radius
	poi.ruin_chance = type.ruin_chance
	poi.display_name = "%s %s" % [NameGenerator.make(rng), type.label]
	return poi


static func pois_in_rect(world_seed: int, rect: Rect2) -> Array[PoiData]:
	var result: Array[PoiData] = []
	for cell in ChunkMath.cells_overlapping(rect, CELL_SIZE):
		var poi := poi_for_cell(world_seed, cell)
		if poi != null and rect.has_point(poi.position_2d()):
			result.append(poi)
	return result


## Searches outward ring by ring; stops once enough POIs are found and no closer ring could beat them.
static func nearest(world_seed: int, pos: Vector3, count: int, max_ring: int = 6) -> Array[PoiData]:
	var center := world_to_cell(pos)
	var p := Vector2(pos.x, pos.z)
	var found: Array[PoiData] = []
	for ring in range(0, max_ring + 1):
		for z in range(-ring, ring + 1):
			for x in range(-ring, ring + 1):
				if maxi(absi(x), absi(z)) != ring:
					continue
				var poi := poi_for_cell(world_seed, center + Vector2i(x, z))
				if poi != null:
					found.append(poi)
		if found.size() >= count:
			found.sort_custom(func(a: PoiData, b: PoiData) -> bool:
				return a.position_2d().distance_squared_to(p) < b.position_2d().distance_squared_to(p))
			# Anything in the next ring is at least `ring * CELL_SIZE` away from pos.
			if found[count - 1].position_2d().distance_to(p) <= ring * CELL_SIZE:
				break
	found.sort_custom(func(a: PoiData, b: PoiData) -> bool:
		return a.position_2d().distance_squared_to(p) < b.position_2d().distance_squared_to(p))
	return found.slice(0, count)


## How far past the plaza edge the "Press E" prompt still shows.
const INTERACT_MARGIN := 10.0


## The POI the player can enter from `pos`, or null.
static func interactable(world_seed: int, pos: Vector3) -> PoiData:
	var near := nearest(world_seed, pos, 1, 2)
	if near.is_empty():
		return null
	var poi := near[0]
	if poi.position_2d().distance_to(Vector2(pos.x, pos.z)) <= poi.plaza_radius + INTERACT_MARGIN:
		return poi
	return null
