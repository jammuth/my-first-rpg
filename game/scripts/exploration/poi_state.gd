class_name PoiState
extends RefCounted

## Banked progress in one POI. A run's unbanked changes live in ExplorationSession until the player
## unloads at the truck, so a defeat can throw them away without touching this.

## container id -> play time (s) when it was looted, so a later refill rule can age entries out.
var looted: Dictionary = {}
var unlocked: Dictionary = {}


func is_empty() -> bool:
	return looted.is_empty() and unlocked.is_empty()


func to_dict() -> Dictionary:
	var doors: Array = unlocked.keys()
	doors.sort()
	return {"looted": looted.duplicate(), "unlocked": doors}


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
	var unlocked_data: Variant = data.get("unlocked")
	if unlocked_data is Array:
		for id: Variant in unlocked_data:
			if id is String:
				state.unlocked[id] = true
	return state
