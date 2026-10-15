class_name Minimap
extends Control

## Round corner minimap that turns with the camera. It shows the buildings, the truck (kept on the
## rim when out of range) and the explorer, plus a pin for every container and loot-room door the
## drone has seen. Each one pings the first time it's seen. Emptied ones go grey.

const RADIUS := 105.0
## Pixels per metre.
const SCALE := 1.6
const PING_TIME := 1.6
const BG := Color(0.05, 0.05, 0.05, 0.6)
const RIM := Color(1, 1, 1, 0.35)
const BUILDING := Color(0.7, 0.66, 0.6, 0.55)
const CONTAINER := Color(1.0, 0.82, 0.35)
const DOOR := Color(0.35, 0.95, 1.0)
const DONE := Color(0.55, 0.55, 0.55, 0.7)
const TRUCK := Color(0.45, 0.85, 0.5)
const YOU := Color(1, 1, 1)

var level: ExplorationLevel
var interactables: Array[Interactable] = []
var session: ExplorationSession
var is_done: Callable
## Set each frame by the scene.
var explorer_position := Vector2.ZERO
var explorer_facing := Vector2(0, -1)
var camera_yaw := 0.0

## Interactable id -> seconds left on its ping.
var _pings := {}


func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS, RADIUS) * 2.0
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_right = -20.0
	offset_left = offset_right - custom_minimum_size.x
	offset_top = 20.0
	offset_bottom = offset_top + custom_minimum_size.y
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func ping(id: String) -> void:
	_pings[id] = PING_TIME


func _process(delta: float) -> void:
	for id: String in _pings.keys():
		_pings[id] -= delta
		if _pings[id] <= 0.0:
			_pings.erase(id)
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	draw_circle(c, RADIUS, BG)
	for f in level.footprints:
		_draw_footprint(c, f)
	var truck := MinimapMath.clamp_to_radius(_map(level.truck_position), RADIUS - 7.0)
	draw_rect(Rect2(c + truck - Vector2(6, 6), Vector2(12, 12)), TRUCK)
	for it in interactables:
		if it.kind == Interactable.Kind.TRUCK or not session.poi_state.seen.has(it.id):
			continue
		var p := _map(it.position)
		if p.length() > RADIUS - 4.0:
			continue
		var color := DONE if is_done.call(it) else (DOOR if it.kind == Interactable.Kind.DOOR else CONTAINER)
		if it.kind == Interactable.Kind.DOOR:
			draw_rect(Rect2(c + p - Vector2(4, 5), Vector2(8, 10)), color)
		else:
			draw_circle(c + p, 4.5, color)
		if _pings.has(it.id):
			var t: float = 1.0 - _pings[it.id] / PING_TIME
			draw_arc(c + p, 6.0 + t * 22.0, 0.0, TAU, 32, Color(color, 1.0 - t), 2.5)
	# The map turns so the camera looks up; the arrow shows which way the explorer faces within that.
	var dir := explorer_facing.rotated(camera_yaw)
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([c + dir * 9.0, c - dir * 6.0 + side * 6.0, c - dir * 6.0 - side * 6.0]), YOU)
	draw_arc(c, RADIUS, 0.0, TAU, 64, RIM, 2.0)


func _map(world: Vector2) -> Vector2:
	return MinimapMath.to_map(world, explorer_position, camera_yaw, SCALE)


## Buildings poking past the rim are squashed onto it rather than clipped.
func _draw_footprint(c: Vector2, f: Dictionary) -> void:
	var half: Vector2 = f.half
	var points := PackedVector2Array()
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var world: Vector2 = f.center + (corner * half).rotated(-f.yaw)
		var p := _map(world)
		if p.length() > RADIUS * 1.6:
			return
		points.append(c + MinimapMath.clamp_to_radius(p, RADIUS - 1.0))
	draw_colored_polygon(points, BUILDING)
