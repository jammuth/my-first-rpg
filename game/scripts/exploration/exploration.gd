extends Node3D

## Placeholder exploration scene: the explorer on foot beside the parked truck, a few blocks to
## walk around, and a debug panel (Tab / Start) driving the run's state until the level, loot and
## encounters exist.

const OVERWORLD_SCENE := "res://scenes/main.tscn"
const TRUCK_MODEL := "res://assets/models/vehicles/delivery.glb"
const EXPLORER_SCENE := preload("res://scenes/explorer.tscn")
const SAND := Color(0.82, 0.68, 0.46)
## Far enough from the cab that the camera, behind the explorer, starts clear of the truck.
const SPAWN := Vector3(6.5, 0.0, -1.0)

var _status: Label
var _panel: PanelContainer
var _first_button: Button
var _session: ExplorationSession
var _explorer: Explorer


func _ready() -> void:
	_session = GameState.exploration
	if _session == null:
		get_tree().change_scene_to_file.call_deferred(OVERWORLD_SCENE)
		return
	_build_world()
	_spawn_explorer()
	_build_ui()
	_set_panel_open(false)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("exploration_menu") or (_panel.visible and event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_set_panel_open(not _panel.visible)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and not _panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_panel_open(open: bool) -> void:
	_panel.visible = open
	_explorer.controls_enabled = not open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
	if open:
		_first_button.grab_focus()
	elif get_viewport().gui_get_focus_owner() != null:
		get_viewport().gui_get_focus_owner().release_focus()


func _spawn_explorer() -> void:
	_explorer = EXPLORER_SCENE.instantiate()
	_explorer.character_id = GameState.character_id
	_explorer.position = SPAWN
	add_child(_explorer)
	_explorer.face(PI * 0.5)
	var cam := ChaseCamera.new()
	cam.name = "ChaseCamera"
	cam.target_path = NodePath("../Explorer")
	add_child(cam)
	cam.set_yaw(-PI * 0.5)


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.86, 0.78, 0.62)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.70, 0.62)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_color = Color(1, 0.91, 0.76)
	sun.shadow_enabled = true
	add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = SAND
	mat.roughness = 1.0
	plane.material = mat
	ground.mesh = plane
	add_child(ground)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(floor_shape)
	add_child(floor_body)

	var truck: Node3D = (load(TRUCK_MODEL) as PackedScene).instantiate()
	truck.transform = Transform3D(Basis.from_scale(Vector3(2, 2, 2)).rotated(Vector3.UP, PI), Vector3.ZERO)
	add_child(truck)
	_add_block(Vector3(0, 1.7, 0), Vector3(3, 3.2, 6.5), false)

	# Stand-ins to walk around and test camera collision until step 3 builds the real site.
	var wall := Color(0.62, 0.52, 0.40)
	_add_block(Vector3(12, 2.0, -6), Vector3(8, 4, 1), true, wall)
	_add_block(Vector3(-10, 1.5, 8), Vector3(1, 3, 10), true, wall)
	_add_block(Vector3(6, 0.5, 9), Vector3(1.2, 1, 1.2), true, Color(0.45, 0.40, 0.33))


func _add_block(center: Vector3, size: Vector3, visible_mesh: bool, color := Color.WHITE) -> void:
	var body := StaticBody3D.new()
	body.position = center
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	if visible_mesh:
		var mesh := MeshInstance3D.new()
		var cube := BoxMesh.new()
		cube.size = size
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		cube.material = mat
		mesh.mesh = cube
		body.add_child(mesh)
	add_child(body)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var hint := Label.new()
	hint.text = "Tab / Start: debug actions    V / R3: shoulder view    Shift / L3: run"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_left = 20
	hint.offset_top = -48
	hint.offset_bottom = -16
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	hint.add_theme_constant_override("outline_size", 6)
	layer.add_child(hint)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	_panel = panel
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(380, 0)
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 26)
	title.text = GameState.exploration_poi.display_name if GameState.exploration_poi else _session.poi_id
	box.add_child(title)
	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Placeholder: the explorer, level, loot and encounters arrive in later steps."
	box.add_child(note)
	_status = Label.new()
	box.add_child(_status)

	_first_button = _button(box, "Search a crate (debug)", _search_crate)
	_button(box, "Lose an encounter (debug)", _lose_encounter)
	_button(box, "Unload at truck", _unload)
	_button(box, "Drive away", _drive_away)


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
	_status.text = "Bag: %d scrap\nTruck stash: %d scrap\nCrates emptied here (banked): %d" % [
		ItemStacks.total(_session.bag), ItemStacks.total(GameState.truck_stash), _session.poi_state.looted.size()]
