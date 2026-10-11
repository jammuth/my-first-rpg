extends TestCase

const BakePlants := preload("res://tools/bake_plants.gd")
const MAX_TRIS := 5000


func _baked_paths() -> Array[String]:
	var paths: Array[String] = []
	for scan: Dictionary in BakePlants.SCANS:
		for letter: String in scan.nodes:
			paths.append(BakePlants.OUT_DIR + "%s_%s.res" % [scan.id, letter])
	for id: String in BakePlants.CACTI:
		paths.append(BakePlants.OUT_DIR + "cactus_" + id + ".res")
	return paths


func test_baked_plants_within_budget_and_textured() -> void:
	for path in _baked_paths():
		var mesh: Mesh = load(path)
		assert_not_null(mesh, "not baked: " + path)
		if mesh == null:
			continue
		var tris := mesh.get_faces().size() / 3
		assert_true(tris <= MAX_TRIS, "%s has %d tris" % [path, tris])
		assert_not_null(mesh.surface_get_material(0), path + " missing material")


func test_cacti_upright_and_grounded() -> void:
	for id: String in BakePlants.CACTI:
		var aabb: AABB = (load(BakePlants.OUT_DIR + "cactus_" + id + ".res") as Mesh).get_aabb()
		assert_true(aabb.size.y > aabb.size.x and aabb.size.y > aabb.size.z, "cactus_%s not upright: %s" % [id, aabb])
		assert_near(aabb.position.y, 0.0, 0.05, "cactus_%s base" % id)
		assert_near(aabb.get_center().x, 0.0, 0.05, "cactus_%s centred" % id)
