extends TestCase

const SEED := 1337


func _biome() -> Biome:
	return BiomeMap.biome_at_cell(SEED, Vector2i.ZERO)


func _pois() -> Array[PoiData]:
	return PoiGenerator.pois_in_rect(SEED, Rect2(-2000, -2000, 4000, 4000))


func _plan(poi: PoiData, dirs: Array[Vector2] = []) -> Array[Dictionary]:
	return PoiPlanner.plan(SEED, poi, _biome().poi_layouts[poi.type_id], poi.ruin_chance, dirs)


func test_every_layout_piece_is_in_catalog() -> void:
	for type_id: String in _biome().poi_layouts:
		for layout: Array in _biome().poi_layouts[type_id]:
			for slot: Dictionary in layout:
				var keys: Array = [slot.m] if slot.m is String else slot.m
				for key: String in keys:
					assert_true(PoiCatalog.PIECES.has(key), "%s uses unknown piece %s" % [type_id, key])


func test_every_poi_type_has_layouts() -> void:
	for t in _biome().poi_types:
		assert_true(_biome().poi_layouts.has(t.id), "no layouts for " + t.id)


func test_plan_is_deterministic() -> void:
	for poi in _pois().slice(0, 20):
		assert_eq(_plan(poi), _plan(poi))


func test_pieces_stay_inside_plaza_and_off_centre() -> void:
	for poi in _pois():
		for item in _plan(poi):
			var d: float = (item.position as Vector2).distance_to(poi.position_2d())
			assert_true(d + PoiCatalog.radius(item.key) <= poi.plaza_radius + 4.0,
				"%s %s pokes out of the %s plaza (%.1f m)" % [poi.id, item.key, poi.type_id, d])
			assert_true(d - PoiCatalog.radius(item.key) > 2.0, "%s %s blocks the centre" % [poi.id, item.key])


func test_solid_pieces_do_not_overlap() -> void:
	# Footprints as circles of the smaller half-extent: tolerant of rotation, strict on real overlaps.
	for type_id: String in _biome().poi_layouts:
		for layout: Array in _biome().poi_layouts[type_id]:
			for i in layout.size():
				for j in range(i + 1, layout.size()):
					var a: Dictionary = layout[i]
					var b: Dictionary = layout[j]
					if a.get("y", 0.0) != b.get("y", 0.0) and a.get("y", 0.0) + b.get("y", 0.0) > 0.0:
						continue
					for ka: String in ([a.m] if a.m is String else a.m):
						for kb: String in ([b.m] if b.m is String else b.m):
							var pa := PoiCatalog.piece(ka)
							var pb := PoiCatalog.piece(kb)
							if not (pa.solid and pb.solid):
								continue
							var ra: float = minf(pa.size.x, pa.size.y) * 0.5
							var rb: float = minf(pb.size.x, pb.size.y) * 0.5
							var d: float = (a.p as Vector2).distance_to(b.p)
							assert_true(d >= ra + rb - 0.5, "%s: %s at %s overlaps %s at %s" % [type_id, ka, a.p, kb, b.p])


func test_road_lanes_are_kept_clear() -> void:
	var dirs: Array[Vector2] = [Vector2(1, 0), Vector2(0, -1).rotated(0.4)]
	var checked := 0
	for poi in _pois().slice(0, 40):
		for item in _plan(poi, dirs):
			assert_false(PoiPlanner.in_road_lane(item.position, PoiCatalog.radius(item.key), poi.position_2d(), dirs, poi.plaza_radius),
				"%s %s sits in a road lane" % [poi.id, item.key])
			checked += 1
	assert_true(checked > 100)


func test_some_buildings_are_ruined_with_rubble() -> void:
	var ruined := 0
	var rubble := 0
	for poi in _pois():
		for item in _plan(poi):
			if item.ruin > 0.0:
				ruined += 1
				assert_true(PoiCatalog.piece(item.key).ruinable)
				assert_true(item.ruin >= PoiPlanner.RUIN_KEEP.x and item.ruin <= PoiPlanner.RUIN_KEEP.y)
			if PoiCatalog.RUBBLE.has(item.key):
				rubble += 1
	assert_true(ruined > 20, "only %d ruined buildings" % ruined)
	assert_true(rubble > ruined, "rubble %d vs ruined %d" % [rubble, ruined])


func test_road_directions_found_for_connected_pois() -> void:
	var sampler := TerrainSampler.new(SEED)
	var with_roads := 0
	for poi in _pois().slice(0, 30):
		var cell := ChunkMath.world_to_cell(poi.position, ChunkGenerator.CHUNK_SIZE)
		var dirs := PoiPlanner.road_directions(poi, sampler.influences_for_cell(cell).roads)
		for d in dirs:
			assert_near(d.length(), 1.0, 0.001)
		if not dirs.is_empty():
			with_roads += 1
	assert_true(with_roads > 20, "only %d POIs found their roads" % with_roads)


func test_catalog_sizes_match_models() -> void:
	var lib := PoiPieceLibrary.new()
	for key: String in PoiCatalog.PIECES:
		var piece := PoiCatalog.piece(key)
		assert_true(ResourceLoader.exists(piece.path), "missing " + piece.path)
		var aabb: AABB = lib.get_info(key).aabb
		var real: Vector2 = Vector2(aabb.size.x, aabb.size.z) * piece.scale
		var listed: Vector2 = piece.size
		assert_near(real.x, listed.x, maxf(0.6, listed.x * 0.1), key + " width")
		assert_near(real.y, listed.y, maxf(0.6, listed.y * 0.1), key + " depth")


func test_poi_site_builds_pieces_and_colliders() -> void:
	var lib := PoiPieceLibrary.new()
	var sampler := TerrainSampler.new(SEED)
	var built := 0
	for x in range(-6, 6):
		for z in range(-6, 6):
			for poi in ChunkGenerator.generate(SEED, Vector2i(x, z), sampler).pois:
				var site := PoiSite.create(poi, lib)
				var solids := poi.layout.filter(func(i: Dictionary) -> bool: return PoiCatalog.piece(i.key).solid).size()
				var shapes := site.find_children("*", "CollisionShape3D", true, false)
				assert_eq(shapes.size(), solids, poi.id + " colliders")
				assert_false(site.find_children("*", "MeshInstance3D", true, false).is_empty(), poi.id + " has no meshes")
				for mi: MeshInstance3D in site.find_children("*", "MeshInstance3D", true, false):
					assert_true(mi.get_surface_override_material(0) is ShaderMaterial, "piece not weathered")
				site.free()
				built += 1
	assert_true(built > 3, "only built %d sites" % built)
