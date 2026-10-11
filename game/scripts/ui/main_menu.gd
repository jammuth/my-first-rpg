extends Control

## Title screen: Continue / New game / Quit, plus the explorer picker with a turntable preview.
## --benchmark and --new-game skip straight to the overworld, as they did before the menu existed.

const OVERWORLD_SCENE := "res://scenes/main.tscn"
const TURN_SPEED := 0.6

var _preview_root: Node3D
var _preview: Node3D
var _name_label: Label
var _continue: Button
var _new_game_button: Button
var _confirm: ConfirmationDialog


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--benchmark") or args.has("--new-game"):
		get_tree().change_scene_to_file.call_deferred(OVERWORLD_SCENE)
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()
	_show_character()
	(_continue if _continue.visible else _new_game_button).grab_focus()


func _process(delta: float) -> void:
	if _preview != null:
		_preview.rotation.y += TURN_SPEED * delta


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.13, 0.10)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.add_theme_constant_override("separation", 64)
	add_child(row)

	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(340, 0)
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", 14)
	row.add_child(menu)
	var title := Label.new()
	title.text = "My First RPG"
	title.add_theme_font_size_override("font_size", 48)
	menu.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Scavenge the wastes. Build your drones."
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.76, 0.58))
	menu.add_child(subtitle)
	menu.add_child(Control.new())
	_continue = _button(menu, "Continue", _start)
	_continue.visible = GameState.has_save
	_new_game_button = _button(menu, "New game", _ask_new_game)
	_button(menu, "Quit", func() -> void: get_tree().quit())

	var picker := VBoxContainer.new()
	picker.add_theme_constant_override("separation", 10)
	row.add_child(picker)
	var heading := Label.new()
	heading.text = "Explorer"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	picker.add_child(heading)
	picker.add_child(_build_preview())
	var choose := HBoxContainer.new()
	choose.add_theme_constant_override("separation", 12)
	picker.add_child(choose)
	var prev := _button(choose, "  <  ", func() -> void: _cycle(-1))
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.add_theme_font_size_override("font_size", 24)
	choose.add_child(_name_label)
	var next := _button(choose, "  >  ", func() -> void: _cycle(1))
	prev.custom_minimum_size.x = 64
	next.custom_minimum_size.x = 64

	_confirm = ConfirmationDialog.new()
	_confirm.title = "New game"
	_confirm.dialog_text = "Start a new game? Your current progress will be overwritten."
	_confirm.ok_button_text = "Start new game"
	_confirm.confirmed.connect(_new_game)
	add_child(_confirm)


func _build_preview() -> Control:
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(360, 440)
	container.stretch = true
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	container.add_child(viewport)
	_preview_root = Node3D.new()
	viewport.add_child(_preview_root)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.70, 0.62)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_preview_root.add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_color = Color(1, 0.91, 0.76)
	_preview_root.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 35.0
	var eye := Vector3(0, 1.3, 5.2)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.95, 0) - eye), eye)
	_preview_root.add_child(cam)
	return container


func _button(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _cycle(step: int) -> void:
	GameState.character_id = CharacterOptions.cycle(GameState.character_id, step)
	_show_character()


func _show_character() -> void:
	var yaw := 0.0
	if _preview != null:
		yaw = _preview.rotation.y
		_preview.free()
	_preview = CharacterBuilder.build(GameState.character_id)
	_preview.rotation.y = yaw
	_preview_root.add_child(_preview)
	(_preview.get_node("AnimationPlayer") as AnimationPlayer).play(ExplorerAnimations.IDLE)
	_name_label.text = CharacterOptions.label(GameState.character_id)


func _ask_new_game() -> void:
	if GameState.has_save:
		_confirm.popup_centered()
		_confirm.get_cancel_button().grab_focus()
	else:
		_new_game()


func _new_game() -> void:
	GameState.new_game()
	_start()


func _start() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(OVERWORLD_SCENE)
