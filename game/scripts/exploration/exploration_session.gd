class_name ExplorationSession
extends RefCounted

## One trip into a POI on foot. Loot and unlocks stay pending until banked at the truck; a defeat
## discards them, which resets the POI to how it was at the last unload.

var poi_id: String
var poi_state: PoiState
var bag: Array[Dictionary] = []
## Encounters fought since the last defeat (the placeholder battle loses the 3rd).
var encounters := 0

var _looted := {}
var _unlocked := {}


func _init(id: String, state: PoiState) -> void:
	poi_id = id
	poi_state = state


func is_looted(container_id: String) -> bool:
	return poi_state.looted.has(container_id) or _looted.has(container_id)


## Returns false (and takes nothing) if the container was already emptied.
func loot(container_id: String, items: Array[Dictionary], now: float) -> bool:
	if is_looted(container_id):
		return false
	_looted[container_id] = now
	ItemStacks.merge(bag, items)
	return true


func is_unlocked(door_id: String) -> bool:
	return poi_state.unlocked.has(door_id) or _unlocked.has(door_id)


func unlock(door_id: String) -> void:
	if not is_unlocked(door_id):
		_unlocked[door_id] = true


func has_unbanked_progress() -> bool:
	return not (bag.is_empty() and _looted.is_empty() and _unlocked.is_empty())


## Commits the run so far to the POI and hands back the bag's contents for the truck stash.
func bank() -> Array[Dictionary]:
	poi_state.looted.merge(_looted)
	poi_state.unlocked.merge(_unlocked)
	_looted.clear()
	_unlocked.clear()
	var unloaded := bag
	bag = []
	return unloaded


func defeat() -> void:
	bag.clear()
	_looted.clear()
	_unlocked.clear()
	encounters = 0
