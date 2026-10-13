class_name Hud
extends CanvasLayer

signal poi_panel_closed
signal explore_requested(poi: PoiData)

var compass: Compass
var _prompt: PanelContainer
var _prompt_label: Label
var _panel: PanelContainer
var _panel_title: Label
var _panel_type: Label
var _panel_note: Label
var _leave: Button
var _explore: Button
var _panel_poi: PoiData
var _using_gamepad := false
var _prompt_poi: PoiData


func _ready() -> void:
	compass = Compass.new()
	compass.set_anchors_preset(Control.PRESET_CENTER_TOP)
	compass.custom_minimum_size = Vector2(720, 64)
	compass.size = compass.custom_minimum_size
	compass.position = Vector2(-360, 8)
	compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(compass)

	_prompt = PanelContainer.new()
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.position.y = -90
	_prompt_label = Label.new()
	_prompt_label.add_theme_font_size_override("font_size", 22)
	_prompt.add_child(_prompt_label)
	_prompt.visible = false
	add_child(_prompt)

	var keys := Label.new()
	keys.text = "Tab / Start: workshop"
	keys.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	keys.add_theme_constant_override("outline_size", 6)
	keys.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	keys.grow_vertical = Control.GROW_DIRECTION_BEGIN
	keys.offset_left = 20
	keys.offset_top = -48
	keys.offset_bottom = -16
	add_child(keys)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 12)
	_panel_title = Label.new()
	_panel_title.add_theme_font_size_override("font_size", 30)
	_panel_type = Label.new()
	_panel_type.add_theme_font_size_override("font_size", 18)
	_panel_note = Label.new()
	_panel_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_note.text = "Park the truck and search the site on foot for scrap."
	_explore = Button.new()
	_explore.text = "Explore on foot"
	_explore.custom_minimum_size = Vector2(0, 44)
	_explore.pressed.connect(func() -> void: explore_requested.emit(_panel_poi))
	_leave = Button.new()
	_leave.text = "Leave"
	_leave.custom_minimum_size = Vector2(0, 44)
	_leave.pressed.connect(close_poi_panel)
	for c in [_panel_title, _panel_type, _panel_note, _explore, _leave]:
		box.add_child(c)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.add_child(box)
	_panel.add_child(margin)
	_panel.visible = false
	add_child(_panel)


func _input(event: InputEvent) -> void:
	var was := _using_gamepad
	if event is InputEventJoypadButton:
		_using_gamepad = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.4:
		_using_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		_using_gamepad = false
	if was != _using_gamepad:
		_refresh_prompt()
	if _panel.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_poi_panel()


func is_poi_panel_open() -> bool:
	return _panel.visible


func set_prompt_poi(poi: PoiData) -> void:
	if poi == _prompt_poi or (poi != null and _prompt_poi != null and poi.id == _prompt_poi.id):
		return
	_prompt_poi = poi
	_refresh_prompt()


func _refresh_prompt() -> void:
	_prompt.visible = _prompt_poi != null and not _panel.visible
	if _prompt_poi != null:
		_prompt_label.text = "  Press %s to enter %s  " % ["A" if _using_gamepad else "E", _prompt_poi.display_name]


func open_poi_panel(poi: PoiData, first_visit: bool) -> void:
	_panel_poi = poi
	_panel_title.text = poi.display_name
	_panel_type.text = poi.type_label + ("  ·  first visit" if first_visit else "  ·  visited")
	_panel.visible = true
	_refresh_prompt()
	_explore.grab_focus()


func close_poi_panel() -> void:
	if not _panel.visible:
		return
	_panel.visible = false
	if get_viewport().gui_get_focus_owner() != null:
		get_viewport().gui_get_focus_owner().release_focus()
	_refresh_prompt()
	poi_panel_closed.emit()
