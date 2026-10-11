extends Node3D

const POI_REFRESH_INTERVAL := 0.2
const FOG_BEGIN := 200.0
const FOG_END := 500.0

@onready var _truck: Truck = $Truck
@onready var _camera: Camera3D = $FollowCamera
@onready var _hud: Hud = $Hud
@onready var _chunks: ChunkManager = $ChunkManager

var _refresh_timer := 0.0
var _interactable: PoiData


func _ready() -> void:
	_truck.terrain = _chunks.terrain
	_camera.terrain = _chunks.terrain
	_truck.snap_to_terrain()
	_truck.reset_physics_interpolation()
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
	var haze := Color(0.93, 0.80, 0.52)
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.42, 0.58, 0.78)
	sky_mat.sky_horizon_color = Color(0.95, 0.84, 0.60)
	sky_mat.sky_curve = 0.12
	sky_mat.ground_horizon_color = haze
	sky_mat.ground_bottom_color = Color(0.70, 0.56, 0.36)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	# Ambient/reflections only change with time of day, so a slow update keeps the GPU cost negligible.
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = haze
	env.fog_light_energy = 1.0
	env.fog_sun_scatter = 0.35
	env.fog_density = 1.0
	env.fog_depth_curve = 1.6
	env.fog_depth_begin = FOG_BEGIN
	env.fog_depth_end = FOG_END
	# Keeps the upper sky visible when the camera orbits low instead of fogging it out completely.
	env.fog_sky_affect = 0.3
	env.fog_height = 4.0
	env.fog_height_density = 0.04
	return env
