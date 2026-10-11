extends Node

const DEFAULT_SEED := 1337

var world_seed: int = DEFAULT_SEED
var visited_pois: Dictionary = {}


func mark_visited(poi_id: String) -> void:
	visited_pois[poi_id] = true


func is_visited(poi_id: String) -> bool:
	return visited_pois.has(poi_id)
