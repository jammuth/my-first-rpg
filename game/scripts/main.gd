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


# Runs before children's _ready, so the truck is at its (saved) spot and the origin is set before
# ChunkManager builds the first chunks around it.
func _enter_tree() -> void:
	var truck: Node3D = $Truck
	var start: Vector2 = GameState.start_position if GameState.start_position != null else Vector2.ZERO
	_set_origin(WorldOrigin.origin_for(start))
	truck.position = Vector3(start.x, 0.0, start.y) - GameState.origin
	truck.rotation.y = GameState.start_yaw


func _ready() -> void:
	_truck.terrain = _chunks.terrain
	_camera.terrain = _chunks.terrain
	_truck.snap_to_terrain()
	_truck.reset_physics_interpolation()
	$WorldEnvironment.environment = _make_environment()
	_hud.poi_panel_closed.connect(func() -> void: _truck.controls_enabled = true)
	_refresh_pois()


func _physics_process(_delta: float) -> void:
	var shift := WorldOrigin.shift_for(_truck.position)
	if shift != Vector3.ZERO:
		_shift_origin(shift)


func _process(delta: float) -> void:
	var f := -_camera.global_basis.z
	var world := truck_world_position()
	_hud.compass.heading = CompassMath.heading_of(Vector2(f.x, f.z))
	_hud.compass.player_pos = world
	GameState.truck_world_position = world
	GameState.truck_yaw = _truck.rotation.y
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


func truck_world_position() -> Vector2:
	var p := _truck.global_position + GameState.origin
	return Vector2(p.x, p.z)


func _set_origin(origin: Vector3) -> void:
	GameState.origin = origin
	RenderingServer.global_shader_parameter_set("world_origin", origin)
	var chunks := get_node_or_null("ChunkManager") as Node3D
	if chunks != null:
		chunks.position = -origin


## Re-centres the world on the truck: everything that lives in local space moves by -shift.
func _shift_origin(shift: Vector3) -> void:
	_set_origin(GameState.origin + shift)
	_truck.position -= shift
	_truck.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for node in get_tree().get_nodes_in_group("origin_shift_listeners"):
		node.on_origin_shifted(shift)


func _refresh_pois() -> void:
	var p2 := truck_world_position()
	var pos := Vector3(p2.x, 0.0, p2.y)
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
	env.fog_height = -12.0
	env.fog_height_density = 0.02
	return env
