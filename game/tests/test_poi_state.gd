extends TestCase


func test_round_trip() -> void:
	var state := PoiState.new()
	state.looted = {"crate_1": 12.5, "crate_4": 80.0}
	state.unlocked = {"door_b": true, "door_a": true}
	var back := PoiState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(back.looted, state.looted)
	assert_eq(back.unlocked, {"door_a": true, "door_b": true})


func test_skips_malformed_entries() -> void:
	var back := PoiState.from_dict({"looted": {"ok": 1.0, "bad": "x"}, "unlocked": ["d", 3, null]})
	assert_eq(back.looted, {"ok": 1.0})
	assert_eq(back.unlocked, {"d": true})
	assert_true(PoiState.from_dict("nonsense").is_empty())
	assert_true(PoiState.from_dict({"looted": [], "unlocked": {}}).is_empty())
