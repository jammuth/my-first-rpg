class_name LootWindow
extends PanelContainer

## The container's contents beside the bag, or the bag alone. Gamepad first: every slot is a
## focusable button. With a container open, pressing a container slot takes it and pressing a bag
## slot drops it into the container. With the bag alone, pressing two slots swaps them.

signal changed
signal closed

const SLOT_SIZE := Vector2(132, 62)
const BAG_COLUMNS := 5
const EMPTY_COLOR := Color(1, 1, 1, 0.08)
const SELECTED_COLOR := Color(1.0, 0.85, 0.3)

var _bag: Bag
## The open container's stacks, or null for the bag on its own.
var _contents: Variant = null
var _selected := -1

var _title: Label
var _container_column: VBoxContainer
var _container_list: VBoxContainer
var _bag_label: Label
var _bag_grid: GridContainer
var _detail: Label
var _hint: Label


func _ready() -> void:
	visible = false
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.05, 0.05, 0.05, 0.94)
	panel.set_corner_radius_all(6)
	add_theme_stylebox_override("panel", panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	box.add_child(_title)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	box.add_child(columns)
	_container_column = VBoxContainer.new()
	columns.add_child(_container_column)
	var container_label := Label.new()
	container_label.text = "Contents"
	_container_column.add_child(container_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(SLOT_SIZE.x * 2.0, SLOT_SIZE.y * 3.0 + 16.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_container_column.add_child(scroll)
	_container_list = VBoxContainer.new()
	_container_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_container_list)

	var bag_column := VBoxContainer.new()
	columns.add_child(bag_column)
	_bag_label = Label.new()
	bag_column.add_child(_bag_label)
	_bag_grid = GridContainer.new()
	_bag_grid.columns = BAG_COLUMNS
	bag_column.add_child(_bag_grid)

	_detail = Label.new()
	_detail.custom_minimum_size = Vector2(0, 28)
	box.add_child(_detail)
	_hint = Label.new()
	_hint.modulate = Color(1, 1, 1, 0.7)
	box.add_child(_hint)


func open_container(title: String, contents: Array[Dictionary], bag: Bag) -> void:
	_bag = bag
	_contents = contents
	_title.text = title
	_hint.text = "E / A: take or drop    T / Y: take all    Esc / B: close"
	_show()


func open_bag(bag: Bag) -> void:
	_bag = bag
	_contents = null
	_title.text = "Bag"
	_hint.text = "E / A on two slots: swap    I / Y or Esc / B: close"
	_show()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _show() -> void:
	_selected = -1
	visible = true
	_container_column.visible = _contents != null
	_rebuild()
	_center.call_deferred()
	var first: Control = _container_list.get_child(0) if _contents != null and _container_list.get_child_count() > 0 else _bag_grid.get_child(0)
	first.grab_focus()


## The size depends on which columns are showing, so it's only known once the contents are built.
func _center() -> void:
	reset_size()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (_contents == null and event.is_action_pressed("inventory")):
		get_viewport().set_input_as_handled()
		close()
	elif _contents != null and event.is_action_pressed("take_all"):
		get_viewport().set_input_as_handled()
		LootTransfer.take_all(_bag, _contents)
		_after_change(_bag_grid, 0)


func _rebuild() -> void:
	for child in _container_list.get_children():
		_container_list.remove_child(child)
		child.queue_free()
	if _contents != null:
		for i in _contents.size():
			var b := _slot_button(_contents[i], -1)
			b.custom_minimum_size = Vector2(SLOT_SIZE.x * 2.0, SLOT_SIZE.y)
			b.pressed.connect(_take.bind(i))
			_container_list.add_child(b)
		if _contents.is_empty():
			var empty := Label.new()
			empty.text = "Empty"
			empty.modulate = Color(1, 1, 1, 0.5)
			_container_list.add_child(empty)
	if _bag_grid.get_child_count() != _bag.capacity():
		for child in _bag_grid.get_children():
			_bag_grid.remove_child(child)
			child.queue_free()
		for i in _bag.capacity():
			var b := Button.new()
			b.custom_minimum_size = SLOT_SIZE
			b.pressed.connect(_bag_pressed.bind(i))
			b.focus_entered.connect(_describe_bag_slot.bind(i))
			_bag_grid.add_child(b)
	for i in _bag.capacity():
		_style_slot(_bag_grid.get_child(i), _bag.slots[i], i)
	_bag_label.text = "Bag  %d / %d slots" % [_bag.used(), _bag.capacity()]


func _slot_button(stack: Dictionary, bag_index: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = SLOT_SIZE
	_style_slot(b, stack, bag_index)
	b.focus_entered.connect(func() -> void: _detail.text = ItemCatalog.describe(stack.id))
	return b


func _style_slot(b: Button, stack: Dictionary, bag_index: int) -> void:
	b.text = "" if stack.is_empty() else "%s\n×%d" % [ItemCatalog.item_name(stack.id), stack.count]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.85)
	style.set_corner_radius_all(4)
	style.set_border_width_all(2)
	style.border_width_left = 6
	style.border_color = EMPTY_COLOR if stack.is_empty() else ItemCatalog.rarity_color(stack.id)
	if bag_index >= 0 and bag_index == _selected:
		style.border_color = SELECTED_COLOR
		style.set_border_width_all(4)
	var focus := style.duplicate() as StyleBoxFlat
	focus.bg_color = Color(0.25, 0.25, 0.25, 0.95)
	b.add_theme_stylebox_override("normal", style)
	b.add_theme_stylebox_override("hover", focus)
	b.add_theme_stylebox_override("pressed", focus)
	b.add_theme_stylebox_override("focus", focus)


func _describe_bag_slot(i: int) -> void:
	var stack := _bag.slots[i]
	_detail.text = "" if stack.is_empty() else ItemCatalog.describe(stack.id)


func _take(i: int) -> void:
	if LootTransfer.take(_bag, _contents, i) == 0:
		_detail.text = "The bag is full."
		return
	_after_change(_container_list, i)


func _bag_pressed(i: int) -> void:
	if _contents != null:
		if _bag.slots[i].is_empty():
			return
		LootTransfer.drop(_bag, i, _contents)
		_after_change(_bag_grid, i)
	elif _selected < 0:
		if not _bag.slots[i].is_empty():
			_selected = i
			_rebuild()
	else:
		_bag.swap(_selected, i)
		_selected = -1
		_after_change(_bag_grid, i)


## Rebuilds and keeps focus near where it was, falling back to the bag when the container empties.
func _after_change(column: Control, index: int) -> void:
	_rebuild()
	changed.emit()
	var target: Control = _bag_grid.get_child(index) if column == _bag_grid else null
	if column == _container_list:
		var buttons := _container_list.get_children().filter(func(c: Node) -> bool: return c is Button)
		target = buttons[mini(index, buttons.size() - 1)] if not buttons.is_empty() else _bag_grid.get_child(0)
	target.grab_focus.call_deferred()
	if target.has_focus():
		target.focus_entered.emit()
