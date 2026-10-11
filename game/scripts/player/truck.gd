class_name Truck
extends CharacterBody3D

@export var max_speed := 18.0
@export var reverse_speed := 8.0
@export var acceleration := 14.0
@export var braking := 30.0
@export var turn_speed := 1.9

var controls_enabled := true
var speed := 0.0


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
	position.y = 0.0
