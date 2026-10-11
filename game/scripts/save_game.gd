class_name SaveGame
extends RefCounted

## Pure (de)serialisation of progress. Positions are world coordinates (not origin-shifted).

const VERSION := 1


static func to_json(world_seed: int, visited: Dictionary, truck_position: Vector2, truck_yaw: float) -> String:
	var ids: Array = visited.keys()
	ids.sort()
	return JSON.stringify({
		"version": VERSION,
		"world_seed": world_seed,
		"visited": ids,
		"truck": {"x": truck_position.x, "z": truck_position.y, "yaw": truck_yaw},
	}, "\t")


## Returns {world_seed, visited: Dictionary, truck_position: Vector2, truck_yaw} or {} when the
## text isn't a save this version understands (callers then start a fresh game).
static func from_json(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var data: Variant = json.data
	if not data is Dictionary or data.get("version") != VERSION:
		return {}
	if not (data.get("world_seed") is float and data.get("visited") is Array and data.get("truck") is Dictionary):
		return {}
	var truck: Dictionary = data.truck
	if not (truck.get("x") is float and truck.get("z") is float and truck.get("yaw") is float):
		return {}
	var visited := {}
	for id: Variant in data.visited:
		if id is String:
			visited[id] = true
	return {
		"world_seed": int(data.world_seed),
		"visited": visited,
		"truck_position": Vector2(truck.x, truck.z),
		"truck_yaw": float(truck.yaw),
	}
