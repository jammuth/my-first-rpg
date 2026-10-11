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
		assert_eq(data.road_vertices.size(), data.road_segments.size() * 4)
		assert_eq(data.road_indices.size(), data.road_segments.size() * 6)
		assert_eq(data.road_uvs.size(), data.road_vertices.size())
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
