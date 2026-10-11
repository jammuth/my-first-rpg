extends TestCase

const SEED := 1337

static var _sample: Array[PoiData] = []


## Real POIs (with planned layouts) near the world origin, shared across tests because generating
## them is the slow part.
func _pois() -> Array[PoiData]:
	if _sample.is_empty():
		for poi in PoiGenerator.pois_in_rect(SEED, Rect2(-1024, -1024, 2048, 2048)):
			var planned := ExplorationLevel.poi_with_layout(SEED, poi.id)
			if planned != null:
				_sample.append(planned)
	return _sample


## Parks the truck the way the game does without a usable parked position: plaza edge, facing in.
func _park(poi: PoiData) -> Array:
	return ExplorationLevel.parking(poi, null, 0.0)


func _level(poi: PoiData) -> ExplorationLevel:
	var park := _park(poi)
	return ExplorationLevel.build(SEED, poi, park[0], park[1])


func test_sample_covers_every_poi_type() -> void:
	var types := {}
	for poi in _pois():
		types[poi.type_id] = true
	assert_true(_pois().size() >= 20, "only %d POIs in sample" % _pois().size())
	for type_id: String in ExplorationLevel.LOOT_ROOMS:
		assert_true(types.has(type_id), "no %s in sample" % type_id)


func test_poi_with_layout_matches_the_overworld_plan() -> void:
	var poi := _pois()[0]
	var chunk := ChunkMath.world_to_cell(poi.position, ChunkGenerator.CHUNK_SIZE)
	var from_chunk: PoiData
	for p in ChunkGenerator.generate(SEED, chunk).pois:
		if p.id == poi.id:
			from_chunk = p
	assert_not_null(from_chunk)
	assert_eq(poi.layout, from_chunk.layout)
	assert_near(poi.position.y, from_chunk.position.y)


func test_parked_truck_faces_the_site() -> void:
	var poi := _pois()[0]
	var park := _park(poi)
	var forward := Vector2(-sin(park[1]), -cos(park[1]))
	assert_near(forward.dot((poi.position_2d() - park[0]).normalized()), 1.0, 0.001)


func test_parking_keeps_a_plausible_spot_and_replaces_a_far_one() -> void:
	var poi := _pois()[0]
	var near := poi.position_2d() + Vector2(poi.plaza_radius + 5.0, 0)
	assert_eq(ExplorationLevel.parking(poi, near, 1.0), [near, 1.0])
	var far: Array = ExplorationLevel.parking(poi, poi.position_2d() + Vector2(900, 0), 1.0)
	assert_true((far[0] as Vector2).distance_to(poi.position_2d()) < poi.plaza_radius + 10.0)
	assert_false(ExplorationLevel.blocked(far[0], ExplorationLevel.footprints_of(poi.layout), 3.0))


func test_build_is_deterministic() -> void:
	for poi in _pois().slice(0, 6):
		var a := _level(poi)
		var b := _level(poi)
		assert_eq(a.spawn, b.spawn)
		assert_eq(a.containers, b.containers)
		assert_eq(a.loot_rooms, b.loot_rooms)


func test_spawn_is_clear_inside_bounds_and_near_the_truck() -> void:
	for poi in _pois():
		var level := _level(poi)
		assert_false(ExplorationLevel.blocked(level.spawn, level.footprints, ExplorationLevel.BODY_RADIUS), "%s spawn blocked" % poi.id)
		assert_true(level.inside_boundary(level.spawn), poi.id)
		assert_true(level.inside_boundary(level.truck_position), "%s truck outside boundary" % poi.id)
		assert_true(level.spawn.distance_to(level.truck_position) < 8.0, poi.id)
		assert_true(level.in_extraction_zone(level.spawn), "%s starts away from the truck" % poi.id)


func test_spots_are_reachable_and_outside_buildings() -> void:
	for poi in _pois():
		var level := _level(poi)
		var reachable := level.reachable_grid()
		assert_true(reachable.size() > 500, "%s: only %d walkable cells" % [poi.id, reachable.size()])
		for c in level.containers:
			assert_true(level.can_reach(c.position, c.reach, reachable), "%s %s unreachable" % [poi.id, c.id])
		for d in level.loot_rooms:
			assert_true(level.can_reach(d.position, ExplorationLevel.REACH, reachable), "%s %s unreachable" % [poi.id, d.id])
			assert_false(ExplorationLevel.blocked(d.position, level.footprints, 0.0), "%s door inside a building" % poi.id)
			var out: Vector2 = d.position - d.building
			assert_true(out.dot(d.normal) > 0.0, "%s door normal points inward" % poi.id)


func test_most_pois_get_their_loot_rooms_and_search_spots() -> void:
	var full := 0
	var with_containers := 0
	for poi in _pois():
		var level := _level(poi)
		if level.loot_rooms.size() == ExplorationLevel.LOOT_ROOMS[poi.type_id]:
			full += 1
		if not level.containers.is_empty():
			with_containers += 1
	var n := _pois().size()
	assert_true(full >= n * 0.8, "only %d/%d POIs got all their loot rooms" % [full, n])
	assert_true(with_containers >= n * 0.8, "only %d/%d POIs have search spots" % [with_containers, n])


func test_ids_are_unique_and_stable_layout_indices() -> void:
	var level := _level(_pois()[1])
	var ids := {}
	for c in level.containers:
		assert_false(ids.has(c.id))
		ids[c.id] = true
		var index := int((c.id as String).substr(1))
		assert_eq(level.poi.layout[index].key, c.key)
	for d in level.loot_rooms:
		assert_false(ids.has(d.id))
		ids[d.id] = true


func test_blocked_respects_rotation() -> void:
	var fp: Array[Dictionary] = [{"center": Vector2(10, 10), "half": Vector2(4, 1), "yaw": PI * 0.5}]
	# Rotated a quarter turn, the long side runs along z.
	assert_true(ExplorationLevel.blocked(Vector2(10, 13.5), fp, 0.0))
	assert_false(ExplorationLevel.blocked(Vector2(13.5, 10), fp, 0.0))
	assert_true(ExplorationLevel.blocked(Vector2(11.4, 10), fp, 0.5), "radius widens the footprint")


func test_boundary_clamp() -> void:
	var level := _level(_pois()[0])
	var far := level.boundary_center + Vector2(level.boundary_radius * 3.0, 0)
	var clamped := level.clamp_to_boundary(far)
	assert_near(clamped.distance_to(level.boundary_center), level.boundary_radius, 0.001)
	assert_eq(level.clamp_to_boundary(level.spawn), level.spawn)
