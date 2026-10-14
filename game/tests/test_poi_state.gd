extends TestCase


func test_round_trip() -> void:
	var state := PoiState.new()
	state.looted = {"crate_1": 12.5, "crate_4": 80.0}
	state.unlocked = {"door_b": true, "door_a": true}
	state.contents = {"crate_4": [{"id": "battery", "count": 2}] as Array[Dictionary]}
	state.seen = {"crate_4": true, "door_a": true}
	var back := PoiState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(back.seen, state.seen)
	assert_eq(back.looted, state.looted)
	assert_eq(back.contents, state.contents)
	assert_eq(back.unlocked, {"door_a": true, "door_b": true})


func test_skips_malformed_entries() -> void:
	var back := PoiState.from_dict({"looted": {"ok": 1.0, "bad": "x"}, "unlocked": ["d", 3, null]})
	assert_eq(back.looted, {"ok": 1.0})
	assert_eq(back.unlocked, {"d": true})
	assert_true(PoiState.from_dict("nonsense").is_empty())
	assert_true(PoiState.from_dict({"looted": [], "unlocked": {}}).is_empty())


func test_contents_need_an_opened_container_and_valid_stacks() -> void:
	var back := PoiState.from_dict({"looted": {"c1": 1.0, "c2": 2.0}, "contents": {
		"c1": [{"id": "wiring", "count": 2}, {"id": 5, "count": 1}],
		"c2": [],
		"never_opened": [{"id": "wiring", "count": 1}],
		"c3": "junk"}})
	assert_eq(back.contents, {"c1": [{"id": "wiring", "count": 2}] as Array[Dictionary]})


func test_seen_alone_makes_a_state_non_empty_and_skips_junk() -> void:
	var state := PoiState.from_dict({"seen": ["c1", 4, null]})
	assert_eq(state.seen, {"c1": true})
	assert_false(state.is_empty())


func test_contents_alone_make_a_state_non_empty() -> void:
	var state := PoiState.new()
	state.contents = {"c1": [{"id": "wiring", "count": 1}] as Array[Dictionary]}
	assert_false(state.is_empty())
