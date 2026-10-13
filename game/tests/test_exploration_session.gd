extends TestCase


func _scrap(n: int) -> Array[Dictionary]:
	var items: Array[Dictionary] = [{"id": "scrap_metal", "count": n}]
	return items


## Opens a container and takes everything from it.
func _loot(s: ExplorationSession, id: String, n: int, now := 0.0) -> void:
	LootTransfer.take_all(s.bag, s.open(id, _scrap(n), now))


func test_opening_rolls_once_and_keeps_what_is_left() -> void:
	var s := ExplorationSession.new("1_2", PoiState.new())
	var box := s.open("c1", _scrap(3), 5.0)
	assert_true(s.is_opened("c1"))
	assert_eq(box, _scrap(3))
	box[0].count = 1
	assert_eq(s.open("c1", _scrap(9), 6.0), _scrap(1), "a second open sees what's left, not a new roll")
	assert_false(s.is_emptied("c1"))
	box.clear()
	assert_true(s.is_emptied("c1"))
	assert_true(s.poi_state.is_empty(), "nothing is banked until unloading")


func test_open_copies_the_roll() -> void:
	var s := ExplorationSession.new("1_2", PoiState.new())
	var rolled := _scrap(3)
	s.open("c1", rolled, 0.0).clear()
	assert_eq(rolled, _scrap(3))


func test_bank_commits_progress_and_empties_bag() -> void:
	var state := PoiState.new()
	var s := ExplorationSession.new("1_2", state)
	_loot(s, "c1", 3, 5.0)
	var partly := s.open("c2", _scrap(4), 6.0)
	partly[0].count = 2
	s.unlock("d1")
	var unloaded := s.bank()
	assert_eq(ItemStacks.total(unloaded), 3)
	assert_true(s.bag.is_empty())
	assert_eq(state.looted, {"c1": 5.0, "c2": 6.0})
	assert_eq(state.contents, {"c2": _scrap(2)}, "emptied containers need no contents entry")
	assert_eq(state.unlocked, {"d1": true})
	assert_false(s.has_unbanked_progress())


func test_defeat_resets_poi_to_last_unload() -> void:
	var s := ExplorationSession.new("1_2", PoiState.new())
	s.open("banked", _scrap(5), 1.0)[0].count = 4
	s.bank()
	LootTransfer.take_all(s.bag, s.open("banked", _scrap(5), 2.0))
	_loot(s, "lost", 4, 2.0)
	s.unlock("door")
	s.encounters = 2
	s.defeat()
	assert_true(s.bag.is_empty())
	assert_eq(s.encounters, 0)
	assert_eq(s.contents("banked"), _scrap(4), "a banked container goes back to what was left at the unload")
	assert_false(s.is_opened("lost"), "containers opened since the unload refill")
	assert_false(s.is_unlocked("door"), "doors opened since the last unload lock again")
	assert_eq(s.open("lost", _scrap(4), 3.0), _scrap(4))


func test_banked_state_is_seen_by_a_new_session() -> void:
	var state := PoiState.new()
	var first := ExplorationSession.new("1_2", state)
	_loot(first, "c1", 1, 1.0)
	first.unlock("d1")
	first.bank()
	var second := ExplorationSession.new("1_2", state)
	assert_true(second.is_emptied("c1"))
	assert_true(second.is_unlocked("d1"))
	assert_eq(second.open("c1", _scrap(1), 9.0).size(), 0, "an emptied container doesn't roll again")


func test_old_saves_count_looted_containers_as_empty() -> void:
	var state := PoiState.new()
	state.looted = {"c1": 3.0}
	var s := ExplorationSession.new("1_2", state)
	assert_true(s.is_emptied("c1"))
	assert_eq(s.open("c1", _scrap(2), 4.0).size(), 0)


func test_dropping_into_a_banked_empty_container_is_kept_until_unload() -> void:
	var state := PoiState.new()
	state.looted = {"c1": 3.0}
	var s := ExplorationSession.new("1_2", state)
	s.bag.add("wiring", 2)
	LootTransfer.drop(s.bag, 0, s.open("c1", [] as Array[Dictionary], 4.0))
	assert_false(s.is_emptied("c1"))
	assert_true(state.contents.is_empty(), "still unbanked")
	s.bank()
	assert_eq(state.contents.c1, [{"id": "wiring", "count": 2}] as Array[Dictionary])
	assert_eq(state.looted.c1, 3.0, "first-opened time is kept")
