extends TestCase


func _scrap(n: int) -> Array[Dictionary]:
	var items: Array[Dictionary] = [{"id": "scrap_metal", "count": n}]
	return items


func test_loot_fills_bag_once_per_container() -> void:
	var s := ExplorationSession.new("1_2", PoiState.new())
	assert_true(s.loot("c1", _scrap(2), 5.0))
	assert_false(s.loot("c1", _scrap(2), 6.0), "second search of the same container")
	assert_true(s.is_looted("c1"))
	assert_eq(ItemStacks.total(s.bag), 2)
	assert_true(s.poi_state.is_empty(), "nothing is banked until unloading")


func test_bank_commits_progress_and_empties_bag() -> void:
	var state := PoiState.new()
	var s := ExplorationSession.new("1_2", state)
	s.loot("c1", _scrap(3), 5.0)
	s.unlock("d1")
	var unloaded := s.bank()
	assert_eq(ItemStacks.total(unloaded), 3)
	assert_eq(s.bag.size(), 0)
	assert_eq(state.looted, {"c1": 5.0})
	assert_eq(state.unlocked, {"d1": true})
	assert_false(s.has_unbanked_progress())


func test_defeat_resets_poi_to_last_unload() -> void:
	var s := ExplorationSession.new("1_2", PoiState.new())
	s.loot("banked", _scrap(1), 1.0)
	s.bank()
	s.loot("lost", _scrap(4), 2.0)
	s.unlock("door")
	s.encounters = 2
	s.defeat()
	assert_eq(s.bag.size(), 0)
	assert_eq(s.encounters, 0)
	assert_true(s.is_looted("banked"), "banked containers stay empty")
	assert_false(s.is_looted("lost"), "containers from the lost bag refill")
	assert_false(s.is_unlocked("door"), "doors opened since the last unload lock again")
	assert_true(s.loot("lost", _scrap(4), 3.0))


func test_banked_state_is_seen_by_a_new_session() -> void:
	var state := PoiState.new()
	var first := ExplorationSession.new("1_2", state)
	first.loot("c1", _scrap(1), 1.0)
	first.unlock("d1")
	first.bank()
	var second := ExplorationSession.new("1_2", state)
	assert_true(second.is_looted("c1"))
	assert_true(second.is_unlocked("d1"))
	assert_false(second.loot("c1", _scrap(1), 9.0))
