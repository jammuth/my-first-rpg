class_name ChunkGenerator
extends RefCounted

## Pure, thread-safe chunk content generation: no scene tree or resource loading in here.

const CHUNK_SIZE := 128.0
const ROAD_HEIGHT := 0.06
const ROAD_PROP_CLEARANCE := 3.0
const POI_PROP_CLEARANCE := 6.0
const SPAWN_CLEAR_RADIUS := 15.0
const SALT := 0xC4A


static func generate(world_seed: int, cell: Vector2i) -> ChunkData:
	var data := ChunkData.new()
	data.cell = cell
	var rect := ChunkMath.cell_rect(cell, CHUNK_SIZE)
	var roads := RoadNetwork.roads_touching_rect(world_seed, rect)
	for road in roads:
		var clipped := Geometry2DUtil.clip_segment_to_rect(road[0], road[1], rect)
		if not clipped.is_empty() and clipped[0].distance_squared_to(clipped[1]) > 0.0001:
			data.road_segments.append(clipped)
	_build_road_mesh(data)
	data.pois = PoiGenerator.pois_in_rect(world_seed, rect)
	var nearby_pois := PoiGenerator.pois_in_rect(world_seed, rect.grow(64.0))
	_scatter_props(world_seed, cell, rect, roads, nearby_pois, data)
	return data


static func _build_road_mesh(data: ChunkData) -> void:
	for seg in data.road_segments:
		var a := seg[0]
		var b := seg[1]
		var dir := (b - a).normalized()
		var side := Vector2(-dir.y, dir.x) * (RoadNetwork.WIDTH * 0.5)
		var base := data.road_vertices.size()
		for p in [a + side, a - side, b + side, b - side]:
			data.road_vertices.append(Vector3(p.x, ROAD_HEIGHT, p.y))
		# V runs in world distance along the road so markings line up across chunk seams.
		var va := a.dot(dir) / RoadNetwork.WIDTH
		var vb := b.dot(dir) / RoadNetwork.WIDTH
		data.road_uvs.append_array(PackedVector2Array([
			Vector2(0, va), Vector2(1, va), Vector2(0, vb), Vector2(1, vb)]))
		data.road_indices.append_array(PackedInt32Array([
			base, base + 2, base + 1, base + 1, base + 2, base + 3]))


static func _scatter_props(world_seed: int, cell: Vector2i, rect: Rect2,
		roads: Array[PackedVector2Array], pois: Array[PoiData], data: ChunkData) -> void:
	var biome := BiomeMap.biome_at_cell(world_seed, cell)
	var rng := WorldHash.rng_for(world_seed, cell.x, cell.y, SALT)
	var hectares := (CHUNK_SIZE * CHUNK_SIZE) / 10000.0
	# Per-chunk density swing so the desert isn't a uniform carpet.
	var density := rng.randf_range(0.4, 1.6)
	for def in biome.props:
		var transforms: Array[Transform3D] = []
		var count := int(round(def.per_hectare * hectares * density * rng.randf_range(0.7, 1.3)))
		for i in count:
			var p := Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y))
			var s := rng.randf_range(def.min_scale, def.max_scale)
			var yaw := rng.randf() * TAU
			var footprint: float = def.radius * s
			if not is_prop_spot_clear(p, footprint, roads, pois):
				continue
			var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s)
			var pos := Vector3(p.x, 0.0, p.y)
			transforms.append(Transform3D(basis, pos))
			if def.solid:
				data.solids.append({"position": pos, "radius": footprint})
		if not transforms.is_empty():
			data.props[def.id] = transforms


static func is_prop_spot_clear(p: Vector2, footprint: float, roads: Array[PackedVector2Array],
		pois: Array[PoiData]) -> bool:
	if p.length() < SPAWN_CLEAR_RADIUS + footprint:
		return false
	var road_clear := RoadNetwork.WIDTH * 0.5 + ROAD_PROP_CLEARANCE + footprint
	for road in roads:
		if Geometry2DUtil.distance_to_segment(p, road[0], road[1]) < road_clear:
			return false
	for poi in pois:
		if p.distance_to(poi.position_2d()) < poi.plaza_radius + POI_PROP_CLEARANCE + footprint:
			return false
	return true
