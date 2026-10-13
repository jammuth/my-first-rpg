class_name Workshop
extends Control

## The truck's workshop: the stash of unloaded scrap, the refinery slot and its queue, and the
## elements refined so far. Full screen over a background image. Gamepad first: pressing a stash
## stack queues it for refining, pressing a queued stack returns it, and pressing the slot stops it.

signal closed

const BACKGROUND := "res://assets/ui/workshop_background.png"
const ROW_SIZE := Vector2(320, 52)
const PANEL_COLOR := Color(0.05, 0.05, 0.05, 0.86)

var _stash_list: VBoxContainer
var _queue_list: VBoxContainer
var _slot_box: VBoxContainer
var _slot_bars: Array[ProgressBar] = []
var _slot_labels: Array[Label] = []
var _total: Label
var _elements: Label
var _detail: Label
## Element counts last shown, so the label only rebuilds when they change.
var _shown_elements := {}


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fill := ColorRect.new()
	fill.color = Color(0.11, 0.09, 0.07)
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fill)
	if ResourceLoader.exists(BACKGROUND):
		var bg := TextureRect.new()
		bg.texture = load(BACKGROUND)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)
	var title := Label.new()
	title.text = "Workshop"
	title.add_theme_font_size_override("font_size", 34)
	_outline(title)
	root.add_child(title)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	root.add_child(columns)
	_stash_list = _list(_panel(columns, "Stash  ·  press to refine"))
	var refining := _panel(columns, "Refining")
	_slot_box = VBoxContainer.new()
	_slot_box.add_theme_constant_override("separation", 8)
	refining.add_child(_slot_box)
	_total = Label.new()
	_total.modulate = Color(1, 1, 1, 0.7)
	refining.add_child(_total)
	var queue_title := Label.new()
	queue_title.text = "Queue  ·  press to return to the stash"
	refining.add_child(queue_title)
	_queue_list = _list(refining)
	var elements_panel := _panel(columns, "Elements")
	_elements = Label.new()
	_elements.add_theme_font_size_override("font_size", 22)
	elements_panel.add_child(_elements)

	_detail = Label.new()
	_detail.custom_minimum_size = Vector2(0, 28)
	_outline(_detail)
	root.add_child(_detail)
	var hint := Label.new()
	hint.text = "E / A: refine, return or stop    Esc / B: close"
	_outline(hint)
	root.add_child(hint)


func open() -> void:
	visible = true
	_rebuild()
	_focus_first()


func close() -> void:
	if not visible:
		return
	visible = false
	GameState.save_game()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _process(_delta: float) -> void:
	if not visible:
		return
	var r := GameState.refinery
	# A slot finishing changes the slots and queue, which needs a rebuild rather than a redraw.
	for i in r.slots.size():
		if _slot_signature(i) != _slot_labels[i].get_meta("signature", ""):
			_rebuild_keeping_focus()
			return
	for i in r.slots.size():
		_slot_bars[i].value = r.item_progress(i)
		_slot_labels[i].text = _slot_text(i)
	_total.text = "All done in %s" % _duration(r.total_time_left()) if not r.is_idle() else "Idle"
	if GameState.elements != _shown_elements:
		_show_elements()


func _rebuild() -> void:
	var r := GameState.refinery
	_clear(_stash_list)
	for i in GameState.truck_stash.size():
		var stack: Dictionary = GameState.truck_stash[i]
		_row(_stash_list, stack, _enqueue.bind(i))
	if GameState.truck_stash.is_empty():
		_empty(_stash_list, "Nothing unloaded yet")

	_clear(_slot_box)
	_slot_bars.clear()
	_slot_labels.clear()
	for i in r.slots.size():
		var s := r.slots[i]
		var b := _row(_slot_box, s, _cancel.bind(i))
		b.text = "Slot %d  ·  empty" % (i + 1) if s.is_empty() else "%s  ×%d" % [ItemCatalog.item_name(s.id), s.count]
		var bar := ProgressBar.new()
		bar.max_value = 1.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(ROW_SIZE.x, 10)
		_slot_box.add_child(bar)
		var label := Label.new()
		label.set_meta("signature", _slot_signature(i))
		_slot_box.add_child(label)
		_slot_bars.append(bar)
		_slot_labels.append(label)

	_clear(_queue_list)
	for i in r.queue.size():
		_row(_queue_list, r.queue[i], _dequeue.bind(i))
	if r.queue.is_empty():
		_empty(_queue_list, "Empty")
	_show_elements()
	_process(0.0)


func _show_elements() -> void:
	_shown_elements = GameState.elements.duplicate()
	var lines: Array[String] = []
	for element: String in ItemCatalog.ELEMENTS:
		lines.append("%s  %d" % [element.capitalize(), GameState.elements.get(element, 0)])
	_elements.text = "\n".join(lines)


func _enqueue(i: int) -> void:
	GameState.refinery.enqueue_from(GameState.truck_stash, i)
	_after_change(_stash_list, i)


func _dequeue(i: int) -> void:
	GameState.refinery.dequeue_to(GameState.truck_stash, i)
	_after_change(_queue_list, i)


func _cancel(i: int) -> void:
	GameState.refinery.cancel_slot(GameState.truck_stash, i)
	_after_change(_slot_box, i)


func _rebuild_keeping_focus() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	for list: Control in [_stash_list, _slot_box, _queue_list]:
		var buttons := list.get_children().filter(func(c: Node) -> bool: return c is Button)
		if focused in buttons:
			_after_change(list, buttons.find(focused))
			return
	_rebuild()


func _after_change(list: Control, index: int) -> void:
	_rebuild()
	var buttons := list.get_children().filter(func(c: Node) -> bool: return c is Button)
	if buttons.is_empty():
		_focus_first()
	else:
		(buttons[mini(index, buttons.size() - 1)] as Button).grab_focus()


func _focus_first() -> void:
	for list: Control in [_stash_list, _slot_box, _queue_list]:
		for c in list.get_children():
			if c is Button:
				c.grab_focus()
				return


## Changes whenever the slot starts on a different stack or count.
func _slot_signature(i: int) -> String:
	var s := GameState.refinery.slots[i]
	return "" if s.is_empty() else "%s:%d" % [s.id, s.count]


func _slot_text(i: int) -> String:
	var r := GameState.refinery
	var s := r.slots[i]
	if s.is_empty():
		return "Pick something from the stash"
	var next: float = ItemCatalog.refine_time(s.id) - s.elapsed
	return "Next in %s  ·  stack done in %s  ·  each gives %s" % [
		_duration(next), _duration(r.slot_time_left(i)), ItemCatalog.yield_text(s.id)]


static func _duration(seconds: float) -> String:
	var s := ceili(seconds)
	return "%ds" % s if s < 60 else "%dm %02ds" % [s / 60, s % 60]


func _panel(parent: Control, heading: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var label := Label.new()
	label.text = heading
	label.add_theme_font_size_override("font_size", 22)
	box.add_child(label)
	return box


func _list(parent: Control) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	parent.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	return list


func _row(list: Control, stack: Dictionary, action: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = ROW_SIZE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = "" if stack.is_empty() else "%s  ×%d" % [ItemCatalog.item_name(stack.id), stack.count]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.set_corner_radius_all(4)
	style.border_width_left = 6
	style.border_color = Color(1, 1, 1, 0.1) if stack.is_empty() else ItemCatalog.rarity_color(stack.id)
	style.content_margin_left = 14
	var focus := style.duplicate() as StyleBoxFlat
	focus.bg_color = Color(0.28, 0.28, 0.28, 0.95)
	b.add_theme_stylebox_override("normal", style)
	b.add_theme_stylebox_override("hover", focus)
	b.add_theme_stylebox_override("pressed", focus)
	b.add_theme_stylebox_override("focus", focus)
	b.pressed.connect(action)
	b.focus_entered.connect(func() -> void:
		_detail.text = "" if stack.is_empty() else ItemCatalog.describe(stack.id))
	list.add_child(b)
	return b


func _empty(list: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color(1, 1, 1, 0.5)
	list.add_child(label)


func _clear(list: Control) -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()


func _outline(label: Label) -> void:
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 6)
