extends Node3D

## A POI on foot: the same terrain, roads and compound as the overworld (a ChunkManager streams
## them around the explorer), the truck parked where the player left it, and the level's search
## spots and loot-room doors to use. The debug panel (Tab / Start) stands in for encounters until
## step 8.

const OVERWORLD_SCENE := "res://scenes/main.tscn"
const TRUCK_SCENE := preload("res://scenes/truck.tscn")
const EXPLORER_SCENE := preload("res://scenes/explorer.tscn")
const SUN_SCENE := preload("res://scenes/desert_sun.tscn")
const BLOWING_SAND := preload("res://scripts/world/blowing_sand.gd")
const MARKER_HEIGHT := 2.6
const CONTAINER_COLOR := Color(1.0, 0.82, 0.35)
const DOOR_COLOR := Color(0.45, 0.85, 1.0)
const DONE_COLOR := Color(0.6, 0.6, 0.6, 0.6)
## Stick deflection past this counts as walking off, which cancels a search.
const MOVE_DEADZONE := 0.2

var level: ExplorationLevel

var _status: Label
var _hint: Label
var _prompt: Label
var _progress: ProgressBar
var _panel: PanelContainer
var _first_button: Button
var _truck_menu: PanelContainer
var _truck_status: Label
var _truck_first_button: Button
var _loot: LootWindow
var _door_menu: PanelContainer
var _door_first_button: Button
## The locked door the Unlock popup is for.
var _door: Interactable
var _session: ExplorationSession
var _explorer: Explorer
var _camera: ChaseCamera
var _chunks: ChunkManager
var _env: Environment
var _sun: DirectionalLight3D
var _interactables: Array[Interactable] = []
## Interactable id -> Label3D over it.
var _markers := {}
var _target: Interactable
var _timer: InteractionTimer


func _ready() -> void:
	_session = GameState.exploration
	var poi := ExplorationLevel.poi_with_layout(GameState.world_seed, _session.poi_id) if _session else null
	if poi == null:
		get_tree().change_scene_to_file.call_deferred(OVERWORLD_SCENE)
		return
	var park := ExplorationLevel.parking(poi, GameState.start_position, GameState.start_yaw)
	level = ExplorationLevel.build(GameState.world_seed, poi, park[0], park[1])
	_interactables = Interactable.from_level(level)
	_set_origin(WorldOrigin.origin_for(level.truck_position))
	_build_world()
	_build_ui()
	_close_menus()
	_refresh()
	DesertEnvironment.apply_graphics(_env, _camera.camera(), _sun, get_viewport())


func _process(delta: float) -> void:
	_hint.text = "Too far from the site. Head back." if _explorer.at_boundary else ""
	_target = null if _menu_open() else Interactable.pick(_available(), _explorer_xz(), _explorer.facing())
	if _timer != null:
		var moving := Input.get_vector("walk_left", "walk_right", "walk_forward", "walk_back").length() > MOVE_DEADZONE
		if InteractionTimer.should_cancel(moving, false, _timer.target, _target):
			_stop_timer()
		elif _timer.advance(delta):
			var finished := _timer.target
			_stop_timer()
			_complete(finished)
	_show_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _loot.visible:
		return
	if event.is_action_pressed("exploration_menu") and not _truck_menu.visible and not _door_menu.visible:
		get_viewport().set_input_as_handled()
		if _panel.visible:
			_close_menus()
		else:
			_open_menu(_panel, _first_button)
	elif _menu_open() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_menus()
	elif not _menu_open() and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_on_interact()
	elif not _menu_open() and event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		_open_bag()
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and not _menu_open():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_origin(origin: Vector3) -> void:
	GameState.origin = origin
	RenderingServer.global_shader_parameter_set("world_origin", origin)


func _local(world: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(world.x, height, world.y) - GameState.origin


func _explorer_xz() -> Vector2:
	var p := _explorer.global_position + GameState.origin
	return Vector2(p.x, p.z)


func _available() -> Array[Interactable]:
	return _interactables.filter(func(it: Interactable) -> bool: return not _is_done(it))


## Searched or unlocked, so using it again skips straight to the loot window.
func _is_opened(it: Interactable) -> bool:
	match it.kind:
		Interactable.Kind.CONTAINER:
			return _session.is_opened(it.id)
		Interactable.Kind.DOOR:
			return _session.is_unlocked(it.id)
		_:
			return false


## Opened with nothing left inside, so there's no reason to prompt for it.
func _is_done(it: Interactable) -> bool:
	return it.kind != Interactable.Kind.TRUCK and _is_opened(it) and _session.is_emptied(it.id)


func _on_interact() -> void:
	if _timer != null:
		_stop_timer()
	elif _target == null:
		return
	elif _target.kind == Interactable.Kind.TRUCK:
		_open_menu(_truck_menu, _truck_first_button)
	elif _is_opened(_target):
		_open_loot(_target)
	elif _target.kind == Interactable.Kind.DOOR:
		_door = _target
		_open_menu(_door_menu, _door_first_button)
	else:
		_timer = InteractionTimer.new(_target)
		_explorer.interacting = true


func _stop_timer() -> void:
	_timer = null
	_explorer.interacting = false


func _complete(it: Interactable) -> void:
	_open_loot(it)


## Stands in for keys and the drone's hack until they're built.
func _unlock_door() -> void:
	_session.unlock(_door.id)
	_open_loot(_door)


func _open_loot(it: Interactable) -> void:
	var rolled := LootTables.roll(GameState.world_seed, level.poi, it.id, it.loot_kind())
	var contents := _session.open(it.id, rolled, GameState.play_time)
	_open_menu(_loot, null)
	_loot.open_container(it.title(), contents, _session.bag)
	_refresh()


func _open_bag() -> void:
	_open_menu(_loot, null)
	_loot.open_bag(_session.bag)


func _show_prompt() -> void:
	_progress.visible = _timer != null
	if _timer != null:
		_prompt.text = "%s    (E / A or move to cancel)" % _timer.target.progress_text()
		_progress.value = _timer.fraction()
	else:
		_prompt.text = _target.prompt(_is_opened(_target)) if _target != null else ""


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

	for it in _interactables:
		if it.kind != Interactable.Kind.TRUCK:
			_markers[it.id] = _add_marker(it.position)


## Placeholder labels over search spots and loot-room doors until they get proper highlights.
func _add_marker(world: Vector2) -> Label3D:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	label.pixel_size = 0.02
	label.outline_size = 12
	label.no_depth_test = false
	label.position = _local(world, _chunks.terrain.height_at(world.x, world.y) + MARKER_HEIGHT)
	add_child(label)
	return label


func _refresh_markers() -> void:
	for it in _interactables:
		if not _markers.has(it.id):
			continue
		var label: Label3D = _markers[it.id]
		var done := _is_done(it)
		var text := "LOOT ROOM" if it.kind == Interactable.Kind.DOOR else it.label.to_upper()
		if done:
			text = "EMPTY"
		elif _is_opened(it):
			text += " (%d left)" % _session.contents(it.id).size()
		label.text = text
		label.modulate = DONE_COLOR if done else (DOOR_COLOR if it.kind == Interactable.Kind.DOOR else CONTAINER_COLOR)


func _menu_open() -> bool:
	return _panel.visible or _truck_menu.visible or _door_menu.visible or _loot.visible


## `focus` may be null when the menu sets its own focus.
func _open_menu(menu: PanelContainer, focus: Button) -> void:
	_stop_timer()
	_panel.visible = menu == _panel
	_truck_menu.visible = menu == _truck_menu
	_door_menu.visible = menu == _door_menu
	_explorer.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if focus != null:
		focus.grab_focus()


func _close_menus() -> void:
	_panel.visible = false
	_truck_menu.visible = false
	_door_menu.visible = false
	_loot.close()
	_explorer.controls_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if get_viewport().gui_get_focus_owner() != null:
		get_viewport().gui_get_focus_owner().release_focus()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var keys := Label.new()
	keys.text = "E / A: interact    I / Y: bag    Tab / Start: debug actions    V / R3: shoulder view    Shift / L3: run"
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
	_hint.offset_top = -200
	_hint.offset_bottom = -160
	layer.add_child(_hint)

	var prompt_box := VBoxContainer.new()
	prompt_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	prompt_box.offset_top = -150
	prompt_box.offset_bottom = -80
	prompt_box.alignment = BoxContainer.ALIGNMENT_END
	layer.add_child(prompt_box)
	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 24)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outline(_prompt)
	prompt_box.add_child(_prompt)
	_progress = ProgressBar.new()
	_progress.max_value = 1.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(320, 14)
	_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	prompt_box.add_child(_progress)

	var box := _menu(layer, false)
	_panel = box.get_parent().get_parent()
	_title(box, level.poi.display_name)
	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Debug actions until random encounters arrive."
	box.add_child(note)
	_status = Label.new()
	box.add_child(_status)
	_first_button = _button(box, "Lose an encounter (debug)", _lose_encounter)
	_button(box, "Close", _close_menus)

	var truck_box := _menu(layer, true)
	_truck_menu = truck_box.get_parent().get_parent()
	_title(truck_box, "Truck")
	_truck_status = Label.new()
	truck_box.add_child(_truck_status)
	_truck_first_button = _button(truck_box, "Unload the bag", _unload)
	_button(truck_box, "Unload and drive away", _drive_away)
	_button(truck_box, "Cancel", _close_menus)

	var door_box := _menu(layer, true)
	_door_menu = door_box.get_parent().get_parent()
	_title(door_box, "Loot room")
	var locked := Label.new()
	locked.text = "The door is locked."
	door_box.add_child(locked)
	_door_first_button = _button(door_box, "Unlock", _unlock_door)
	_button(door_box, "Cancel", _close_menus)

	_loot = LootWindow.new()
	layer.add_child(_loot)
	_loot.changed.connect(_refresh)
	_loot.closed.connect(_close_menus)


## A panel with a column for its contents; returns the column (the panel is two parents up).
func _menu(layer: CanvasLayer, centred: bool) -> VBoxContainer:
	var panel := PanelContainer.new()
	if centred:
		panel.set_anchors_preset(Control.PRESET_CENTER)
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	else:
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
	return box


func _title(box: VBoxContainer, text: String) -> void:
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 26)
	title.text = text
	box.add_child(title)


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


func _lose_encounter() -> void:
	_session.defeat()
	_refresh()


func _unload() -> void:
	GameState.unload_at_truck()
	_refresh()
	_close_menus()


func _drive_away() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.end_exploration()
	get_tree().change_scene_to_file.call_deferred(OVERWORLD_SCENE)


func _refresh() -> void:
	var searched := _interactables.filter(func(it: Interactable) -> bool:
		return it.kind == Interactable.Kind.CONTAINER and _is_opened(it)).size()
	var opened := _interactables.filter(func(it: Interactable) -> bool:
		return it.kind == Interactable.Kind.DOOR and _is_opened(it)).size()
	var stash := "Bag: %d / %d slots\nTruck stash: %d items" % [
		_session.bag.used(), _session.bag.capacity(), ItemStacks.total(GameState.truck_stash)]
	_truck_status.text = stash
	_status.text = "%s\nSearched: %d / %d    Loot rooms open: %d / %d\nEncounters this run: %d" % [
		stash, searched, level.containers.size(), opened, level.loot_rooms.size(), _session.encounters]
	_refresh_markers()
