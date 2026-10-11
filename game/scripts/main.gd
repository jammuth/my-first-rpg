extends Node3D

const POI_REFRESH_INTERVAL := 0.2

@onready var _truck: Truck = $Truck
@onready var _camera: Camera3D = $FollowCamera
@onready var _hud: Hud = $Hud

var _refresh_timer := 0.0
var _interactable: PoiData


func _ready() -> void:
	$WorldEnvironment.environment = _make_environment()
	_hud.poi_panel_closed.connect(func() -> void: _truck.controls_enabled = true)
	_refresh_pois()


func _process(delta: float) -> void:
	var f := -_camera.global_basis.z
	_hud.compass.heading = CompassMath.heading_of(Vector2(f.x, f.z))
	_hud.compass.player_pos = Vector2(_truck.global_position.x, _truck.global_position.z)
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = POI_REFRESH_INTERVAL
		_refresh_pois()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _interactable != null and not _hud.is_poi_panel_open():
		get_viewport().set_input_as_handled()
		var first := not GameState.is_visited(_interactable.id)
		GameState.mark_visited(_interactable.id)
		_truck.controls_enabled = false
		_hud.open_poi_panel(_interactable, first)


func _refresh_pois() -> void:
	var pos := _truck.global_position
	_hud.compass.pois = PoiGenerator.nearest(GameState.world_seed, pos, 3)
	_interactable = PoiGenerator.interactable(GameState.world_seed, pos)
	_hud.set_prompt_poi(_interactable)


func _make_environment() -> Environment:
	var env := Environment.new()
	var haze := Color(0.86, 0.76, 0.62)
	env.background_mode = Environment.BG_COLOR
	env.background_color = haze
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.72, 0.68)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = haze
	env.fog_density = 1.0
	env.fog_depth_begin = 150.0
	env.fog_depth_end = 290.0
	return env
