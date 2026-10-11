extends Node3D

## Placeholder exploration scene: the truck parked at the POI plus debug actions that drive the
## run's state. The explorer, level, loot and encounters replace the debug panel in later steps.

const OVERWORLD_SCENE := "res://scenes/main.tscn"
const TRUCK_MODEL := "res://assets/models/vehicles/delivery.glb"
const SAND := Color(0.82, 0.68, 0.46)

var _status: Label
var _session: ExplorationSession


func _ready() -> void:
	_session = GameState.exploration
	if _session == null:
		get_tree().change_scene_to_file.call_deferred(OVERWORLD_SCENE)
		return
	_build_world()
	_build_ui()
	_refresh()


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

	var truck: Node3D = (load(TRUCK_MODEL) as PackedScene).instantiate()
	truck.transform = Transform3D(Basis.from_scale(Vector3(2, 2, 2)).rotated(Vector3.UP, PI), Vector3.ZERO)
	add_child(truck)

	var cam := Camera3D.new()
	cam.position = Vector3(9, 6, 13)
	add_child(cam)
	cam.look_at(Vector3(0, 1.5, 0))


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
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

	var first := _button(box, "Search a crate (debug)", _search_crate)
	_button(box, "Lose an encounter (debug)", _lose_encounter)
	_button(box, "Unload at truck", _unload)
	_button(box, "Drive away", _drive_away)
	first.grab_focus()


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
	GameState.end_exploration()
	get_tree().change_scene_to_file.call_deferred(OVERWORLD_SCENE)


func _refresh() -> void:
	_status.text = "Bag: %d scrap\nTruck stash: %d scrap\nCrates emptied here (banked): %d" % [
		ItemStacks.total(_session.bag), ItemStacks.total(GameState.truck_stash), _session.poi_state.looted.size()]
