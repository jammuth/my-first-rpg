class_name RoadNetwork
extends RefCounted

const WIDTH := 9.0


## Each road is owned by exactly one cell (the one with the lower coords along its direction), so
## chunks can query roads locally without duplicates. Diagonals only appear when both orthogonal
## cells they would bypass are empty, which keeps the network connected without crossings.
static func roads_owned_by_cell(world_seed: int, cell: Vector2i) -> Array[PackedVector2Array]:
	var roads: Array[PackedVector2Array] = []
	var a := PoiGenerator.poi_for_cell(world_seed, cell)
	if a == null:
		return roads
	var right := PoiGenerator.poi_for_cell(world_seed, cell + Vector2i(1, 0))
	var down := PoiGenerator.poi_for_cell(world_seed, cell + Vector2i(0, 1))
	var up := PoiGenerator.poi_for_cell(world_seed, cell + Vector2i(0, -1))
	for b in [right, down]:
		if b != null:
			roads.append(PackedVector2Array([a.position_2d(), b.position_2d()]))
	if right == null and down == null:
		var diag := PoiGenerator.poi_for_cell(world_seed, cell + Vector2i(1, 1))
		if diag != null:
			roads.append(PackedVector2Array([a.position_2d(), diag.position_2d()]))
	if right == null and up == null:
		var diag := PoiGenerator.poi_for_cell(world_seed, cell + Vector2i(1, -1))
		if diag != null:
			roads.append(PackedVector2Array([a.position_2d(), diag.position_2d()]))
	return roads


## Full (unclipped) road segments that pass through `rect`.
static func roads_touching_rect(world_seed: int, rect: Rect2) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var poi_cell_size := PoiGenerator.CELL_SIZE
	# Roads span at most to a diagonal neighbour, so owners lie within one POI cell of the rect.
	var search := rect.grow(poi_cell_size)
	for cell in ChunkMath.cells_overlapping(search, poi_cell_size):
		for road in roads_owned_by_cell(world_seed, cell):
			if not Geometry2DUtil.clip_segment_to_rect(road[0], road[1], rect.grow(WIDTH)).is_empty():
				result.append(road)
	return result
