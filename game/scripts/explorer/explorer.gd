class_name Explorer
extends CharacterBody3D

@export var walk_speed := 2.6
@export var run_speed := 5.6
@export var acceleration := 24.0
## Higher = turns to face the movement direction faster.
@export var turn_sharpness := 12.0
@export var gravity := 20.0

## Set before the explorer enters the tree; see set_character() to change it later.
var character_id := CharacterOptions.DEFAULT
var controls_enabled := true
## Set by the camera each frame; movement is relative to where the player is looking.
var camera_yaw := 0.0

var _model: Node3D
var _anim: AnimationPlayer


func _ready() -> void:
	set_character(character_id)


func set_character(id: String) -> void:
	character_id = id
	var yaw := 0.0
	if _model != null:
		yaw = _model.rotation.y
		_model.free()
	_model = CharacterBuilder.build(id)
	_model.rotation.y = yaw
	add_child(_model)
	_anim = _model.get_node("AnimationPlayer")
	_anim.play(ExplorerAnimations.IDLE)


func face(yaw: float) -> void:
	_model.rotation.y = yaw


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	var sprinting := false
	if controls_enabled:
		input = Input.get_vector("walk_left", "walk_right", "walk_forward", "walk_back")
		sprinting = Input.is_action_pressed("sprint")
	var direction := ExplorerMotion.move_direction(input, camera_yaw)
	var speed := ExplorerMotion.target_speed(input.length(), sprinting, walk_speed, run_speed)
	var target := direction.normalized() * speed if direction != Vector3.ZERO else Vector3.ZERO
	var horizontal := ExplorerMotion.approach(Vector3(velocity.x, 0.0, velocity.z), target, acceleration, delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	move_and_slide()
	_model.rotation.y = ExplorerMotion.turn_towards(_model.rotation.y, direction, turn_sharpness, delta)
	_animate(Vector2(velocity.x, velocity.z).length())


func _animate(speed: float) -> void:
	var anim_name := ExplorerMotion.animation_for(speed, walk_speed)
	if _anim.current_animation != anim_name:
		_anim.play(anim_name, 0.2)
	# Keeps feet roughly matched to ground speed across analog deflection.
	match anim_name:
		ExplorerAnimations.WALK:
			_anim.speed_scale = clampf(speed / walk_speed, 0.6, 1.3)
		ExplorerAnimations.RUN:
			_anim.speed_scale = clampf(speed / run_speed, 0.8, 1.2)
		_:
			_anim.speed_scale = 1.0
