class_name FollowCamera
extends Camera3D

@export var target_path: NodePath
@export var distance := 36.0
@export_range(20.0, 80.0) var pitch_degrees := 45.0
@export var look_height := 2.0
## Higher = camera swings round to the truck's heading faster.
@export var yaw_sharpness := 4.0

var _target: Node3D
var _yaw := 0.0


static func offset_for(yaw: float, pitch_radians: float, dist: float) -> Vector3:
	var local := Vector3(0.0, sin(pitch_radians), cos(pitch_radians)) * dist
	return Basis(Vector3.UP, yaw) * local


func _ready() -> void:
	_target = get_node(target_path)
	# Driven from _process with the target's interpolated transform, so skip engine interpolation here.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_yaw = _target.global_rotation.y
	_place(_target.global_transform)


func _process(delta: float) -> void:
	var t := _target.get_global_transform_interpolated()
	_yaw = lerp_angle(_yaw, t.basis.get_euler().y, 1.0 - exp(-yaw_sharpness * delta))
	_place(t)


func _place(t: Transform3D) -> void:
	var focus := t.origin + Vector3.UP * look_height
	global_position = focus + offset_for(_yaw, deg_to_rad(pitch_degrees), distance)
	look_at(focus, Vector3.UP)
