extends TestCase


func test_starts_with_eight_empty_slots() -> void:
	var bag := Bag.new()
	assert_eq(bag.capacity(), 8)
	assert_eq(bag.used(), 0)
	assert_true(bag.is_empty())


func test_add_tops_up_partial_stacks_before_new_slots() -> void:
	var bag := Bag.new()
	assert_eq(bag.add("scrap_metal", 15), 0)
	assert_eq(bag.add("wiring", 1), 0)
	assert_eq(bag.add("scrap_metal", 10), 0)
	assert_eq(bag.slots[0], {"id": "scrap_metal", "count": 20}, "stack size is 20")
	assert_eq(bag.slots[1], {"id": "wiring", "count": 1})
	assert_eq(bag.slots[2], {"id": "scrap_metal", "count": 5}, "overflow starts a new slot")


func test_large_adds_split_into_full_stacks() -> void:
	var bag := Bag.new()
	assert_eq(bag.add("power_cell", 12), 0)
	assert_eq(bag.used(), 3)
	assert_eq(bag.slots[2].count, 2)


func test_full_bag_rejects_and_reports_the_rest() -> void:
	var bag := Bag.new(2)
	assert_eq(bag.add("drone_core", 3), 1, "drone cores don't stack")
	assert_eq(bag.space_for("drone_core"), 0)
	assert_eq(bag.add("wiring", 4), 4, "no empty slot left")


func test_space_for_counts_partial_stacks_and_empty_slots() -> void:
	var bag := Bag.new(3)
	bag.add("wiring", 10)
	bag.add("battery", 8)
	assert_eq(bag.space_for("wiring"), 5 + 15)
	assert_eq(bag.space_for("battery"), 8)
	assert_eq(bag.space_for("drone_core"), 1)


func test_swap_and_take_slot() -> void:
	var bag := Bag.new()
	bag.add("wiring", 2)
	bag.swap(0, 7)
	assert_true(bag.slots[0].is_empty())
	assert_eq(bag.slots[7], {"id": "wiring", "count": 2})
	assert_eq(bag.take_slot(7), {"id": "wiring", "count": 2})
	assert_true(bag.is_empty())


func test_items_merges_slots_for_the_stash() -> void:
	var bag := Bag.new()
	bag.add("scrap_metal", 25)
	bag.add("battery", 1)
	var expected: Array[Dictionary] = [{"id": "scrap_metal", "count": 25}, {"id": "battery", "count": 1}]
	assert_eq(bag.items(), expected)


func test_unknown_items_take_a_slot_each() -> void:
	var bag := Bag.new(2)
	assert_eq(bag.add("mystery", 3), 1)
	assert_eq(bag.used(), 2)


func test_take_moves_what_fits_and_leaves_the_rest() -> void:
	var bag := Bag.new(1)
	bag.add("wiring", 10)
	var contents: Array[Dictionary] = [{"id": "wiring", "count": 8}, {"id": "battery", "count": 1}]
	assert_eq(LootTransfer.take(bag, contents, 0), 5)
	assert_eq(contents[0], {"id": "wiring", "count": 3})
	assert_eq(LootTransfer.take(bag, contents, 1), 0, "no slot for the battery")
	assert_eq(contents.size(), 2)


func test_take_removes_a_fully_taken_stack() -> void:
	var bag := Bag.new()
	var contents: Array[Dictionary] = [{"id": "wiring", "count": 2}]
	assert_eq(LootTransfer.take(bag, contents, 0), 2)
	assert_true(contents.is_empty())


func test_take_all_stops_when_full_but_takes_what_still_fits() -> void:
	var bag := Bag.new(2)
	var contents: Array[Dictionary] = [
		{"id": "drone_core", "count": 1}, {"id": "power_cell", "count": 1},
		{"id": "battery", "count": 1}, {"id": "power_cell", "count": 2}]
	assert_eq(LootTransfer.take_all(bag, contents), 4, "the second power cells join the first stack")
	assert_eq(contents, [{"id": "battery", "count": 1}] as Array[Dictionary])


func test_drop_moves_a_slot_into_the_container() -> void:
	var bag := Bag.new()
	bag.add("battery", 3)
	var contents: Array[Dictionary] = []
	LootTransfer.drop(bag, 0, contents)
	assert_true(bag.is_empty())
	assert_eq(contents, [{"id": "battery", "count": 3}] as Array[Dictionary])
	LootTransfer.drop(bag, 0, contents)
	assert_eq(contents.size(), 1, "dropping an empty slot does nothing")
