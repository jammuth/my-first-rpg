extends TestCase


func _items(pairs: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Array in pairs:
		out.append({"id": p[0], "count": p[1]})
	return out


func test_merge_adds_to_matching_stacks_and_appends_new_ones() -> void:
	var stash := _items([["scrap_metal", 2]])
	ItemStacks.merge(stash, _items([["scrap_metal", 3], ["wiring", 1]]))
	assert_eq(stash, _items([["scrap_metal", 5], ["wiring", 1]]))


func test_merge_copies_rather_than_aliasing_the_source() -> void:
	var stash: Array[Dictionary] = []
	var source := _items([["wiring", 1]])
	ItemStacks.merge(stash, source)
	stash[0].count = 9
	assert_eq(source[0].count, 1)


func test_total_and_find() -> void:
	var stash := _items([["a", 2], ["b", 5]])
	assert_eq(ItemStacks.total(stash), 7)
	assert_eq(ItemStacks.find(stash, "b").count, 5)
	assert_eq(ItemStacks.find(stash, "missing"), {})
