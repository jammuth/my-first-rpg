extends TestCase

const SEED := 1337


func test_height_deterministic_across_instances() -> void:
	var a := TerrainSampler.new(SEED)
	var b := TerrainSampler.new(SEED)
	for i in 50:
		var x := i * 37.3 - 900.0
		var z := i * -21.7 + 400.0
		assert_eq(a.height_at(x, z), b.height_at(x, z))


func test_seed_changes_terrain() -> void:
	var a := TerrainSampler.new(1)
	var b := TerrainSampler.new(2)
	var differ := 0
	for i in 20:
		if not is_equal_approx(a.base_height(i * 50.0, 0), b.base_height(i * 50.0, 0)):
			differ += 1
	assert_true(differ > 15)


func test_terrain_is_gentle_but_varied() -> void:
	var s := TerrainSampler.new(SEED)
	var lo := INF
	var hi := -INF
	var max_slope := 0.0
	for i in 400:
		var x := (i % 20) * 97.0 - 1000.0
		var z := (i / 20) * 97.0 - 1000.0
		var h := s.base_height(x, z)
		lo = minf(lo, h)
		hi = maxf(hi, h)
		max_slope = maxf(max_slope, absf(s.base_height(x + 1.0, z) - h))
	assert_true(hi - lo > 15.0, "relief only %.1fm" % (hi - lo))
	assert_true(max_slope < 0.6, "natural slope too steep: %.2f" % max_slope)


func test_plazas_are_flat_at_poi_height() -> void:
	var s := TerrainSampler.new(SEED)
	var count := 0
	for poi in PoiGenerator.pois_in_rect(SEED, Rect2(-1500, -1500, 3000, 3000)):
		var h := s.poi_height(poi)
		for k in 8:
			var r := poi.plaza_radius * 0.95
			var p := poi.position_2d() + Vector2.from_angle(k * TAU / 8.0) * r
			assert_near(s.height_at(p.x, p.y), h, 0.02, "plaza %s not flat" % poi.id)
		count += 1
	assert_true(count > 50)


func test_road_centre_follows_profile() -> void:
	var s := TerrainSampler.new(SEED)
	var checked := 0
	for cell in ChunkMath.cells_in_radius(Vector2i.ZERO, 3):
		for road in s.influences_for_cell(cell).roads:
			var a: Vector2 = road.a
			var b: Vector2 = road.b
			var len := a.distance_to(b)
			# Away from the plaza blend rings at each end, the road surface is the pure profile.
			for t in [0.4, 0.5, 0.6]:
				var p := a.lerp(b, t)
				if p.distance_to(a) < road.ra + TerrainSampler.POI_BLEND or p.distance_to(b) < road.rb + TerrainSampler.POI_BLEND:
					continue
				var near_other := false
				for e in s.influences_for_cell(cell).pois:
					if p.distance_to(e.poi.position_2d()) < e.poi.plaza_radius + TerrainSampler.POI_BLEND:
						near_other = true
				if near_other or len < 1.0:
					continue
				var expected := TerrainSampler.road_height(road, p)
				var got := s.height_at(p.x, p.y)
				# Another road can overlap near junction-free crossings; only check clean stretches.
				if absf(got - expected) < 0.05:
					checked += 1
				else:
					var others := 0
					for r2 in s.influences_for_cell(cell).roads:
						if Geometry2DUtil.distance_to_segment(p, r2.a, r2.b) < 40.0:
							others += 1
					assert_true(others > 1, "road surface off profile by %.2f" % (got - expected))
	assert_true(checked > 10, "only %d road samples checked" % checked)


func test_road_height_holds_across_plazas() -> void:
	var road := {"a": Vector2(0, 0), "b": Vector2(100, 0), "ha": 5.0, "hb": 15.0, "ra": 20.0, "rb": 10.0}
	assert_near(TerrainSampler.road_height(road, Vector2(10, 3)), 5.0)
	assert_near(TerrainSampler.road_height(road, Vector2(95, -2)), 15.0)
	assert_near(TerrainSampler.road_height(road, Vector2(55, 0)), 10.0)


func test_heights_continuous_across_chunk_seam() -> void:
	var s := TerrainSampler.new(SEED)
	var size := ChunkGenerator.CHUNK_SIZE
	for i in 64:
		var z := 300.0 + i * 2.0
		var left := s.height_at(size * 3 - 0.001, z)
		var right := s.height_at(size * 3 + 0.001, z)
		assert_near(left, right, 0.01, "step at seam z=%.0f" % z)


func test_mesh_seams_match_between_neighbours() -> void:
	var s := TerrainSampler.new(SEED)
	var a := TerrainMesher.build(s, Vector2i(2, 1), 0)
	var b := TerrainMesher.build(s, Vector2i(3, 1), 0)
	var side := int(ChunkGenerator.CHUNK_SIZE / TerrainMesher.LOD_STEPS[0]) + 1
	for z in side:
		var ia := z * side + side - 1
		var ib := z * side
		assert_true(a.vertices[ia].is_equal_approx(b.vertices[ib]), "vertex mismatch row %d" % z)
		assert_true(a.normals[ia].is_equal_approx(b.normals[ib]), "normal mismatch row %d" % z)


func test_lods_share_corner_heights() -> void:
	var s := TerrainSampler.new(SEED)
	var fine := TerrainMesher.build(s, Vector2i(-1, 2), 0)
	var coarse := TerrainMesher.build(s, Vector2i(-1, 2), 2)
	var lookup := {}
	var fine_side := int(ChunkGenerator.CHUNK_SIZE / TerrainMesher.LOD_STEPS[0]) + 1
	for i in fine_side * fine_side:
		var v := fine.vertices[i]
		lookup[Vector2(v.x, v.z)] = v.y
	var coarse_side := int(ChunkGenerator.CHUNK_SIZE / TerrainMesher.LOD_STEPS[2]) + 1
	for i in coarse_side * coarse_side:
		var v := coarse.vertices[i]
		assert_near(lookup[Vector2(v.x, v.z)], v.y, 0.0001)


func test_mesh_sizes_per_lod() -> void:
	var s := TerrainSampler.new(SEED)
	for lod in TerrainMesher.LOD_STEPS.size():
		var n := int(ChunkGenerator.CHUNK_SIZE / TerrainMesher.LOD_STEPS[lod])
		var m := TerrainMesher.build(s, Vector2i(0, 0), lod)
		var side := n + 1
		assert_eq(m.vertices.size(), side * side + 4 * side, "lod %d verts" % lod)
		assert_eq(m.indices.size(), n * n * 6 + 4 * n * 6, "lod %d indices" % lod)
		assert_eq(m.normals.size(), m.vertices.size())


func test_lod_rings() -> void:
	assert_eq(TerrainMesher.lod_for_ring(0), 0)
	assert_eq(TerrainMesher.lod_for_ring(1), 0)
	assert_eq(TerrainMesher.lod_for_ring(2), 1)
	assert_eq(TerrainMesher.lod_for_ring(4), 2)


func test_skirt_covers_lod_height_error() -> void:
	var s := TerrainSampler.new(SEED)
	var worst := 0.0
	for cell in [Vector2i(0, 0), Vector2i(5, -3), Vector2i(-7, 2)]:
		var coarse := TerrainMesher.build(s, cell, 2)
		var step: float = TerrainMesher.LOD_STEPS[2]
		var side := int(ChunkGenerator.CHUNK_SIZE / step) + 1
		# Compare the coarse edge (linear between samples) against the true surface at fine spacing.
		for k in side - 1:
			var p0 := coarse.vertices[k]
			var p1 := coarse.vertices[k + 1]
			for j in 4:
				var q := p0.lerp(p1, j / 4.0)
				worst = maxf(worst, absf(q.y - s.height_at(q.x, q.z)))
	assert_true(worst < TerrainMesher.SKIRT_DEPTH, "LOD error %.2f exceeds skirt" % worst)


func test_mesas_exist_with_reasonable_coverage() -> void:
	var s := TerrainSampler.new(SEED)
	var on_mesa := 0
	var total := 0
	for i in 60:
		for j in 60:
			var x := i * 50.0 - 1500.0
			var z := j * 50.0 - 1500.0
			var cell := Vector2i(floori(x / ChunkGenerator.CHUNK_SIZE), floori(z / ChunkGenerator.CHUNK_SIZE))
			if s.mesa_height(Vector2(x, z), s.influences_for_cell(cell)) > 1.0:
				on_mesa += 1
			total += 1
	var frac := float(on_mesa) / total
	assert_true(frac > 0.02 and frac < 0.3, "mesa coverage %.3f" % frac)


func test_cliffs_are_steep() -> void:
	var s := TerrainSampler.new(SEED)
	var steepest := 0.0
	for i in 400:
		for j in 40:
			var x := i * 6.0 - 1200.0
			var z := j * 60.0 - 1200.0
			steepest = maxf(steepest, absf(s.height_at(x + 2.0, z) - s.height_at(x, z)) / 2.0)
	assert_true(steepest > 1.2, "no cliff found; steepest grade %.2f" % steepest)


func test_no_mesas_near_roads_or_plazas_or_spawn() -> void:
	var s := TerrainSampler.new(SEED)
	assert_eq(s.mesa_height(Vector2.ZERO, s.influences_for_cell(Vector2i.ZERO)), 0.0, "spawn")
	var checked := 0
	for cell in ChunkMath.cells_in_radius(Vector2i(2, 2), 4):
		var inf := s.influences_for_cell(cell)
		var rect := ChunkMath.cell_rect(cell, ChunkGenerator.CHUNK_SIZE)
		for road in inf.roads:
			for t in 11:
				var p: Vector2 = road.a.lerp(road.b, t / 10.0)
				var d: Vector2 = (road.b - road.a).normalized().orthogonal()
				for off in [-35.0, 0.0, 35.0]:
					var q: Vector2 = p + d * off
					if rect.has_point(q):
						assert_eq(s.mesa_height(q, inf), 0.0, "mesa within road corridor")
						checked += 1
		for e in inf.pois:
			var poi: PoiData = e.poi
			if rect.has_point(poi.position_2d()):
				assert_eq(s.mesa_height(poi.position_2d(), inf), 0.0, "mesa at POI")
	assert_true(checked > 20)


func test_spawn_is_drivable() -> void:
	var s := TerrainSampler.new(SEED)
	for k in 16:
		var p := Vector2.from_angle(k * TAU / 16.0) * 20.0
		assert_false(TruckMotion.blocked_by_slope(s.height_at(0, 0), s.height_at(p.x, p.y), 20.0, 0.9))
