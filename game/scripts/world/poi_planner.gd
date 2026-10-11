class_name PoiPlanner
extends RefCounted

## Pure, thread-safe: turns a POI into the list of pieces to place, deterministically from the seed.

const SALT := 0x9A1
## Extra clearance beside a road lane, on top of the road half-width and the piece's radius.
const ROAD_LANE_MARGIN := 2.0
## Fraction of a ruined building's height that survives.
const RUIN_KEEP := Vector2(0.35, 0.75)
const RUBBLE_COUNT := Vector2i(2, 4)
## How far past the plaza edge a piece may reach after being nudged out of a road lane.
const MAX_OVERHANG := 4.0


## Returns [{key, position: Vector2 (world x/z), y: float (offset above the POI ground), yaw,
## ruin: float (0 = intact, else fraction of height kept)}].
## `road_dirs` are unit directions (x/z) of roads leaving the POI centre; pieces in those lanes are
## dropped so roads lead into the compound.
static func plan(world_seed: int, poi: PoiData, layouts: Array, ruin_chance: float,
		road_dirs: Array[Vector2]) -> Array[Dictionary]:
	var rng := WorldHash.rng_for(world_seed, poi.cell.x, poi.cell.y, SALT)
	var layout: Array = layouts[rng.randi() % layouts.size()]
	var mirror := rng.randf() < 0.5
	var origin := poi.position_2d()
	# Layouts are authored with their main street along local +x; point it down the first road so
	# that road runs through the compound instead of clearing a lane across it.
	var yaw := poi.yaw if road_dirs.is_empty() else -road_dirs[0].angle()
	var items: Array[Dictionary] = []
	var solids: Array[Dictionary] = []
	for slot: Dictionary in layout:
		# Roll every random value up front so a dropped slot doesn't shift the ones after it.
		var keep: bool = rng.randf() < slot.get("opt", 1.0)
		var choices: Variant = slot.m
		var key: String = choices if choices is String else choices[rng.randi() % choices.size()]
		var ruin_roll := rng.randf()
		var ruin_keep := rng.randf_range(RUIN_KEEP.x, RUIN_KEEP.y)
		var rubble_seed := rng.randi()
		if not keep:
			continue
		var local: Vector2 = slot.p
		var yaw_deg: float = slot.get("r", 0.0)
		if mirror:
			local.x = -local.x
			yaw_deg = -yaw_deg
		var piece := PoiCatalog.piece(key)
		var radius := PoiCatalog.radius(key)
		var pos := _clear_of_roads(origin + local.rotated(-yaw), radius, origin, road_dirs, poi.plaza_radius)
		if pos == Vector2.INF or (piece.solid and _overlaps(pos, key, solids)):
			continue
		var ruin := 0.0
		if piece.ruinable and ruin_roll < ruin_chance:
			ruin = ruin_keep
		var item := {"key": key, "position": pos, "y": slot.get("y", 0.0), "yaw": yaw + deg_to_rad(yaw_deg), "ruin": ruin}
		items.append(item)
		if piece.solid and item.y == 0.0:
			solids.append(item)
		if ruin > 0.0:
			items.append_array(_rubble(rubble_seed, item, origin, road_dirs, poi.plaza_radius))
	return items


## Pushes `pos` sideways out of any road lane it sits in. Returns Vector2.INF when it can't be
## cleared without leaving the plaza.
static func _clear_of_roads(pos: Vector2, radius: float, origin: Vector2, road_dirs: Array[Vector2],
		reach: float) -> Vector2:
	var clear := RoadNetwork.WIDTH * 0.5 + ROAD_LANE_MARGIN + radius
	for attempt in 3:
		var moved := false
		for dir in road_dirs:
			var lane_end := origin + dir * (reach + radius)
			var d := Geometry2DUtil.distance_to_segment(pos, origin, lane_end)
			if d >= clear:
				continue
			var side := dir.orthogonal()
			if side.dot(pos - origin) < 0.0:
				side = -side
			pos += side * (clear - d + 0.5)
			moved = true
		if not moved:
			break
	if in_road_lane(pos, radius, origin, road_dirs, reach) or pos.distance_to(origin) + radius > reach + MAX_OVERHANG:
		return Vector2.INF
	return pos


## Solid pieces may touch but not interpenetrate; footprints use their smaller half-extent so the
## check works at any rotation.
static func _overlaps(pos: Vector2, key: String, solids: Array[Dictionary]) -> bool:
	var size: Vector2 = PoiCatalog.piece(key).size
	var r := minf(size.x, size.y) * 0.5
	for other in solids:
		var o: Vector2 = PoiCatalog.piece(other.key).size
		if pos.distance_to(other.position) < r + minf(o.x, o.y) * 0.5 - 0.5:
			return true
	return false


static func in_road_lane(pos: Vector2, radius: float, origin: Vector2, road_dirs: Array[Vector2],
		reach: float) -> bool:
	var clear := RoadNetwork.WIDTH * 0.5 + ROAD_LANE_MARGIN + radius
	for dir in road_dirs:
		if Geometry2DUtil.distance_to_segment(pos, origin, origin + dir * (reach + radius)) < clear:
			return true
	return false


static func _rubble(seed_value: int, building: Dictionary, origin: Vector2, road_dirs: Array[Vector2],
		reach: float) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: Array[Dictionary] = []
	var size: Vector2 = PoiCatalog.piece(building.key).size
	for i in rng.randi_range(RUBBLE_COUNT.x, RUBBLE_COUNT.y):
		var key: String = PoiCatalog.RUBBLE[rng.randi() % PoiCatalog.RUBBLE.size()]
		# Just outside a random edge of the footprint, as if fallen from the walls.
		var side := Vector2.from_angle(rng.randf() * TAU)
		var offset := Vector2(side.x * (size.x * 0.5 + rng.randf_range(0.5, 2.5)),
			side.y * (size.y * 0.5 + rng.randf_range(0.5, 2.5)))
		var pos: Vector2 = building.position + offset.rotated(-building.yaw)
		var yaw := rng.randf() * TAU
		if pos.distance_to(origin) > reach or in_road_lane(pos, PoiCatalog.radius(key), origin, road_dirs, reach):
			continue
		out.append({"key": key, "position": pos, "y": 0.0, "yaw": yaw, "ruin": 0.0})
	return out


## Unit directions of roads that end at the POI.
static func road_directions(poi: PoiData, roads: Array) -> Array[Vector2]:
	var dirs: Array[Vector2] = []
	var p := poi.position_2d()
	for road: Dictionary in roads:
		var a: Vector2 = road.a
		var b: Vector2 = road.b
		if a.is_equal_approx(p):
			dirs.append((b - a).normalized())
		elif b.is_equal_approx(p):
			dirs.append((a - b).normalized())
	return dirs
