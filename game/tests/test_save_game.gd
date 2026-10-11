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
