class_name ChaseCamera
extends Node3D

## Third-person camera on a spring arm, so walls pull it in instead of clipping. Centred by default;
## toggle_shoulder shifts the view over the shoulder.

@export var target_path: NodePath
@export var height := 1.6
@export var distance := 4.8
@export var shoulder_offset := 0.8
@export_range(-80.0, 0.0) var default_pitch_degrees := -16.0
@export_range(-89.0, 0.0) var min_pitch_degrees := -60.0
@export_range(-30.0, 60.0) var max_pitch_degrees := 25.0
## Radians per pixel of mouse movement while the mouse is captured.
@export var mouse_sensitivity := 0.0035
## Radians per second at full right-stick deflection.
@export var stick_speed := 2.6

var shoulder := false
## x = yaw, y = pitch (radians).
var look := Vector2.ZERO

var _target: Node3D
var _arm: SpringArm3D
var _camera: Camera3D


## Applies a look input: yaw wraps, pitch stays within limits.
static func apply_look(current: Vector2, delta_radians: Vector2, min_pitch: float, max_pitch: float) -> Vector2:
	return Vector2(wrapf(current.x + delta_radians.x, -PI, PI),
		clampf(current.y + delta_radians.y, min_pitch, max_pitch))


func _ready() -> void:
	_target = get_node(target_path)
	top_level = true
	# Driven from _process with the target's interpolated transform, so skip engine interpolation here.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_arm = SpringArm3D.new()
	_arm.spring_length = distance
	_arm.margin = 0.2
	var probe := SphereShape3D.new()
	probe.radius = 0.25
	_arm.shape = probe
	if _target is CollisionObject3D:
		_arm.add_excluded_object((_target as CollisionObject3D).get_rid())
	add_child(_arm)
	_camera = Camera3D.new()
	_camera.fov = 60.0
	_camera.position.z = distance
	_arm.add_child(_camera)
	_camera.make_current()
	look.y = deg_to_rad(default_pitch_degrees)
	_place()


func set_yaw(yaw: float) -> void:
	look.x = yaw
	_place()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_turn(Vector2(-event.relative.x, -event.relative.y) * mouse_sensitivity)
	elif event.is_action_pressed("toggle_shoulder"):
		shoulder = not shoulder


func _process(delta: float) -> void:
	var stick := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if stick != Vector2.ZERO:
		_turn(Vector2(-stick.x, -stick.y) * stick_speed * delta)
	_camera.h_offset = shoulder_offset if shoulder else 0.0
	_place()


func _turn(delta_radians: Vector2) -> void:
	look = apply_look(look, delta_radians, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))


func _place() -> void:
	global_position = _target.get_global_transform_interpolated().origin + Vector3.UP * height
	rotation = Vector3(look.y, look.x, 0.0)
	if _target is Explorer:
		(_target as Explorer).camera_yaw = look.x
