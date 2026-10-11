extends TestCase

const SEED := 1337


func test_deterministic() -> void:
	for x in range(-3, 4):
		for z in range(-3, 4):
			var a := PoiGenerator.poi_for_cell(SEED, Vector2i(x, z))
			var b := PoiGenerator.poi_for_cell(SEED, Vector2i(x, z))
			assert_eq(a == null, b == null)
			if a != null:
				assert_eq(a.position, b.position)
				assert_eq(a.display_name, b.display_name)
				assert_eq(a.model_path, b.model_path)


func test_different_seed_changes_world() -> void:
	var same := 0
	for x in 10:
		var a := PoiGenerator.poi_for_cell(1, Vector2i(x, 0))
		var b := PoiGenerator.poi_for_cell(2, Vector2i(x, 0))
		if (a == null and b == null) or (a != null and b != null and a.position == b.position):
			same += 1
	assert_true(same < 10)


func test_poi_inside_own_cell_with_margin() -> void:
	var count := 0
	for x in range(-10, 10):
		for z in range(-10, 10):
			var poi := PoiGenerator.poi_for_cell(SEED, Vector2i(x, z))
			if poi == null:
				continue
			count += 1
			var rect := ChunkMath.cell_rect(Vector2i(x, z), PoiGenerator.CELL_SIZE).grow(-PoiGenerator.EDGE_MARGIN)
			assert_true(rect.has_point(poi.position_2d()), "poi %s outside margin" % poi.id)
			assert_eq(poi.id, "%d_%d" % [x, z])
			assert_true(poi.display_name.ends_with(poi.type_label))
			assert_true(ResourceLoader.exists(poi.model_path), "missing model " + poi.model_path)
	# 400 cells at 60% chance: wildly unlikely to fall outside this band.
	assert_true(count > 180 and count < 300, "unexpected poi count %d" % count)


func test_spawn_origin_clear_of_pois() -> void:
	for poi in PoiGenerator.nearest(SEED, Vector3.ZERO, 4):
		assert_true(poi.position_2d().length() >= PoiGenerator.EDGE_MARGIN * sqrt(2.0) - 0.01)


func test_nearest_matches_brute_force() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 20:
		var pos := Vector3(rng.randf_range(-3000, 3000), 0, rng.randf_range(-3000, 3000))
		var got := PoiGenerator.nearest(SEED, pos, 3)
		var all := PoiGenerator.pois_in_rect(SEED, Rect2(pos.x - 1500, pos.z - 1500, 3000, 3000))
		var p := Vector2(pos.x, pos.z)
		all.sort_custom(func(a: PoiData, b: PoiData) -> bool:
			return a.position_2d().distance_to(p) < b.position_2d().distance_to(p))
		assert_eq(got.size(), 3)
		for k in 3:
			assert_eq(got[k].id, all[k].id, "query %d rank %d" % [i, k])


func test_pois_in_rect_only_returns_contained() -> void:
	var rect := Rect2(-300, -300, 600, 600)
	for poi in PoiGenerator.pois_in_rect(SEED, rect):
		assert_true(rect.has_point(poi.position_2d()))


func test_interactable_only_near_plaza() -> void:
	var poi := PoiGenerator.nearest(SEED, Vector3(500, 0, 500), 1)[0]
	var reach := poi.plaza_radius + PoiGenerator.INTERACT_MARGIN
	assert_eq(PoiGenerator.interactable(SEED, poi.position + Vector3(reach - 1.0, 0, 0)).id, poi.id)
	assert_eq(PoiGenerator.interactable(SEED, poi.position + Vector3(reach + 1.0, 0, 0)), null)
	assert_eq(PoiGenerator.interactable(SEED, Vector3.ZERO), null, "spawn is not inside a POI")
