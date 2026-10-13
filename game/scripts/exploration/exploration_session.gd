class_name ExplorationSession
extends RefCounted

## One trip into a POI on foot. Loot, leftovers and unlocks stay pending until banked at the truck;
## a defeat discards them, which resets the POI to how it was at the last unload.

var poi_id: String
var poi_state: PoiState
var bag := Bag.new()
## Encounters fought since the last defeat (the placeholder battle loses the 3rd).
var encounters := 0

var _looted := {}
## Container id -> what's left in it, for containers opened or changed since the last unload.
var _contents := {}
var _unlocked := {}


func _init(id: String, state: PoiState) -> void:
	poi_id = id
	poi_state = state


func is_opened(container_id: String) -> bool:
	return poi_state.looted.has(container_id) or _looted.has(container_id)


## What's left in an opened container. Saves from before leftovers were kept recorded emptied
## containers without contents, so a missing entry means empty.
func contents(container_id: String) -> Array[Dictionary]:
	if _contents.has(container_id):
		return _contents[container_id]
	var banked: Array[Dictionary] = poi_state.contents.get(container_id, [] as Array[Dictionary])
	return banked


func is_emptied(container_id: String) -> bool:
	return is_opened(container_id) and contents(container_id).is_empty()


## Opens a container, filling it with `rolled` the first time, and returns its contents for the loot
## window to take from and drop into. Changes stay with this run until banked.
func open(container_id: String, rolled: Array[Dictionary], now: float) -> Array[Dictionary]:
	if not _contents.has(container_id):
		var start := contents(container_id) if is_opened(container_id) else rolled
		_contents[container_id] = start.duplicate(true)
		if not is_opened(container_id):
			_looted[container_id] = now
	return _contents[container_id]


func is_unlocked(door_id: String) -> bool:
	return poi_state.unlocked.has(door_id) or _unlocked.has(door_id)


func unlock(door_id: String) -> void:
	if not is_unlocked(door_id):
		_unlocked[door_id] = true


func has_unbanked_progress() -> bool:
	return not (bag.is_empty() and _looted.is_empty() and _contents.is_empty() and _unlocked.is_empty())


## Commits the run so far to the POI and hands back the bag's contents for the truck stash.
func bank() -> Array[Dictionary]:
	poi_state.looted.merge(_looted)
	poi_state.unlocked.merge(_unlocked)
	for id: String in _contents:
		var left: Array[Dictionary] = _contents[id]
		if left.is_empty():
			poi_state.contents.erase(id)
		else:
			poi_state.contents[id] = left.duplicate(true)
	_looted.clear()
	_contents.clear()
	_unlocked.clear()
	var unloaded := bag.items()
	bag.clear()
	return unloaded


func defeat() -> void:
	bag.clear()
	_looted.clear()
	_contents.clear()
	_unlocked.clear()
	encounters = 0
