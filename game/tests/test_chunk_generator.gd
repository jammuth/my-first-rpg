extends TestCase

const SEED := 1337


func test_deterministic() -> void:
	var a := ChunkGenerator.generate(SEED, Vector2i(3, -2))
	var b := ChunkGenerator.generate(SEED, Vector2i(3, -2))
	assert_eq(a.road_vertices, b.road_vertices)
	assert_eq(a.props.keys(), b.props.keys())
	for k in a.props:
		assert_eq(a.props[k], b.props[k])
	assert_eq(a.solids.size(), b.solids.size())


func test_chunks_have_props() -> void:
	var total := 0
	for x in 4:
		var data := ChunkGenerator.generate(SEED, Vector2i(x, 5))
		for k in data.props:
			total += data.props[k].size()
	assert_true(total > 20, "only %d props in 4 chunks" % total)


func test_props_stay_off_roads_and_plazas() -> void:
	for x in range(-3, 3):
		for z in range(-3, 3):
			var cell := Vector2i(x, z)
			var rect := ChunkMath.cell_rect(cell, ChunkGenerator.CHUNK_SIZE)
			var roads := RoadNetwork.roads_touching_rect(SEED, rect)
			var pois := PoiGenerator.pois_in_rect(SEED, rect.grow(64.0))
			var data := ChunkGenerator.generate(SEED, cell)
			for k in data.props:
				for t: Transform3D in data.props[k]:
					var p := Vector2(t.origin.x, t.origin.z)
					assert_true(rect.has_point(p), "prop outside its chunk")
					for r in roads:
						assert_true(Geometry2DUtil.distance_to_segment(p, r[0], r[1]) > RoadNetwork.WIDTH * 0.5,
							"prop on road")
					for poi in pois:
						assert_true(p.distance_to(poi.position_2d()) > poi.plaza_radius, "prop on plaza")
					assert_true(p.length() > ChunkGenerator.SPAWN_CLEAR_RADIUS, "prop at spawn")


func test_road_mesh_matches_segments() -> void:
	var found := false
	for x in range(-4, 4):
		var data := ChunkGenerator.generate(SEED, Vector2i(x, 0))
		var verts := 0
		var tris := 0
		for seg in data.road_segments:
			var steps := maxi(1, ceili(seg[0].distance_to(seg[1]) / ChunkGenerator.ROAD_SAMPLE_STEP))
			verts += (steps + 1) * 2
			tris += steps * 2
		assert_eq(data.road_vertices.size(), verts)
		assert_eq(data.road_indices.size(), tris * 3)
		assert_eq(data.road_uvs.size(), data.road_vertices.size())
		assert_eq(data.road_uv2s.size(), data.road_vertices.size())
		assert_eq(data.road_ends.size(), data.road_segments.size())
		if not data.road_segments.is_empty():
			found = true
	assert_true(found, "expected some roads in a row of 8 chunks")


func test_pois_belong_to_one_chunk() -> void:
	var counts := {}
	for x in range(-6, 6):
		for z in range(-6, 6):
			for poi in ChunkGenerator.generate(SEED, Vector2i(x, z)).pois:
				counts[poi.id] = counts.get(poi.id, 0) + 1
	assert_true(counts.size() > 0)
	for id in counts:
		assert_eq(counts[id], 1, "poi %s" % id)


func test_props_and_pois_sit_on_terrain() -> void:
	var sampler := TerrainSampler.new(SEED)
	var defs := {}
	for def in BiomeMap.biome_at_cell(SEED, Vector2i.ZERO).props:
		defs[def.id] = def
	for x in range(-2, 2):
		var data := ChunkGenerator.generate(SEED, Vector2i(x, 1), sampler)
		for k in data.props:
			var sink: float = defs[k].get("sink", 0.0)
			for t: Transform3D in data.props[k]:
				var expected := sampler.height_at(t.origin.x, t.origin.z) - sink * t.basis.get_scale().x
				assert_near(t.origin.y, expected, 0.001, "prop height")
		for poi in data.pois:
			assert_near(poi.position.y, sampler.poi_height(poi), 0.001, "poi height")


func test_road_ribbon_hugs_terrain() -> void:
	var sampler := TerrainSampler.new(SEED)
	var checked := 0
	for x in range(-4, 4):
		var data := ChunkGenerator.generate(SEED, Vector2i(x, 0), sampler)
		for v in data.road_vertices:
			assert_near(v.y - sampler.height_at(v.x, v.z), ChunkGenerator.ROAD_HEIGHT, 0.001)
			checked += 1
	assert_true(checked > 0)


func test_no_props_on_cliff_faces() -> void:
	var sampler := TerrainSampler.new(SEED)
	for x in range(-6, 6):
		var data := ChunkGenerator.generate(SEED, Vector2i(x, -3), sampler)
		for k in data.props:
			for t: Transform3D in data.props[k]:
				assert_true(sampler.normal_at(t.origin.x, t.origin.z, 1.5).y >= ChunkGenerator.PROP_MIN_NORMAL_Y)


func test_every_prop_model_exists() -> void:
	for def in BiomeMap.biome_at_cell(SEED, Vector2i.ZERO).props:
		assert_true(ResourceLoader.exists(def.path), "missing prop model " + def.path)


func test_road_uv2_is_distance_to_nearest_road_end() -> void:
	var checked := 0
	for x in range(-4, 4):
		var data := ChunkGenerator.generate(SEED, Vector2i(x, 0))
		var vi := 0
		for s in data.road_segments.size():
			var seg := data.road_segments[s]
			var ends := data.road_ends[s]
			var steps := maxi(1, ceili(seg[0].distance_to(seg[1]) / ChunkGenerator.ROAD_SAMPLE_STEP))
			for i in steps + 1:
				var p := seg[0].lerp(seg[1], float(i) / steps)
				var expected := minf(p.distance_to(ends[0]), p.distance_to(ends[1]))
				assert_near(data.road_uv2s[vi].x, expected, 0.01)
				vi += 2
				checked += 1
	assert_true(checked > 10)
