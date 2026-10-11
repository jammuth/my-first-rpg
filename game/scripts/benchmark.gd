class_name Benchmark
extends Node

## `-- --benchmark`: drives a fixed route from a fresh game for DURATION seconds, then prints and
## saves frame-time stats (user://benchmark-<preset>-<time>.txt) and quits. Vsync is off so the
## numbers show real headroom.

const WARMUP := 3.0
const DURATION := 60.0
## Seconds between deliberate turns, so the route crosses many chunks and some POIs.
const TURN_EVERY := 9.0
const TURN_FOR := 0.6

var truck: Truck
var overlay: DebugOverlay

var _elapsed := 0.0
var _stats := FrameStats.new(0)
var _max_draw_calls := 0
var _max_triangles := 0
var _distance := 0.0
var _last_position := Vector3.ZERO


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	overlay.visible = true
	_last_position = truck.global_position
	Input.action_press("move_forward")


func _process(delta: float) -> void:
	_elapsed += delta
	var turning := fmod(_elapsed, TURN_EVERY) < TURN_FOR or absf(truck.speed) < 2.0
	if turning:
		Input.action_press("turn_left")
	else:
		Input.action_release("turn_left")
	if _elapsed < WARMUP:
		_last_position = truck.global_position
		return
	_stats.push(delta * 1000.0)
	_max_draw_calls = maxi(_max_draw_calls, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	_max_triangles = maxi(_max_triangles, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	var p := truck.global_position
	if p.distance_to(_last_position) < 50.0:  # ignore origin-shift jumps
		_distance += p.distance_to(_last_position)
	_last_position = p
	if _elapsed >= WARMUP + DURATION:
		_finish()


func _finish() -> void:
	set_process(false)
	Input.action_release("move_forward")
	Input.action_release("turn_left")
	var report := "\n".join([
		"benchmark  preset=%s  render_scale=%.2f" % [GraphicsSettings.preset_name, GraphicsSettings.get_value("render_scale")],
		"gpu: %s" % RenderingServer.get_video_adapter_name(),
		"cpu: %s" % OS.get_processor_name(),
		"frames %d over %.0f s, drove %.0f m" % [_stats.count(), DURATION, _distance],
		"frame ms: avg %.2f  p50 %.2f  p99 %.2f  max %.2f" % [_stats.average(), _stats.percentile(0.5),
			_stats.percentile(0.99), _stats.worst()],
		"avg fps %.0f   peak draw calls %d   peak triangles %dk" % [1000.0 / maxf(_stats.average(), 0.001),
			_max_draw_calls, _max_triangles / 1000],
		"frames over 16.7 ms (missed 60 fps): %d   over 33.3 ms: %d" % [_stats.count_over(16.7), _stats.count_over(33.3)],
	])
	print(report)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "user://benchmark-%s-%s.txt" % [GraphicsSettings.preset_name, stamp]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(report + "\n")
		print("saved ", ProjectSettings.globalize_path(path))
	get_tree().quit()
