class_name Biome
extends RefCounted

## Extend this per biome; generation code only reads these fields, so it stays biome-agnostic.

var id: String
var poi_chance: float = 0.5
var ground_color_a: Color
var ground_color_b: Color
## Each: {id, label, models: Array[String], scale: float, plaza_radius: float, weight: float}
var poi_types: Array[Dictionary] = []
## Each: {id, path, per_hectare: float, min_scale, max_scale, solid: bool, radius: float}
## `radius` is the footprint at scale 1, used for collision and spacing.
var props: Array[Dictionary] = []


func pick_poi_type(rng: RandomNumberGenerator) -> Dictionary:
	var total := 0.0
	for t in poi_types:
		total += t.weight
	var roll := rng.randf() * total
	for t in poi_types:
		roll -= t.weight
		if roll < 0.0:
			return t
	return poi_types.back()
