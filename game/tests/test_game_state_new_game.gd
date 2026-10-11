extends TestCase


func test_new_game_wipes_progress_but_keeps_character() -> void:
	var gs: Node = Engine.get_main_loop().root.get_node("GameState")
	var keys := ["world_seed", "visited_pois", "start_position", "start_yaw", "truck_world_position",
		"truck_yaw", "origin", "play_time", "poi_states", "truck_stash", "character_id"]
	var backup := {}
	for k in keys:
		backup[k] = gs.get(k)
	gs.world_seed = 99
	gs.visited_pois = {"1_1": true}
	gs.start_position = Vector2(50, 50)
	gs.play_time = 300.0
	gs.poi_states = {"1_1": PoiState.new()}
	var stash: Array[Dictionary] = [{"id": "scrap_metal", "count": 3}]
	gs.truck_stash = stash
	gs.character_id = "hoarder"
	gs.new_game()
	assert_eq(gs.world_seed, gs.DEFAULT_SEED)
	assert_eq(gs.visited_pois, {})
	assert_eq(gs.start_position, null)
	assert_near(gs.play_time, 0.0)
	assert_eq(gs.poi_states, {})
	assert_eq(gs.truck_stash.size(), 0)
	assert_eq(gs.character_id, "hoarder")
	for k in keys:
		gs.set(k, backup[k])
