extends Node3D

const POI_REFRESH_INTERVAL := 0.2
const EXPLORATION_SCENE := "res://scenes/exploration.tscn"

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
	$WorldEnvironment.environment = DesertEnvironment.make()
	_apply_graphics()
	GraphicsSettings.changed.connect(_apply_graphics)
	var overlay := DebugOverlay.new()
	overlay.chunks = _chunks
	overlay.world_position = truck_world_position
	add_child(overlay)
	if OS.get_cmdline_user_args().has("--benchmark"):
		var bench := Benchmark.new()
		bench.truck = _truck
		bench.overlay = overlay
		add_child(bench)
	_hud.poi_panel_closed.connect(func() -> void: _truck.controls_enabled = true)
	_hud.explore_requested.connect(_explore)
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


func _explore(poi: PoiData) -> void:
	GameState.start_exploration(poi)
	get_tree().change_scene_to_file.call_deferred(EXPLORATION_SCENE)


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


func _apply_graphics() -> void:
	DesertEnvironment.apply_graphics($WorldEnvironment.environment, _camera, $Sun, get_viewport())
