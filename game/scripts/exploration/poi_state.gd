class_name PoiState
extends RefCounted

## Banked progress in one POI. A run's unbanked changes live in ExplorationSession until the player
## unloads at the truck, so a defeat can throw them away without touching this.

## container id -> play time (s) when it was first opened, so a later refill rule can age entries out.
var looted: Dictionary = {}
## container id -> stacks left behind in it. Opened containers without an entry are empty.
var contents: Dictionary = {}
var unlocked: Dictionary = {}


func is_empty() -> bool:
	return looted.is_empty() and contents.is_empty() and unlocked.is_empty()


func to_dict() -> Dictionary:
	var doors: Array = unlocked.keys()
	doors.sort()
	return {"looted": looted.duplicate(), "contents": contents.duplicate(true), "unlocked": doors}


## Skips malformed entries rather than rejecting the whole POI.
static func from_dict(data: Variant) -> PoiState:
	var state := PoiState.new()
	if not data is Dictionary:
		return state
	var looted_data: Variant = data.get("looted")
	if looted_data is Dictionary:
		for id: Variant in looted_data:
			if id is String and looted_data[id] is float:
				state.looted[id] = looted_data[id]
	var contents_data: Variant = data.get("contents")
	if contents_data is Dictionary:
		for id: Variant in contents_data:
			var stacks := ItemStacks.read(contents_data[id])
			if id is String and state.looted.has(id) and not stacks.is_empty():
				state.contents[id] = stacks
	var unlocked_data: Variant = data.get("unlocked")
	if unlocked_data is Array:
		for id: Variant in unlocked_data:
			if id is String:
				state.unlocked[id] = true
	return state
