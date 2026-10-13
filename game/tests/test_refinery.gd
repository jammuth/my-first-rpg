extends TestCase


func _stash(pairs: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Array in pairs:
		out.append({"id": p[0], "count": p[1]})
	return out


func test_starts_idle_with_one_slot() -> void:
	var r := Refinery.new()
	assert_eq(r.slots.size(), 1)
	assert_true(r.is_idle())
	assert_eq(r.advance(100.0), {})


func test_enqueue_moves_the_stack_and_fills_the_idle_slot() -> void:
	var r := Refinery.new()
	var stash := _stash([["scrap_metal", 3], ["battery", 1]])
	r.enqueue_from(stash, 0)
	assert_eq(stash, _stash([["battery", 1]]))
	assert_eq(r.slots[0], {"id": "scrap_metal", "count": 3, "elapsed": 0.0})
	r.enqueue_from(stash, 0)
	assert_eq(r.queue, _stash([["battery", 1]]), "the slot is busy, so it waits")
	assert_true(stash.is_empty())


func test_each_item_takes_its_rarity_time_and_yields_on_completion() -> void:
	var r := Refinery.new()
	var stash := _stash([["scrap_metal", 2]])
	r.enqueue_from(stash, 0)
	assert_eq(r.advance(9.0), {}, "common takes 10 s")
	assert_near(r.item_progress(0), 0.9)
	assert_eq(r.advance(1.0), {"metal": 2})
	assert_eq(r.slots[0].count, 1)
	assert_near(r.slot_time_left(0), 10.0)
	assert_eq(r.advance(10.0), {"metal": 2})
	assert_true(r.is_idle())


func test_a_long_step_finishes_several_items_and_pulls_from_the_queue() -> void:
	var r := Refinery.new()
	var stash := _stash([["scrap_metal", 2], ["battery", 1]])
	r.enqueue_from(stash, 0)
	r.enqueue_from(stash, 0)
	assert_near(r.total_time_left(), 10.0 * 2 + 20.0)
	assert_eq(r.advance(25.0), {"metal": 4})
	assert_eq(r.slots[0].id, "battery", "the queue fed the slot")
	assert_near(r.slots[0].elapsed, 5.0, 0.0001, "leftover time carries into the next stack")
	assert_eq(r.advance(15.0), {"power": 4, "metal": 2})
	assert_true(r.is_idle())


func test_offline_style_big_advance_matches_small_steps() -> void:
	var big := Refinery.new()
	var small := Refinery.new()
	for r: Refinery in [big, small]:
		var stash := _stash([["wiring", 5], ["power_cell", 2], ["drone_core", 1]])
		r.enqueue_from(stash, 0)
		r.enqueue_from(stash, 0)
		r.enqueue_from(stash, 0)
	var total_big := big.advance(200.0)
	var total_small := {}
	for i in 2000:
		var got := small.advance(0.1)
		for e: String in got:
			total_small[e] = total_small.get(e, 0) + got[e]
	assert_eq(total_big, total_small)
	assert_eq(big.slots[0].id, small.slots[0].id)
	assert_near(big.slots[0].elapsed, small.slots[0].elapsed, 0.01)


func test_dequeue_returns_to_the_stash() -> void:
	var r := Refinery.new()
	var stash := _stash([["wiring", 2], ["wiring", 3]])
	r.enqueue_from(stash, 0)
	r.enqueue_from(stash, 0)
	r.dequeue_to(stash, 0)
	assert_eq(stash, _stash([["wiring", 3]]))
	assert_true(r.queue.is_empty())


func test_cancel_slot_returns_unfinished_items_and_pulls_the_next() -> void:
	var r := Refinery.new()
	var stash := _stash([["scrap_metal", 3], ["battery", 1]])
	r.enqueue_from(stash, 0)
	r.enqueue_from(stash, 0)
	r.advance(15.0)
	r.cancel_slot(stash, 0)
	assert_eq(stash, _stash([["scrap_metal", 2]]), "one finished, two come back; partial progress is lost")
	assert_eq(r.slots[0], {"id": "battery", "count": 1, "elapsed": 0.0})


func test_more_slots_work_in_parallel() -> void:
	var r := Refinery.new(2)
	var stash := _stash([["scrap_metal", 1], ["plastic_scraps", 1]])
	r.enqueue_from(stash, 0)
	r.enqueue_from(stash, 0)
	assert_eq(r.advance(10.0), {"metal": 2, "polymer": 2})


func test_upgrading_slots_pulls_queued_work() -> void:
	var r := Refinery.new()
	var stash := _stash([["scrap_metal", 1], ["wiring", 1]])
	r.enqueue_from(stash, 0)
	r.enqueue_from(stash, 0)
	r.set_slot_count(2)
	assert_eq(r.slots[1].id, "wiring")
	assert_true(r.queue.is_empty())


func test_round_trips_through_json() -> void:
	var r := Refinery.new()
	var stash := _stash([["battery", 3], ["wiring", 2], ["battery", 1]])
	r.enqueue_from(stash, 0)
	r.enqueue_from(stash, 0)
	r.enqueue_from(stash, 0)
	r.advance(27.5)
	var back := Refinery.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))
	assert_eq(back.slots[0].id, "battery")
	assert_eq(back.slots[0].count, 2)
	assert_near(back.slots[0].elapsed, 7.5)
	assert_eq(back.queue, _stash([["wiring", 2], ["battery", 1]]), "queue order and repeats survive")
	assert_eq(back.advance(12.5), r.advance(12.5))


func test_bad_saves_load_as_empty() -> void:
	assert_true(Refinery.from_dict(null).is_idle())
	assert_true(Refinery.from_dict({"slots": "x", "queue": 4}).is_idle())
	var r := Refinery.from_dict({"slots": [{"id": "wiring", "count": 2, "elapsed": 999.0}, {"id": "x", "count": 1}],
		"queue": [{"id": 3}, {"id": "battery", "count": 1}]})
	assert_eq(r.slots.size(), 1, "extra saved slots beyond the current count are ignored")
	assert_near(r.slots[0].elapsed, 10.0, 0.0001, "elapsed is clamped to the item's time")
	assert_eq(r.queue, _stash([["battery", 1]]))


func test_empty_saved_slot_pulls_from_saved_queue() -> void:
	var r := Refinery.from_dict({"slots": [{}], "queue": [{"id": "wiring", "count": 1}]})
	assert_eq(r.slots[0].id, "wiring")
	assert_true(r.queue.is_empty())


func test_save_game_keeps_refinery_and_elements() -> void:
	var r := Refinery.new()
	var stash := _stash([["battery", 2]])
	r.enqueue_from(stash, 0)
	var text := SaveGame.to_json(9, {}, Vector2.ZERO, 0.0, {"refinery": r.to_dict(), "elements": {"metal": 5, "core": 1}})
	var data := SaveGame.from_json(text)
	assert_eq(Refinery.from_dict(data.refinery).slots[0].id, "battery")
	assert_eq(data.elements, {"metal": 5, "core": 1})


func test_older_saves_have_no_refinery_or_elements() -> void:
	var data := SaveGame.from_json('{"version": 2, "world_seed": 5, "visited": [], "truck": {"x": 0, "z": 0, "yaw": 0}, "elements": {"metal": -3, "power": 2, "x": "y"}}')
	assert_true(Refinery.from_dict(data.refinery).is_idle())
	assert_eq(data.elements, {"power": 2})
