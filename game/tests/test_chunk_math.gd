extends TestCase


func test_world_to_cell_positive_and_negative() -> void:
	assert_eq(ChunkMath.world_to_cell(Vector3(0, 0, 0), 128.0), Vector2i(0, 0))
	assert_eq(ChunkMath.world_to_cell(Vector3(127.9, 5, 128.0), 128.0), Vector2i(0, 1))
	assert_eq(ChunkMath.world_to_cell(Vector3(-0.1, 0, -128.0), 128.0), Vector2i(-1, -1))
	assert_eq(ChunkMath.world_to_cell(Vector3(-128.1, 0, 0), 128.0), Vector2i(-2, 0))


func test_cell_origin_and_rect() -> void:
	assert_eq(ChunkMath.cell_origin(Vector2i(-2, 3), 64.0), Vector3(-128, 0, 192))
	assert_eq(ChunkMath.cell_rect(Vector2i(1, -1), 10.0), Rect2(10, -10, 10, 10))


func test_cells_in_radius_count_and_order() -> void:
	var cells := ChunkMath.cells_in_radius(Vector2i(5, -3), 2)
	assert_eq(cells.size(), 25)
	assert_eq(cells[0], Vector2i(5, -3), "center first")
	var last_d := 0
	for c in cells:
		var d := (c - Vector2i(5, -3)).length_squared()
		assert_true(d >= last_d, "not sorted by distance")
		last_d = d
		assert_true(ChunkMath.chebyshev(c, Vector2i(5, -3)) <= 2)


func test_cells_overlapping() -> void:
	var cells := ChunkMath.cells_overlapping(Rect2(-10, -10, 20, 20), 100.0)
	assert_eq(cells.size(), 4)
	assert_true(cells.has(Vector2i(-1, -1)) and cells.has(Vector2i(0, 0)))
