extends Node3D

## A POI on foot: the same terrain, roads and compound as the overworld (a ChunkManager streams
## them around the explorer), the truck parked where the player left it, and the level's search
## spots marked. The debug panel (Tab / Start) drives the run's state until interactables, loot and
## encounters replace it.

const OVERWORLD_SCENE := "res://scenes/main.tscn"
const TRUCK_SCENE := preload("res://scenes/truck.tscn")
const EXPLORER_SCENE := preload("res://scenes/explorer.tscn")
const SUN_SCENE := preload("res://scenes/desert_sun.tscn")
const BLOWING_SAND := preload("res://scripts/world/blowing_sand.gd")
const MARKER_HEIGHT := 2.6
const CONTAINER_COLOR := Color(1.0, 0.82, 0.35)
const DOOR_COLOR := Color(0.45, 0.85, 1.0)

var level: ExplorationLevel

var _status: Label
var _hint: Label
var _panel: PanelContainer
var _first_button: Button
var _session: ExplorationSession
var _explorer: Explorer
var _camera: ChaseCamera
var _chunks: ChunkManager
var _env: Environment
var _sun: DirectionalLight3D


func _ready() -> void:
	_session = GameState.exploration
	var poi := ExplorationLevel.poi_with_layout(GameState.world_seed, _session.poi_id) if _session else null
	if poi == null:
		get_tree().change_scene_to_file.call_deferred(OVERWORLD_SCENE)
		return
	var park := ExplorationLevel.parking(poi, GameState.start_position, GameState.start_yaw)
	level = ExplorationLevel.build(GameState.world_seed, poi, park[0], park[1])
	_set_origin(WorldOrigin.origin_for(level.truck_position))
	_build_world()
	_build_ui()
	_set_panel_open(false)
	_refresh()
	DesertEnvironment.apply_graphics(_env, _camera.camera(), _sun, get_viewport())


func _process(_delta: float) -> void:
	var p := _explorer.global_position + GameState.origin
	var here := Vector2(p.x, p.z)
	if _explorer.at_boundary:
		_hint.text = "Too far from the site. Head back."
	elif level.in_extraction_zone(here):
		_hint.text = "At the truck: Tab / Start to unload or drive away"
	else:
		_hint.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("exploration_menu") or (_panel.visible and event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_set_panel_open(not _panel.visible)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and not _panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_origin(origin: Vector3) -> void:
	GameState.origin = origin
	RenderingServer.global_shader_parameter_set("world_origin", origin)


func _local(world: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(world.x, height, world.y) - GameState.origin


func _build_world() -> void:
	_env = DesertEnvironment.make()
	var world_env := WorldEnvironment.new()
	world_env.environment = _env
	add_child(world_env)
	_sun = SUN_SCENE.instantiate()
	add_child(_sun)

	_explorer = EXPLORER_SCENE.instantiate()
	_explorer.character_id = GameState.character_id
	_explorer.position = _local(level.spawn)
	_explorer.origin = GameState.origin
	_explorer.level = level
	add_child(_explorer)
	# Models face +Z; the truck (and so the start view) faces -Z.
	_explorer.face(level.spawn_yaw + PI)

	_chunks = ChunkManager.new()
	_chunks.name = "ChunkManager"
	_chunks.target_path = NodePath("../Explorer")
	# The walkable area is small; one ring of content around the explorer covers it and the view.
	_chunks.content_radius = 1
	_chunks.content_unload_radius = 2
	add_child(_chunks)
	_explorer.terrain = _chunks.terrain
	var start := level.spawn
	_explorer.position.y = _chunks.terrain.height_at(start.x, start.y) - GameState.origin.y
	_explorer.reset_physics_interpolation()

	var truck: Truck = TRUCK_SCENE.instantiate()
	truck.controls_enabled = false
	truck.position = _local(level.truck_position)
	truck.rotation.y = level.truck_yaw
	add_child(truck)
	truck.terrain = _chunks.terrain
	truck.snap_to_terrain()
	truck.reset_physics_interpolation()

	_camera = ChaseCamera.new()
	_camera.name = "ChaseCamera"
	_camera.target_path = NodePath("../Explorer")
	_camera.terrain = _chunks.terrain
	_camera.origin = GameState.origin
	add_child(_camera)
	_camera.set_yaw(level.spawn_yaw)

	var sand := GPUParticles3D.new()
	sand.set_script(BLOWING_SAND)
	sand.set("target_path", NodePath("../Explorer"))
	add_child(sand)

	for c in level.containers:
		_add_marker(c.position, c.kind.to_upper(), CONTAINER_COLOR)
	for d in level.loot_rooms:
		_add_marker(d.position, "LOOT ROOM", DOOR_COLOR)


## Placeholder labels over search spots and loot-room doors until step 4 makes them interactable.
func _add_marker(world: Vector2, text: String, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	label.pixel_size = 0.02
	label.outline_size = 12
	label.no_depth_test = false
	label.position = _local(world, _chunks.terrain.height_at(world.x, world.y) + MARKER_HEIGHT)
	add_child(label)


func _set_panel_open(open: bool) -> void:
	_panel.visible = open
	_explorer.controls_enabled = not open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
	if open:
		_first_button.grab_focus()
	elif get_viewport().gui_get_focus_owner() != null:
		get_viewport().gui_get_focus_owner().release_focus()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var keys := Label.new()
	keys.text = "Tab / Start: debug actions    V / R3: shoulder view    Shift / L3: run"
	_outline(keys)
	keys.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	keys.grow_vertical = Control.GROW_DIRECTION_BEGIN
	keys.offset_left = 20
	keys.offset_top = -48
	keys.offset_bottom = -16
	layer.add_child(keys)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 24)
	_outline(_hint)
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.offset_top = -120
	_hint.offset_bottom = -80
	layer.add_child(_hint)

	_panel = PanelContainer.new()
	_panel.position = Vector2(24, 24)
	layer.add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(380, 0)
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 26)
	title.text = level.poi.display_name
	box.add_child(title)
	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Placeholder: searching, loot rooms and encounters arrive in later steps."
	box.add_child(note)
	_status = Label.new()
	box.add_child(_status)

	_first_button = _button(box, "Search a crate (debug)", _search_crate)
	_button(box, "Lose an encounter (debug)", _lose_encounter)
	_button(box, "Unload at truck", _unload)
	_button(box, "Drive away", _drive_away)


func _outline(label: Label) -> void:
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("outline_size", 6)


func _button(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _search_crate() -> void:
	var i := 0
	while _session.is_looted("debug_crate_%d" % i):
		i += 1
	var items: Array[Dictionary] = [{"id": "scrap_metal", "count": 1 + i % 3}]
	_session.loot("debug_crate_%d" % i, items, GameState.play_time)
	_refresh()


func _lose_encounter() -> void:
	_session.defeat()
	_refresh()


func _unload() -> void:
	GameState.unload_at_truck()
	_refresh()


func _drive_away() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.end_exploration()
	get_tree().change_scene_to_file.call_deferred(OVERWORLD_SCENE)


func _refresh() -> void:
	_status.text = "Bag: %d scrap\nTruck stash: %d scrap\nSearch spots: %d    Loot rooms: %d" % [
		ItemStacks.total(_session.bag), ItemStacks.total(GameState.truck_stash),
		level.containers.size(), level.loot_rooms.size()]
