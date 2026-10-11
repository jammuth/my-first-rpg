class_name PoiData
extends RefCounted

var id: String
var cell: Vector2i
var position: Vector3
var yaw: float
var type_id: String
var type_label: String
var display_name: String
var plaza_radius: float
var ruin_chance: float
## Filled in by ChunkGenerator via PoiPlanner.plan (see there for the item format).
var layout: Array[Dictionary] = []


func position_2d() -> Vector2:
	return Vector2(position.x, position.z)
