extends TestCase

const BakeRocks := preload("res://tools/bake_rocks.gd")


func test_baked_rocks_within_budget() -> void:
	for n in BakeRocks.SOURCES:
		var mesh: Mesh = load("res://assets/models/rocks/boulder_%s.res" % n)
		assert_not_null(mesh, "boulder %s not baked" % n)
		if mesh == null:
			continue
		var tris := mesh.get_faces().size() / 3
		assert_true(tris <= BakeRocks.TARGET_TRIS * 2, "boulder %s has %d tris" % [n, tris])
		var arrays := mesh.surface_get_arrays(0)
		assert_true(arrays[Mesh.ARRAY_TANGENT] != null, "boulder %s missing tangents" % n)


func test_build_compact_drops_unused_vertices() -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(9, 9, 9)])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)])
	var mesh := BakeRocks.build_compact(arrays, PackedInt32Array([0, 2, 1]))
	var out := mesh.surface_get_arrays(0)
	assert_eq((out[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), 3)
	assert_false((out[Mesh.ARRAY_VERTEX] as PackedVector3Array).has(Vector3(9, 9, 9)), "unused vertex kept")
