extends TestCase

const GS := preload("res://scripts/graphics_settings.gd")


func test_detects_steam_deck() -> void:
	assert_eq(GS.detect_preset("1", "", ""), "deck", "Steam env var")
	assert_eq(GS.detect_preset("", "AMD Custom GPU 0405 (RADV VANGOGH)", ""), "deck", "LCD Deck GPU")
	assert_eq(GS.detect_preset("", "", "AMD Custom APU 0932"), "deck", "OLED Deck CPU")
	assert_eq(GS.detect_preset("", "NVIDIA GeForce RTX 4060 Laptop GPU", "AMD Ryzen 7"), "high")
	assert_eq(GS.detect_preset("0", "", ""), "high")


func test_deck_preset_is_cheaper_everywhere() -> void:
	var high: Dictionary = GS.PRESETS.high
	var deck: Dictionary = GS.PRESETS.deck
	assert_eq(high.keys(), deck.keys(), "presets define the same settings")
	for key: String in ["render_scale", "shadow_distance", "shadow_atlas", "terrain_radius", "view_distance",
			"prop_density", "prop_view_scale", "particles"]:
		assert_true(deck[key] <= high[key], key)


func test_view_distance_covered_by_terrain() -> void:
	for name: String in GS.PRESETS:
		var p: Dictionary = GS.PRESETS[name]
		# Fog must end before streamed terrain does (nearest edge is terrain_radius chunks away).
		assert_true(p.view_distance <= p.terrain_radius * ChunkGenerator.CHUNK_SIZE, name)


func test_keep_prop_is_deterministic_and_matches_density() -> void:
	var kept := 0
	for i in 2000:
		var pos := Vector3(i * 3.7, 0, i * -1.3)
		assert_eq(GS.keep_prop(pos, 0.65), GS.keep_prop(pos, 0.65))
		if GS.keep_prop(pos, 0.65):
			kept += 1
	assert_true(kept > 1150 and kept < 1450, "kept %d of 2000 at 0.65" % kept)
	assert_true(GS.keep_prop(Vector3(5, 0, 5), 1.0))
