class_name DroneScanner
extends Node3D

## The drone's always-on scan. A few times a second, every container and loot-room door that is on
## screen, within range and not behind a wall lights up; anything seen for the first time is
## recorded on the POI and reported so the minimap can ping it. Loot-room doors also get a door frame
## on their wall, since the buildings have no doors of their own.

signal first_seen(id: String)

const INTERVAL := 0.1
## Height above the ground the line of sight aims at.
const AIM_HEIGHT := 0.8
const DOOR_SIZE := Vector2(1.2, 2.1)
const HIGHLIGHT := preload("res://shaders/scan_highlight.gdshader")

var level: ExplorationLevel
var interactables: Array[Interactable] = []
var session: ExplorationSession
var explorer: Explorer
var camera: Camera3D
var chunks: ChunkManager
## Returns true for interactables with nothing left to find (emptied), which stop lighting up.
var is_done: Callable

var _timer := 0.0
var _overlay: ShaderMaterial
## Interactable id -> MeshInstance3Ds that light up.
var _meshes := {}
var _lit := {}
var _site: Node
var _heights := {}


func _ready() -> void:
	_overlay = ShaderMaterial.new()
	_overlay.shader = HIGHLIGHT
	for it in interactables:
		_heights[it.id] = chunks.terrain.height_at(it.position.x, it.position.y)
	for d in level.loot_rooms:
		_meshes[d.id] = _build_door_frame(d.position, d.normal, _heights[d.id])


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = INTERVAL
	_find_site()
	var space := explorer.get_world_3d().direct_space_state
	var p := explorer.global_position + GameState.origin
	var here := Vector2(p.x, p.z)
	var visible: Array[String] = []
	for it in interactables:
		if it.kind == Interactable.Kind.TRUCK:
			continue
		var on: bool = not is_done.call(it) and _sees(it, here, space)
		_light(it.id, on)
		if on:
			visible.append(it.id)
	for id in ScanRules.record(visible, session.poi_state.seen):
		first_seen.emit(id)


func _sees(it: Interactable, here: Vector2, space: PhysicsDirectSpaceState3D) -> bool:
	if not ScanRules.in_range(here, it.position):
		return false
	var eye := camera.global_position + GameState.origin
	var radius := maxf(it.radius, 0.6)
	for p in ScanRules.probe_points(it.position, it.radius, Vector2(eye.x, eye.z)):
		var aim := Vector3(p.x, _heights[it.id] + AIM_HEIGHT, p.y) - GameState.origin
		if not camera.is_position_in_frustum(aim):
			continue
		var query := PhysicsRayQueryParameters3D.create(camera.global_position, aim)
		query.exclude = [explorer.get_rid()]
		var hit := space.intersect_ray(query)
		var hit_at: Variant = null
		if not hit.is_empty():
			var h: Vector3 = hit.position + GameState.origin
			hit_at = Vector2(h.x, h.z)
		if ScanRules.unobstructed(hit_at, it.position, radius):
			return true
	return false


func _light(id: String, on: bool) -> void:
	if _lit.get(id, false) == on:
		return
	_lit[id] = on
	for mi: MeshInstance3D in _meshes.get(id, []):
		if is_instance_valid(mi):
			mi.material_overlay = _overlay if on else null


## The POI's compound streams in with its chunk (and can stream out and back), so its container
## meshes are looked up whenever the node changes.
func _find_site() -> void:
	if _site != null and is_instance_valid(_site):
		return
	_site = chunks.find_child("Poi_" + level.poi.id, true, false)
	if _site == null:
		return
	var by_index := {}
	for pivot in _site.get_children():
		if pivot.has_meta("layout_index"):
			by_index[pivot.get_meta("layout_index")] = pivot
	for c in level.containers:
		var pivot: Node = by_index.get(int((c.id as String).substr(1)))
		if pivot != null:
			var found: Array[MeshInstance3D] = []
			found.assign(pivot.find_children("*", "MeshInstance3D", true, false))
			_meshes[c.id] = found
	_lit.clear()


## A plain metal door in a frame, flush against the wall the door spot looks out from.
func _build_door_frame(spot: Vector2, normal: Vector2, ground: float) -> Array[MeshInstance3D]:
	var root := Node3D.new()
	var wall := spot - normal * (ExplorationLevel.BODY_RADIUS + 0.25)
	root.position = Vector3(wall.x, ground, wall.y) - GameState.origin
	root.rotation.y = atan2(normal.x, normal.y)
	add_child(root)
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.32, 0.3, 0.27)
	frame_mat.metallic = 0.5
	frame_mat.roughness = 0.6
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.42, 0.36, 0.28)
	door_mat.roughness = 0.8
	var out: Array[MeshInstance3D] = []
	var w := DOOR_SIZE.x
	var h := DOOR_SIZE.y
	out.append(_box(root, Vector3(0.12, h, 0.14), Vector3(-w * 0.5, h * 0.5, 0), frame_mat))
	out.append(_box(root, Vector3(0.12, h, 0.14), Vector3(w * 0.5, h * 0.5, 0), frame_mat))
	out.append(_box(root, Vector3(w + 0.12, 0.12, 0.14), Vector3(0, h, 0), frame_mat))
	out.append(_box(root, Vector3(w - 0.08, h - 0.06, 0.06), Vector3(0, (h - 0.06) * 0.5, -0.02), door_mat))
	return out


func _box(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = at
	parent.add_child(mi)
	return mi
