class_name DesertBiome
extends Biome

const MODELS := "res://assets/models/"


func _init() -> void:
	id = "desert"
	poi_chance = 0.6
	ground_color_a = Color(0.85, 0.71, 0.49)
	ground_color_b = Color(0.77, 0.60, 0.40)
	terrain_swell = Vector2(14.0, 1400.0)
	terrain_dunes = Vector2(8.0, 380.0)
	terrain_ridges = Vector2(3.0, 150.0)
	mesa_threshold = 0.38
	mesa_heights = Vector2(22.0, 14.0)
	poi_types = [
		{"id": "scrapyard", "label": "Scrapyard", "weight": 3.0, "scale": 9.0, "plaza_radius": 22.0,
			"models": [MODELS + "industrial/building-a.glb", MODELS + "industrial/building-o.glb"]},
		{"id": "factory", "label": "Factory", "weight": 2.0, "scale": 10.0, "plaza_radius": 20.0,
			"models": [MODELS + "industrial/building-d.glb", MODELS + "industrial/building-k.glb"]},
		{"id": "settlement", "label": "Settlement", "weight": 2.0, "scale": 10.0, "plaza_radius": 18.0,
			"models": [MODELS + "commercial/building-a.glb", MODELS + "commercial/building-c.glb",
				MODELS + "commercial/building-f.glb"]},
		{"id": "homestead", "label": "Homestead", "weight": 2.0, "scale": 9.0, "plaza_radius": 18.0,
			"models": [MODELS + "suburban/building-type-a.glb", MODELS + "suburban/building-type-c.glb",
				MODELS + "suburban/building-type-h.glb"]},
		{"id": "water_tower", "label": "Water Tower", "weight": 1.0, "scale": 9.0, "plaza_radius": 14.0,
			"models": [MODELS + "industrial/water-tower.glb"]},
	]
	props = [
		{"id": "scrub", "path": MODELS + "props/Bush_1_A_Color3.gltf", "per_hectare": 8.0,
			"min_scale": 6.0, "max_scale": 10.0, "solid": false, "radius": 0.13},
		{"id": "scrub_dry", "path": MODELS + "props/Bush_2_A_Color5.gltf", "per_hectare": 4.0,
			"min_scale": 3.0, "max_scale": 4.5, "solid": false, "radius": 0.26},
		{"id": "dead_tree", "path": MODELS + "props/tree_dead_small.gltf", "per_hectare": 1.5,
			"min_scale": 2.0, "max_scale": 2.6, "solid": false, "radius": 0.5},
		{"id": "boulder_small", "path": MODELS + "rocks/boulder_05.res", "per_hectare": 5.0,
			"min_scale": 1.5, "max_scale": 3.0, "solid": true, "radius": 0.5, "sink": 0.08},
		{"id": "boulder_flat", "path": MODELS + "rocks/boulder_02.res", "per_hectare": 2.5,
			"min_scale": 1.0, "max_scale": 2.0, "solid": true, "radius": 0.9, "sink": 0.1},
		{"id": "boulder_large", "path": MODELS + "rocks/boulder_04.res", "per_hectare": 1.2,
			"min_scale": 1.0, "max_scale": 2.2, "solid": true, "radius": 1.1, "sink": 0.15},
		{"id": "tire", "path": MODELS + "debris/debris-tire.glb", "per_hectare": 1.0,
			"min_scale": 2.5, "max_scale": 3.0, "solid": false, "radius": 0.3},
		{"id": "door", "path": MODELS + "debris/debris-door.glb", "per_hectare": 1.0,
			"min_scale": 2.5, "max_scale": 3.0, "solid": false, "radius": 0.4},
		{"id": "plate", "path": MODELS + "debris/debris-plate-a.glb", "per_hectare": 1.0,
			"min_scale": 2.5, "max_scale": 3.0, "solid": false, "radius": 0.45},
	]
