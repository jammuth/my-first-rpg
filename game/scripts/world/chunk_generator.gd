class_name ChunkGenerator
extends RefCounted

## Pure, thread-safe chunk content generation: no scene tree or resource loading in here.

const CHUNK_SIZE := 128.0
const ROAD_HEIGHT := 0.15
const ROAD_SAMPLE_STEP := 4.0
## Asphalt pad at the centre of every POI with roads. Roads run plain asphalt inside it (matching
## the pad), so their square ends and overlaps merge into one round junction.
const JUNCTION_MIN_RADIUS := 16.0
## How far past the plaza edge a pad may reach (the terrain is still nearly flat there).
const JUNCTION_PLAZA_OVERHANG := 6.0
const JUNCTION_SEGMENTS := 32
## The pad sits just under the road ribbons.
const JUNCTION_DROP := 0.05
const ROAD_PROP_CLEARANCE := 3.0
const POI_PROP_CLEARANCE := 6.0
const SPAWN_CLEAR_RADIUS := 15.0
const SALT := 0xC4A
## Props are skipped on slopes steeper than this (normal.y), i.e. cliff faces.
const PROP_MIN_NORMAL_Y := 0.85


static func generate(world_seed: int, cell: Vector2i, sampler: TerrainSampler = null) -> ChunkData:
	if sampler == null:
		sampler = TerrainSampler.new(world_seed)
	var data := ChunkData.new()
	data.cell = cell
	var rect := ChunkMath.cell_rect(cell, CHUNK_SIZE)
	var influences := sampler.influences_for_cell(cell)
	var roads: Array[PackedVector2Array] = []
	for road in influences.roads:
		roads.append(PackedVector2Array([road.a, road.b]))
		var clipped := Geometry2DUtil.clip_segment_to_rect(road.a, road.b, rect)
		if not clipped.is_empty() and clipped[0].distance_squared_to(clipped[1]) > 0.0001:
			data.road_segments.append(clipped)
			data.road_ends.append(PackedVector2Array([road.a, road.b]))
	_build_road_mesh(data, sampler, world_seed)
	data.pois = PoiGenerator.pois_in_rect(world_seed, rect)
	for poi in data.pois:
		poi.position.y = sampler.poi_height(poi)
		var biome := BiomeMap.biome_at_cell(world_seed, poi.cell)
		var dirs := PoiPlanner.road_directions(poi, influences.roads)
		poi.layout = PoiPlanner.plan(world_seed, poi, biome.poi_layouts[poi.type_id], poi.ruin_chance, dirs)
		if not dirs.is_empty():
			_build_junction(data, poi, sampler, poi_junction_radius(world_seed, poi.cell))
	var nearby_pois: Array[PoiData] = []
	for e in influences.pois:
		nearby_pois.append(e.poi)
	_scatter_props(world_seed, cell, rect, roads, nearby_pois, data, sampler)
	return data


static func poi_junction_radius(world_seed: int, poi_cell: Vector2i) -> float:
	var poi := PoiGenerator.poi_for_cell(world_seed, poi_cell)
	return RoadNetwork.junction_radius(RoadNetwork.directions_at(world_seed, poi_cell),
		JUNCTION_MIN_RADIUS, poi.plaza_radius + JUNCTION_PLAZA_OVERHANG)


static func _build_road_mesh(data: ChunkData, sampler: TerrainSampler, world_seed: int) -> void:
	for s in data.road_segments.size():
		var seg := data.road_segments[s]
		var ends := data.road_ends[s]
		var end_radii := [
			poi_junction_radius(world_seed, PoiGenerator.world_to_cell(Vector3(ends[0].x, 0, ends[0].y))),
			poi_junction_radius(world_seed, PoiGenerator.world_to_cell(Vector3(ends[1].x, 0, ends[1].y)))]
		var a := seg[0]
		var b := seg[1]
		var length := a.distance_to(b)
		var dir := (b - a) / length
		var side := Vector2(-dir.y, dir.x) * (RoadNetwork.WIDTH * 0.5)
		var steps := maxi(1, ceili(length / ROAD_SAMPLE_STEP))
		var base := data.road_vertices.size()
		for i in steps + 1:
			var p := a + dir * (length * i / steps)
			# Sample the real terrain at each edge so the ribbon hugs it, including where plaza and
			# road blending bend the surface away from the ideal road profile.
			for e in [p + side, p - side]:
				data.road_vertices.append(Vector3(e.x, sampler.height_at(e.x, e.y) + ROAD_HEIGHT, e.y))
			# V runs in world distance along the road so markings line up across chunk seams.
			var v := p.dot(dir) / RoadNetwork.WIDTH
			data.road_uvs.append_array(PackedVector2Array([Vector2(0, v), Vector2(1, v)]))
			# Roads always end at POI centres: distance to the nearer end in units of that end's pad
			# radius lets the shader turn the road into plain asphalt inside the pad.
			var to_end: float = minf(p.distance_to(ends[0]) / end_radii[0], p.distance_to(ends[1]) / end_radii[1])
			data.road_uv2s.append_array(PackedVector2Array([Vector2(to_end, 0), Vector2(to_end, 0)]))
			if i > 0:
				var k := base + (i - 1) * 2
				data.road_indices.append_array(PackedInt32Array([k, k + 2, k + 1, k + 1, k + 2, k + 3]))


## Round pad with a centre vertex and two rings, following the terrain (large pads reach past the
## flat plaza). UV.x runs from the centre (0.5) to the rim (1) so the road shader's edge sand rings
## it; UV2.y = 1 marks it as a pad so that sand isn't suppressed.
static func _build_junction(data: ChunkData, poi: PoiData, sampler: TerrainSampler, radius: float) -> void:
	var c := poi.position
	var base := data.junction_vertices.size()
	data.junction_vertices.append(Vector3(c.x, c.y + ROAD_HEIGHT - JUNCTION_DROP, c.z))
	data.junction_uvs.append(Vector2(0.5, 0.0))
	for ring: float in [0.5, 1.0]:
		for i in JUNCTION_SEGMENTS:
			var d := Vector2.from_angle(TAU * i / JUNCTION_SEGMENTS) * radius * ring
			var x := c.x + d.x
			var z := c.z + d.y
			data.junction_vertices.append(Vector3(x, sampler.height_at(x, z) + ROAD_HEIGHT - JUNCTION_DROP, z))
			data.junction_uvs.append(Vector2(0.5 + 0.5 * ring, 0.0))
	for i in JUNCTION_SEGMENTS:
		var j := (i + 1) % JUNCTION_SEGMENTS
		var inner_i := base + 1 + i
		var inner_j := base + 1 + j
		var outer_i := inner_i + JUNCTION_SEGMENTS
		var outer_j := inner_j + JUNCTION_SEGMENTS
		data.junction_indices.append_array(PackedInt32Array([
			base, inner_j, inner_i,
			inner_i, inner_j, outer_i,
			inner_j, outer_j, outer_i]))


static func _scatter_props(world_seed: int, cell: Vector2i, rect: Rect2,
		roads: Array[PackedVector2Array], pois: Array[PoiData], data: ChunkData,
		sampler: TerrainSampler) -> void:
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
			if sampler.normal_at(p.x, p.y, 1.5).y < PROP_MIN_NORMAL_Y:
				continue
			var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s)
			var pos := Vector3(p.x, sampler.height_at(p.x, p.y) - def.get("sink", 0.0) * s, p.y)
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
