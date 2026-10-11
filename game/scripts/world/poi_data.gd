class_name PoiData
extends RefCounted

var id: String
var cell: Vector2i
var position: Vector3
var yaw: float
var type_id: String
var type_label: String
var display_name: String
var model_path: String
var model_scale: float
var plaza_radius: float


func position_2d() -> Vector2:
	return Vector2(position.x, position.z)
