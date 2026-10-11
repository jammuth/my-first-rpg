extends TestCase

const SEED := 1337
const TruckScene := preload("res://scenes/truck.tscn")


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _first_site_with_solid() -> Array:
	var sampler := TerrainSampler.new(SEED)
	var lib := PoiPieceLibrary.new()
	for cell in ChunkMath.cells_in_radius(Vector2i.ZERO, 6):
		for poi in ChunkGenerator.generate(SEED, cell, sampler).pois:
			for item: Dictionary in poi.layout:
				var piece := PoiCatalog.piece(item.key)
				if piece.solid and item.ruin == 0.0 and item.y == 0.0 and piece.size.x > 5.0:
					return [PoiSite.create(poi, lib), poi, item]
	return []


func test_truck_is_blocked_by_poi_buildings() -> void:
	var found := _first_site_with_solid()
	assert_false(found.is_empty(), "no solid POI piece found")
	if found.is_empty():
		return
	var site: PoiSite = found[0]
	var poi: PoiData = found[1]
	var item: Dictionary = found[2]
	_tree().root.add_child(site)
	var truck: CharacterBody3D = TruckScene.instantiate()
	truck.set_physics_process(false)
	_tree().root.add_child(truck)
	var target: Vector2 = item.position
	var start := target + (target - poi.position_2d()).normalized() * 25.0
	truck.global_position = Vector3(start.x, poi.position.y, start.y)
	truck.look_at(Vector3(target.x, poi.position.y, target.y), Vector3.UP)
	var toward := Vector3(target.x - start.x, 0.0, target.y - start.y)
	assert_true(truck.test_move(truck.global_transform, toward), "drove through %s at %s" % [item.key, poi.id])
	var away := -toward.normalized() * 5.0
	assert_false(truck.test_move(truck.global_transform, away), "blocked driving away from %s" % item.key)
	truck.free()
	site.free()
