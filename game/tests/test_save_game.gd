extends TestCase


func test_round_trip() -> void:
	var text := SaveGame.to_json(4242, {"3_-1": true, "0_2": true}, Vector2(1234.5, -987.25), 1.25)
	var data := SaveGame.from_json(text)
	assert_eq(data.world_seed, 4242)
	assert_eq(data.visited, {"0_2": true, "3_-1": true})
	assert_eq(data.truck_position, Vector2(1234.5, -987.25))
	assert_near(data.truck_yaw, 1.25)


func test_large_positions_survive() -> void:
	var data := SaveGame.from_json(SaveGame.to_json(1, {}, Vector2(123456.75, -654321.5), 0.0))
	assert_eq(data.truck_position, Vector2(123456.75, -654321.5))


func test_rejects_garbage_and_other_versions() -> void:
	assert_eq(SaveGame.from_json(""), {})
	assert_eq(SaveGame.from_json("not json"), {})
	assert_eq(SaveGame.from_json("[1, 2]"), {})
	assert_eq(SaveGame.from_json('{"version": 999, "world_seed": 1, "visited": [], "truck": {"x": 0, "z": 0, "yaw": 0}}'), {})
	assert_eq(SaveGame.from_json('{"version": 1, "world_seed": 1, "visited": [], "truck": {"x": "a", "z": 0, "yaw": 0}}'), {})


func test_ignores_non_string_visited_entries() -> void:
	var data := SaveGame.from_json('{"version": 1, "world_seed": 7, "visited": ["1_1", 5, null], "truck": {"x": 0, "z": 0, "yaw": 0}}')
	assert_eq(data.visited, {"1_1": true})


func test_v2_round_trips_exploration_progress() -> void:
	var state := PoiState.new()
	state.looted = {"crate_1": 42.0}
	state.unlocked = {"door_1": true}
	state.contents = {"crate_1": [{"id": "power_cell", "count": 1}] as Array[Dictionary]}
	var stash: Array[Dictionary] = [{"id": "scrap_metal", "count": 7}]
	var text := SaveGame.to_json(9, {}, Vector2.ZERO, 0.0, {
		"play_time": 123.5, "poi_states": {"2_3": state, "empty": PoiState.new()}, "stash": stash})
	var data := SaveGame.from_json(text)
	assert_near(data.play_time, 123.5)
	assert_eq(data.poi_states.keys(), ["2_3"], "empty POI states are not written")
	assert_eq(data.poi_states["2_3"].looted, {"crate_1": 42.0})
	assert_eq(data.poi_states["2_3"].unlocked, {"door_1": true})
	assert_eq(data.poi_states["2_3"].contents, state.contents)
	assert_eq(data.stash, stash)


func test_v1_saves_still_load_with_empty_progress() -> void:
	var data := SaveGame.from_json('{"version": 1, "world_seed": 5, "visited": ["0_0"], "truck": {"x": 1, "z": 2, "yaw": 0.5}}')
	assert_eq(data.world_seed, 5)
	assert_eq(data.visited, {"0_0": true})
	assert_near(data.play_time, 0.0)
	assert_eq(data.poi_states, {})
	assert_eq(data.stash.size(), 0)


func test_bad_stash_entries_are_dropped() -> void:
	var data := SaveGame.from_json('{"version": 2, "world_seed": 5, "visited": [], "truck": {"x": 0, "z": 0, "yaw": 0}, "play_time": -4, "stash": [{"id": "a", "count": 2}, {"id": "a", "count": 1}, {"id": 3, "count": 1}, {"id": "b", "count": 0}, "x"]}')
	var expected: Array[Dictionary] = [{"id": "a", "count": 3}]
	assert_eq(data.stash, expected)
	assert_near(data.play_time, 0.0)


func test_character_round_trips_and_defaults_to_empty() -> void:
	var data := SaveGame.from_json(SaveGame.to_json(1, {}, Vector2.ZERO, 0.0, {"character": "drifter"}))
	assert_eq(data.character, "drifter")
	assert_eq(SaveGame.from_json(SaveGame.to_json(1, {}, Vector2.ZERO, 0.0)).character, "")
	var bad := SaveGame.from_json('{"version": 2, "world_seed": 1, "visited": [], "truck": {"x": 0, "z": 0, "yaw": 0}, "character": 4}')
	assert_eq(bad.character, "")
