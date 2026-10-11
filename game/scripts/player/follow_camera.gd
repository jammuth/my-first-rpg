class_name FollowCamera
extends Camera3D

@export var target_path: NodePath
@export var distance := 36.0
@export_range(20.0, 80.0) var pitch_degrees := 45.0
@export var look_height := 2.0
## Higher = camera swings round to the truck's heading faster.
@export var yaw_sharpness := 4.0
## Minimum height above the ground directly below the camera, so low orbits can't clip into dunes.
@export var ground_clearance := 3.0

@export_group("Orbit")
## Radians of orbit per pixel of mouse movement while right mouse is held.
@export var mouse_sensitivity := 0.006
## Radians per second at full right-stick deflection.
@export var stick_speed := 2.5
@export_range(5.0, 89.0) var min_pitch_degrees := 12.0
@export_range(5.0, 89.0) var max_pitch_degrees := 80.0
## Higher = snaps back to the default view faster once orbiting stops.
@export var return_sharpness := 4.0

var terrain: TerrainSampler

var _target: Node3D
var _yaw := 0.0
## Offset from the default view: x = yaw (radians), y = pitch (radians).
var _orbit := Vector2.ZERO
var _mouse_orbiting := false


static func offset_for(yaw: float, pitch_radians: float, dist: float) -> Vector3:
	var local := Vector3(0.0, sin(pitch_radians), cos(pitch_radians)) * dist
	return Basis(Vector3.UP, yaw) * local


## Applies an orbit input, keeping the total pitch within limits and the yaw offset wrapped.
static func orbit_drag(orbit: Vector2, delta_radians: Vector2, base_pitch: float,
		min_pitch: float, max_pitch: float) -> Vector2:
	var yaw := wrapf(orbit.x + delta_radians.x, -PI, PI)
	var pitch := clampf(base_pitch + orbit.y + delta_radians.y, min_pitch, max_pitch) - base_pitch
	return Vector2(yaw, pitch)


## Eases the orbit offset back towards the default view, taking the short way round in yaw.
static func orbit_return(orbit: Vector2, sharpness: float, delta: float) -> Vector2:
	var t := 1.0 - exp(-sharpness * delta)
	return Vector2(lerp_angle(orbit.x, 0.0, t), lerpf(orbit.y, 0.0, t))


func _ready() -> void:
	_target = get_node(target_path)
	# Driven from _process with the target's interpolated transform, so skip engine interpolation here.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_yaw = _target.global_rotation.y
	_place(_target.global_transform)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_set_mouse_orbiting(event.pressed)
	elif event is InputEventMouseMotion and _mouse_orbiting:
		_drag(Vector2(-event.relative.x, event.relative.y) * mouse_sensitivity)


func _notification(what: int) -> void:
	# The release event never arrives if focus is lost mid-drag, which would leave the mouse captured.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_set_mouse_orbiting(false)


func _process(delta: float) -> void:
	var stick := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if stick != Vector2.ZERO:
		_drag(Vector2(-stick.x, stick.y) * stick_speed * delta)
	elif not _mouse_orbiting:
		_orbit = orbit_return(_orbit, return_sharpness, delta)
	var t := _target.get_global_transform_interpolated()
	_yaw = lerp_angle(_yaw, t.basis.get_euler().y, 1.0 - exp(-yaw_sharpness * delta))
	_place(t)


func _set_mouse_orbiting(active: bool) -> void:
	if active == _mouse_orbiting:
		return
	_mouse_orbiting = active
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE


func _drag(delta_radians: Vector2) -> void:
	_orbit = orbit_drag(_orbit, delta_radians, deg_to_rad(pitch_degrees),
		deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))


func _place(t: Transform3D) -> void:
	var focus := t.origin + Vector3.UP * look_height
	var pitch := deg_to_rad(pitch_degrees) + _orbit.y
	var pos := focus + offset_for(_yaw + _orbit.x, pitch, distance)
	if terrain != null:
		var world := pos + GameState.origin
		pos.y = maxf(pos.y, terrain.height_at(world.x, world.z) + ground_clearance)
	global_position = pos
	look_at(focus, Vector3.UP)
