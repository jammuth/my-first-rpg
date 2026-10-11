class_name Biome
extends RefCounted

## Extend this per biome; generation code only reads these fields, so it stays biome-agnostic.

var id: String
var poi_chance: float = 0.5
var ground_color_a: Color
var ground_color_b: Color
## Terrain layers as [amplitude_m, wavelength_m]; heights are summed.
var terrain_swell := Vector2(0.0, 1.0)
var terrain_dunes := Vector2(0.0, 1.0)
## Ridged noise for sharper dune crests.
var terrain_ridges := Vector2(0.0, 1.0)
## Mesas: where a low-frequency mask passes `mesa_threshold`, the ground steps up by
## mesa_heights.x (and by mesa_heights.y more past threshold + mesa_tier_gap). 0 heights = none.
var mesa_wavelength := 700.0
var mesa_threshold := 1.0
var mesa_tier_gap := 0.14
## Mask range over which a cliff rises; smaller = steeper.
var mesa_edge_band := 0.035
var mesa_heights := Vector2.ZERO
## Amplitude of high-frequency mask noise that makes cliff outlines jagged.
var mesa_jaggedness := 0.03
## Each: {id, label, weight, plaza_radius, ruin_chance}; the compound comes from poi_layouts[id].
var poi_types: Array[Dictionary] = []
## POI type id -> Array of layouts (see DesertPoiLayouts for the slot format).
var poi_layouts: Dictionary = {}
## Each: {id, path, per_hectare: float, min_scale, max_scale, solid: bool, radius: float}
## `radius` is the footprint at scale 1, used for collision and spacing. Optional `sink` (metres
## at scale 1) buries the base so props don't float on the downhill side of slopes. Optional
## `view_distance` overrides how far away the prop is still drawn.
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
