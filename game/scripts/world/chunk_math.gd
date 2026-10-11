class_name ChunkMath
extends RefCounted


static func world_to_cell(pos: Vector3, cell_size: float) -> Vector2i:
	return Vector2i(floori(pos.x / cell_size), floori(pos.z / cell_size))


static func cell_origin(cell: Vector2i, cell_size: float) -> Vector3:
	return Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)


static func cell_rect(cell: Vector2i, cell_size: float) -> Rect2:
	return Rect2(cell.x * cell_size, cell.y * cell_size, cell_size, cell_size)


static func chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Nearest cells first so streaming fills in from the player outwards.
static func cells_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for z in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			cells.append(center + Vector2i(x, z))
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a - center).length_squared() < (b - center).length_squared())
	return cells


## Cells of size `cell_size` overlapping `rect` (in x/z world units).
static func cells_overlapping(rect: Rect2, cell_size: float) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var min_c := Vector2i(floori(rect.position.x / cell_size), floori(rect.position.y / cell_size))
	var max_c := Vector2i(floori(rect.end.x / cell_size), floori(rect.end.y / cell_size))
	for z in range(min_c.y, max_c.y + 1):
		for x in range(min_c.x, max_c.x + 1):
			cells.append(Vector2i(x, z))
	return cells
