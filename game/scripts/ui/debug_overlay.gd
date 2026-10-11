class_name DebugOverlay
extends CanvasLayer

## Performance readout toggled with the toggle_debug action (F3 / gamepad Select).

const REFRESH := 0.25

var chunks: ChunkManager
var world_position := Callable()

var _label: Label
var _stats := FrameStats.new(120)
var _timer := 0.0


func _ready() -> void:
	layer = 50
	var panel := PanelContainer.new()
	# Below the compass, whose POI labels can stack three rows deep.
	panel.position = Vector2(8, 130)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(_label)
	add_child(panel)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		visible = not visible


func _process(delta: float) -> void:
	_stats.push(delta * 1000.0)
	_timer -= delta
	if not visible or _timer > 0.0:
		return
	_timer = REFRESH
	_label.text = describe()


func describe() -> String:
	var lines := [
		"FPS %d   frame %.1f ms avg / %.1f p99 / %.1f max" % [Engine.get_frames_per_second(),
			_stats.average(), _stats.percentile(0.99), _stats.worst()],
		"draw calls %d   triangles %dk" % [
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1000],
		"video memory %d MB" % (RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576),
		"preset %s (F4)   render scale %.2f" % [GraphicsSettings.preset_name, GraphicsSettings.get_value("render_scale")],
	]
	if chunks != null:
		lines.append("chunks: content %d   terrain %d" % [chunks.loaded_chunk_count(), chunks.loaded_terrain_count()])
	if world_position.is_valid():
		var p: Vector2 = world_position.call()
		lines.append("world (%.0f, %.0f)   origin (%.0f, %.0f)" % [p.x, p.y, GameState.origin.x, GameState.origin.z])
	return "\n".join(lines)
