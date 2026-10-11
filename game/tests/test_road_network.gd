extends TestCase

const SEED := 1337


func _all_roads(radius: int) -> Array[PackedVector2Array]:
	var roads: Array[PackedVector2Array] = []
	for x in range(-radius, radius + 1):
		for z in range(-radius, radius + 1):
			roads.append_array(RoadNetwork.roads_owned_by_cell(SEED, Vector2i(x, z)))
	return roads


func test_roads_connect_existing_pois() -> void:
	var positions := {}
	for x in range(-9, 10):
		for z in range(-9, 10):
			var poi := PoiGenerator.poi_for_cell(SEED, Vector2i(x, z))
			if poi != null:
				positions[poi.position_2d()] = true
	var roads := _all_roads(8)
	assert_true(roads.size() > 50)
	for r in roads:
		assert_true(positions.has(r[0]) and positions.has(r[1]), "road endpoint is not a POI")


func test_no_duplicate_roads() -> void:
	var seen := {}
	for r in _all_roads(8):
		var key := [r[0], r[1]] if r[0] < r[1] else [r[1], r[0]]
		assert_false(seen.has(key), "duplicate road")
		seen[key] = true


func test_roads_do_not_cross() -> void:
	var roads := _all_roads(6)
	for i in roads.size():
		for j in range(i + 1, roads.size()):
			var a := roads[i]
			var b := roads[j]
			if a[0] == b[0] or a[0] == b[1] or a[1] == b[0] or a[1] == b[1]:
				continue
			assert_true(Geometry2D.segment_intersects_segment(a[0], a[1], b[0], b[1]) == null,
				"roads %s and %s cross" % [a, b])


func test_most_pois_are_connected() -> void:
	var degree := {}
	for r in _all_roads(10):
		degree[r[0]] = degree.get(r[0], 0) + 1
		degree[r[1]] = degree.get(r[1], 0) + 1
	var total := 0
	var isolated := 0
	for x in range(-8, 9):
		for z in range(-8, 9):
			var poi := PoiGenerator.poi_for_cell(SEED, Vector2i(x, z))
			if poi == null:
				continue
			total += 1
			if not degree.has(poi.position_2d()):
				isolated += 1
	assert_true(isolated * 50 < total, "%d of %d POIs have no road" % [isolated, total])


func test_roads_touching_rect_finds_every_crossing_road() -> void:
	var rect := Rect2(-200, 100, 128, 128)
	var expected := 0
	for r in _all_roads(4):
		if not Geometry2DUtil.clip_segment_to_rect(r[0], r[1], rect).is_empty():
			expected += 1
	var got := RoadNetwork.roads_touching_rect(SEED, rect)
	var hits := 0
	for r in got:
		if not Geometry2DUtil.clip_segment_to_rect(r[0], r[1], rect).is_empty():
			hits += 1
	assert_eq(hits, expected)
