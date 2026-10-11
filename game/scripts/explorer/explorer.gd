class_name Explorer
extends CharacterBody3D

@export var walk_speed := 2.6
@export var run_speed := 5.6
@export var acceleration := 24.0
## Higher = turns to face the movement direction faster.
@export var turn_sharpness := 12.0
@export var gravity := 20.0
## Steepest rise (over run) the explorer walks up; anything steeper is a cliff.
@export var max_climb_grade := 1.2
## How far ahead the slope is checked.
@export var slope_probe := 0.8

## Set before the explorer enters the tree; see set_character() to change it later.
var character_id := CharacterOptions.DEFAULT
var controls_enabled := true
## Set by the camera each frame; movement is relative to where the player is looking.
var camera_yaw := 0.0
## When set, height follows the terrain (which has no collision mesh) like the truck does.
var terrain: TerrainSampler
## Floating-origin offset: world = local + origin.
var origin := Vector3.ZERO
## When set, the explorer can't leave its boundary.
var level: ExplorationLevel
## True while pressed against the level boundary, for a HUD hint.
var at_boundary := false

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
	if terrain != null and target != Vector3.ZERO and _cliff_ahead(target.normalized()):
		target = Vector3.ZERO
	var horizontal := ExplorerMotion.approach(Vector3(velocity.x, 0.0, velocity.z), target, acceleration, delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if terrain != null:
		velocity.y = 0.0
	else:
		velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	move_and_slide()
	_keep_in_bounds()
	if terrain != null:
		var p := global_position + origin
		position.y = terrain.height_at(p.x, p.z) - origin.y
	_model.rotation.y = ExplorerMotion.turn_towards(_model.rotation.y, direction, turn_sharpness, delta)
	_animate(Vector2(velocity.x, velocity.z).length())


func _cliff_ahead(direction: Vector3) -> bool:
	var p := global_position + origin
	var here := terrain.height_at(p.x, p.z)
	var ahead := terrain.height_at(p.x + direction.x * slope_probe, p.z + direction.z * slope_probe)
	return TruckMotion.blocked_by_slope(here, ahead, slope_probe, max_climb_grade)


func _keep_in_bounds() -> void:
	at_boundary = false
	if level == null:
		return
	var world := Vector2(global_position.x + origin.x, global_position.z + origin.z)
	if level.inside_boundary(world):
		return
	at_boundary = true
	var clamped := level.clamp_to_boundary(world)
	global_position.x = clamped.x - origin.x
	global_position.z = clamped.y - origin.z
	var slid := ExplorerMotion.slide_along(Vector2(velocity.x, velocity.z), (world - level.boundary_center).normalized())
	velocity.x = slid.x
	velocity.z = slid.y


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
