class_name RoadNetwork
extends RefCounted

const WIDTH := 9.0
## Fraction of a junction pad's radius that is plain asphalt (see road.gdshader).
const JUNCTION_CORE := 0.6


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


## Directions (x/z, unit) of every road ending at the POI in `poi_cell`. Roads to a POI are owned
## by its own cell or one of its eight neighbours, so this is a local lookup.
static func directions_at(world_seed: int, poi_cell: Vector2i) -> Array[Vector2]:
	var dirs: Array[Vector2] = []
	var poi := PoiGenerator.poi_for_cell(world_seed, poi_cell)
	if poi == null:
		return dirs
	var p := poi.position_2d()
	for z in range(-1, 2):
		for x in range(-1, 2):
			for road in roads_owned_by_cell(world_seed, poi_cell + Vector2i(x, z)):
				if road[0].is_equal_approx(p):
					dirs.append((road[1] - road[0]).normalized())
				elif road[1].is_equal_approx(p):
					dirs.append((road[0] - road[1]).normalized())
	return dirs


## Radius of the asphalt pad at a POI: big enough that any two of its roads have stopped
## overlapping by JUNCTION_CORE of the radius (narrow angles need more), within
## [min_radius, max_radius]. Beyond the core the road shader brings back per-road edge sand, which
## would z-fight if ribbons still overlapped there.
static func junction_radius(dirs: Array[Vector2], min_radius: float, max_radius: float) -> float:
	var radius := min_radius
	for i in dirs.size():
		for j in range(i + 1, dirs.size()):
			var half_angle := dirs[i].angle_to(dirs[j]) * 0.5
			var t := absf(tan(half_angle))
			var overlap := INF if t < 0.001 else (WIDTH * 0.5 + 1.5) / t
			radius = maxf(radius, overlap / JUNCTION_CORE)
	return minf(radius, max_radius)


## True when the world point is on asphalt: a road (any road in `roads`, as {a, b} dicts from
## TerrainSampler.influences_for_cell) or a POI's junction pad.
static func is_paved(p: Vector2, roads: Array, pads: Array) -> bool:
	for road: Dictionary in roads:
		if Geometry2DUtil.distance_to_segment(p, road.a, road.b) <= WIDTH * 0.5:
			return true
	for pad: Dictionary in pads:
		if p.distance_to(pad.centre) <= pad.radius:
			return true
	return false
