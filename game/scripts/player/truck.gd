class_name Truck
extends CharacterBody3D

@export var max_speed := 18.0
@export var reverse_speed := 8.0
@export var acceleration := 14.0
@export var braking := 30.0
@export var turn_speed := 1.9
## Distances between the terrain sample points used to tilt the body.
@export var wheelbase := 5.0
@export var track_width := 2.8
## Higher = body settles onto slopes faster.
@export var tilt_sharpness := 10.0

var controls_enabled := true
var speed := 0.0
var terrain: TerrainSampler

@onready var _tilt: Node3D = $Tilt


func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var steer := 0.0
	if controls_enabled:
		throttle = Input.get_axis("move_back", "move_forward")
		steer = Input.get_axis("turn_right", "turn_left")
	speed = TruckMotion.step_speed(speed, throttle, delta, max_speed, reverse_speed, acceleration, braking)
	rotate_y(steer * turn_speed * delta)
	var forward := -global_basis.z
	velocity = forward * speed
	move_and_slide()
	# Bleed speed into walls instead of grinding against them at full throttle.
	speed = velocity.dot(forward)
	if terrain != null:
		snap_to_terrain(delta)


func snap_to_terrain(delta: float = 0.0) -> void:
	var p := global_position
	position.y = terrain.height_at(p.x, p.z)
	var fwd := -global_basis.z * (wheelbase * 0.5)
	var right := global_basis.x * (track_width * 0.5)
	var tilt := TruckMotion.tilt_from_heights(
		terrain.height_at(p.x + fwd.x, p.z + fwd.z), terrain.height_at(p.x - fwd.x, p.z - fwd.z),
		terrain.height_at(p.x - right.x, p.z - right.z), terrain.height_at(p.x + right.x, p.z + right.z),
		wheelbase, track_width)
	var target := Basis.from_euler(Vector3(tilt.x, 0.0, tilt.y))
	var t := 1.0 if delta <= 0.0 else 1.0 - exp(-tilt_sharpness * delta)
	_tilt.basis = _tilt.basis.slerp(target, t).orthonormalized()
