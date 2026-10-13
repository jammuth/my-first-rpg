class_name SaveGame
extends RefCounted

## Pure (de)serialisation of progress. Positions are world coordinates (not origin-shifted).
## Version 2 added exploration progress. Its keys are optional on load, so later additions don't
## need another version bump and version 1 saves still load.

const VERSION := 2
const READABLE_VERSIONS := [1, 2]


## progress (all optional): play_time: float, poi_states: {id: PoiState}, stash: Array[Dictionary],
## character: String, refinery: Dictionary (Refinery.to_dict()), elements: {element: int}.
static func to_json(world_seed: int, visited: Dictionary, truck_position: Vector2, truck_yaw: float,
		progress := {}) -> String:
	var ids: Array = visited.keys()
	ids.sort()
	var pois := {}
	var poi_states: Dictionary = progress.get("poi_states", {})
	for id: String in poi_states:
		var state: PoiState = poi_states[id]
		if not state.is_empty():
			pois[id] = state.to_dict()
	return JSON.stringify({
		"version": VERSION,
		"world_seed": world_seed,
		"visited": ids,
		"truck": {"x": truck_position.x, "z": truck_position.y, "yaw": truck_yaw},
		"play_time": float(progress.get("play_time", 0.0)),
		"pois": pois,
		"stash": progress.get("stash", []),
		"character": String(progress.get("character", "")),
		"refinery": progress.get("refinery", {}),
		"elements": progress.get("elements", {}),
	}, "\t")


## Returns {world_seed, visited: Dictionary, truck_position: Vector2, truck_yaw, play_time: float,
## poi_states: {id: PoiState}, stash: Array[Dictionary], character: String ("" if absent),
## refinery: Variant (raw, for Refinery.from_dict), elements: {element: int}} or {} when
## the text isn't a save this version understands (callers then start a fresh game).
static func from_json(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var data: Variant = json.data
	if not data is Dictionary or not data.get("version") is float:
		return {}
	# JSON numbers arrive as floats, and Array.has() won't match them against int versions.
	if not int(data.version) in READABLE_VERSIONS:
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
	var play_time: Variant = data.get("play_time")
	var poi_states := {}
	var pois: Variant = data.get("pois")
	if pois is Dictionary:
		for id: Variant in pois:
			if id is String:
				poi_states[id] = PoiState.from_dict(pois[id])
	return {
		"world_seed": int(data.world_seed),
		"visited": visited,
		"truck_position": Vector2(truck.x, truck.z),
		"truck_yaw": float(truck.yaw),
		"play_time": play_time if play_time is float and play_time >= 0.0 else 0.0,
		"poi_states": poi_states,
		"stash": ItemStacks.read(data.get("stash")),
		"character": data.character if data.get("character") is String else "",
		"refinery": data.get("refinery", {}),
		"elements": _read_elements(data.get("elements")),
	}


static func _read_elements(data: Variant) -> Dictionary:
	var out := {}
	if data is Dictionary:
		for element: Variant in data:
			if element is String and (data[element] is float or data[element] is int) and data[element] >= 0:
				out[element] = int(data[element])
	return out
