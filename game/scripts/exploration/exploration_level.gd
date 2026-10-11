class_name ExplorationLevel
extends RefCounted

## Pure, deterministic description of a POI as a level on foot: where the explorer starts beside
## the parked truck, how far they may roam, and which spots can be searched or unlocked. Positions
## are world x/z. The scene builds the visuals from the same chunk data as the overworld.

const SALT := 0xE7A
## Explorer capsule radius plus a little slack, used when testing spots against footprints.
const BODY_RADIUS := 0.6
const GRID_STEP := 1.0
const EXTRACTION_RADIUS := 5.0
## How far past the plaza (and the parked truck) the explorer may wander.
const BOUNDARY_MARGIN := 28.0
const TRUCK_MARGIN := 14.0
## A truck further than this past the plaza can't have entered from the overworld prompt.
const MAX_PARK_DISTANCE := PoiGenerator.INTERACT_MARGIN + 20.0
## Spawn offsets beside the truck, in the truck's frame (x right, y forward), best first.
const SPAWN_OFFSETS: Array[Vector2] = [Vector2(3.0, 1.0), Vector2(-3.0, 1.0), Vector2(0.0, -6.0), Vector2(0.0, 6.0)]
## Layout pieces worth searching, by kind.
const SEARCHABLE := {
	"barrel": "barrel",
	"trash": "trash", "trash_pile": "trash",
	"pallet": "crate", "container_green": "crate", "container_red": "crate",
	"couch": "furniture",
	"pickup": "wreck", "pickup_armored": "wreck", "sports": "wreck", "van": "wreck", "van_armored": "wreck",
}
## Locked loot rooms per POI type (capped by the buildings available).
const LOOT_ROOMS := {"settlement": 3, "factory": 2, "homestead": 2, "scrapyard": 1, "water_tower": 1}
## Searching or unlocking works from this far outside a spot's footprint.
const REACH := 1.2

var poi: PoiData
var truck_position: Vector2
var truck_yaw: float
var spawn: Vector2
## Yaw of the truck's heading; the explorer starts facing the same way.
var spawn_yaw: float
var boundary_center: Vector2
var boundary_radius: float
## [{id, kind, key, position: Vector2, reach: float}] — position is the piece's centre.
var containers: Array[Dictionary] = []
## [{id, key, position: Vector2 (door spot just outside the face), normal: Vector2, building: Vector2}]
var loot_rooms: Array[Dictionary] = []
## Oriented footprints of solid ground-level pieces: [{center: Vector2, half: Vector2, yaw: float}].
var footprints: Array[Dictionary] = []


## `poi` must have its layout planned (see poi_with_layout). The truck is where the player parked.
static func build(world_seed: int, poi: PoiData, truck_pos: Vector2, truck_heading: float) -> ExplorationLevel:
	var level := ExplorationLevel.new()
	level.poi = poi
	level.truck_position = truck_pos
	level.truck_yaw = truck_heading
	level.boundary_center = poi.position_2d()
	level.boundary_radius = maxf(poi.plaza_radius + BOUNDARY_MARGIN,
		truck_pos.distance_to(poi.position_2d()) + TRUCK_MARGIN)
	level.footprints = footprints_of(poi.layout)
	level.footprints.append({"center": truck_pos, "half": Vector2(1.5, 3.25), "yaw": truck_heading})
	level._place_spawn()
	var reachable := level.reachable_grid()
	level._find_containers(reachable)
	level._find_loot_rooms(world_seed, reachable)
	return level


## The POI as the overworld plans it, with layout and ground height filled in.
static func poi_with_layout(world_seed: int, poi_id: String) -> PoiData:
	var parts := poi_id.split("_")
	var cell := Vector2i(int(parts[0]), int(parts[1]))
	var base := PoiGenerator.poi_for_cell(world_seed, cell)
	if base == null:
		return null
	var chunk := ChunkMath.world_to_cell(base.position, ChunkGenerator.CHUNK_SIZE)
	for poi in ChunkGenerator.generate(world_seed, chunk).pois:
		if poi.id == poi_id:
			return poi
	return null


## Where the truck goes: where the player parked, unless that's implausibly far from the site, in
## which case it's parked at the plaza edge facing the centre on the first clear spot.
## Returns [position: Vector2, yaw: float].
static func parking(poi: PoiData, truck_pos: Variant, truck_heading: float) -> Array:
	if truck_pos is Vector2 and truck_pos.distance_to(poi.position_2d()) <= poi.plaza_radius + MAX_PARK_DISTANCE:
		return [truck_pos, truck_heading]
	var solids := footprints_of(poi.layout)
	for i in 16:
		var dir := Vector2.from_angle(poi.yaw + i * TAU / 16.0)
		var pos := poi.position_2d() + dir * (poi.plaza_radius + 4.0)
		if not blocked(pos, solids, 3.5):
			return [pos, atan2(dir.x, dir.y)]
	return [poi.position_2d() + Vector2(poi.plaza_radius + 12.0, 0.0), 0.0]


static func footprints_of(layout: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in layout:
		var piece := PoiCatalog.piece(item.key)
		if piece.solid and item.y == 0.0:
			out.append({"center": item.position, "half": (piece.size as Vector2) * 0.5, "yaw": item.yaw})
	return out


## True when a body of `radius` at `p` would overlap a footprint.
static func blocked(p: Vector2, footprints: Array[Dictionary], radius: float) -> bool:
	for f in footprints:
		var local: Vector2 = (p - f.center).rotated(f.yaw)
		var half: Vector2 = f.half
		if absf(local.x) < half.x + radius and absf(local.y) < half.y + radius:
			return true
	return false


func inside_boundary(p: Vector2) -> bool:
	return p.distance_to(boundary_center) <= boundary_radius


## Pulls a point back inside the boundary circle.
func clamp_to_boundary(p: Vector2) -> Vector2:
	var offset := p - boundary_center
	if offset.length() <= boundary_radius:
		return p
	return boundary_center + offset.normalized() * boundary_radius


func in_extraction_zone(p: Vector2) -> bool:
	return p.distance_to(truck_position) <= EXTRACTION_RADIUS


## Grid cells (Vector2i, GRID_STEP metres, relative to boundary_center) walkable from the spawn.
func reachable_grid() -> Dictionary:
	var seen := {}
	var start := _to_cell(spawn)
	if blocked(spawn, footprints, BODY_RADIUS):
		return seen
	var queue: Array[Vector2i] = [start]
	seen[start] = true
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in dirs:
			var n := c + d
			if seen.has(n):
				continue
			var p := _to_point(n)
			if not inside_boundary(p) or blocked(p, footprints, BODY_RADIUS):
				continue
			seen[n] = true
			queue.append(n)
	return seen


## True when some reachable cell lies within `reach` of `p`.
func can_reach(p: Vector2, reach: float, reachable: Dictionary) -> bool:
	var c := _to_cell(p)
	var span := ceili(reach / GRID_STEP)
	for dx in range(-span, span + 1):
		for dy in range(-span, span + 1):
			var n := c + Vector2i(dx, dy)
			if reachable.has(n) and _to_point(n).distance_to(p) <= reach:
				return true
	return false


func _to_cell(p: Vector2) -> Vector2i:
	return Vector2i(((p - boundary_center) / GRID_STEP).round())


func _to_point(c: Vector2i) -> Vector2:
	return boundary_center + Vector2(c) * GRID_STEP


func _place_spawn() -> void:
	spawn_yaw = truck_yaw
	# The truck faces -Z at yaw 0, so its right is +X and forward -Z.
	var right := Vector2(cos(truck_yaw), -sin(truck_yaw))
	var forward := Vector2(-sin(truck_yaw), -cos(truck_yaw))
	for offset in SPAWN_OFFSETS:
		var p := truck_position + right * offset.x + forward * offset.y
		if inside_boundary(p) and not blocked(p, footprints, BODY_RADIUS):
			spawn = p
			return
	spawn = truck_position + right * SPAWN_OFFSETS[0].x


func _find_containers(reachable: Dictionary) -> void:
	for i in poi.layout.size():
		var item: Dictionary = poi.layout[i]
		if not SEARCHABLE.has(item.key) or item.y != 0.0:
			continue
		var reach := PoiCatalog.radius(item.key) + REACH
		if not can_reach(item.position, reach, reachable):
			continue
		containers.append({"id": "c%d" % i, "kind": SEARCHABLE[item.key], "key": item.key,
			"position": item.position, "reach": reach})


func _find_loot_rooms(world_seed: int, reachable: Dictionary) -> void:
	var rng := WorldHash.rng_for(world_seed, poi.cell.x, poi.cell.y, SALT)
	var candidates: Array[Dictionary] = []
	for i in poi.layout.size():
		var item: Dictionary = poi.layout[i]
		var piece := PoiCatalog.piece(item.key)
		if not (piece.solid and piece.ruinable and item.y == 0.0):
			continue
		var door := _door_for(item)
		if not door.is_empty():
			door.id = "d%d" % i
			candidates.append(door)
	# Shuffle deterministically, then keep the first N reachable ones.
	for i in range(candidates.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	var wanted: int = LOOT_ROOMS.get(poi.type_id, 1)
	for door in candidates:
		if loot_rooms.size() >= wanted:
			break
		if can_reach(door.position, REACH, reachable):
			loot_rooms.append(door)


## The door goes on the face that looks most toward the POI centre (the street side), falling
## back to the other faces when that one is hemmed in.
func _door_for(item: Dictionary) -> Dictionary:
	var half: Vector2 = (PoiCatalog.piece(item.key).size as Vector2) * 0.5
	var centre: Vector2 = item.position
	var faces: Array[Dictionary] = []
	for n: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var world_n := n.rotated(-item.yaw)
		var depth := absf(n.x) * half.x + absf(n.y) * half.y
		var spot: Vector2 = centre + world_n * (depth + BODY_RADIUS + 0.3)
		faces.append({"normal": world_n, "spot": spot, "score": world_n.dot((boundary_center - centre).normalized())})
	faces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	for face in faces:
		if inside_boundary(face.spot) and not blocked(face.spot, footprints, BODY_RADIUS * 0.5):
			return {"key": item.key, "position": face.spot, "normal": face.normal, "building": centre}
	return {}
