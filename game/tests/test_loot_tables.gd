extends TestCase

const SEED := 1337


func _poi(type_id := "factory", cell := Vector2i(3, -2)) -> PoiData:
	var poi := PoiData.new()
	poi.id = "%d_%d" % [cell.x, cell.y]
	poi.cell = cell
	poi.type_id = type_id
	return poi


func test_catalog_is_complete() -> void:
	for id: String in ItemCatalog.ITEMS:
		var item: Dictionary = ItemCatalog.ITEMS[id]
		assert_true(item.stack >= 1, "%s stack size" % id)
		assert_true(item.main in ItemCatalog.ELEMENTS, "%s main element" % id)
		assert_true(item.get("secondary", "metal") in ItemCatalog.ELEMENTS, "%s secondary element" % id)
		assert_false(ItemCatalog.yield_of(id).is_empty(), "%s breaks down into something" % id)
	for r in ItemCatalog.Rarity.values():
		assert_false(ItemCatalog.ids_of(r).is_empty(), "rarity %d has items" % r)
	assert_eq(ItemCatalog.RARITY_NAMES.size(), 4)
	assert_eq(ItemCatalog.RARITY_COLORS.size(), 4)
	assert_eq(ItemCatalog.REFINE_TIME.size(), 4)
	assert_eq(ItemCatalog.MAIN_YIELD.size(), 4)


func test_unknown_items_are_safe() -> void:
	assert_eq(ItemCatalog.item_name("odd_thing"), "Odd Thing")
	assert_eq(ItemCatalog.stack_size("odd_thing"), 1)
	assert_eq(ItemCatalog.rarity("odd_thing"), ItemCatalog.Rarity.COMMON)
	assert_true(ItemCatalog.describe("odd_thing").contains("Unknown scrap"))
	assert_eq(ItemCatalog.yield_of("odd_thing"), {})


func test_yields_follow_material_and_rarity() -> void:
	assert_eq(ItemCatalog.yield_of("scrap_metal"), {"metal": 2})
	assert_eq(ItemCatalog.yield_of("wiring"), {"circuitry": 2, "polymer": 1})
	assert_eq(ItemCatalog.yield_of("battery"), {"power": 4, "metal": 2})
	assert_eq(ItemCatalog.yield_of("sensor_module"), {"circuitry": 7, "power": 3})
	assert_eq(ItemCatalog.yield_of("fusion_coil"), {"power": 12, "metal": 6, "core": 1})


func test_rarer_items_yield_more_and_take_longer() -> void:
	for r in range(1, 4):
		assert_true(ItemCatalog.MAIN_YIELD[r] > ItemCatalog.MAIN_YIELD[r - 1])
		assert_true(ItemCatalog.REFINE_TIME[r] > ItemCatalog.REFINE_TIME[r - 1])
	assert_near(ItemCatalog.refine_time("scrap_metal"), 10.0)
	assert_near(ItemCatalog.refine_time("drone_core"), 90.0)
	for id in ItemCatalog.ids_of(ItemCatalog.Rarity.EPIC):
		assert_true(ItemCatalog.yield_of(id).has("core"), "%s gives core" % id)
	for r in [ItemCatalog.Rarity.COMMON, ItemCatalog.Rarity.UNCOMMON, ItemCatalog.Rarity.RARE]:
		for id in ItemCatalog.ids_of(r):
			assert_false(ItemCatalog.yield_of(id).has("core"), "%s gives no core" % id)


func test_describe_shows_yield_and_time() -> void:
	assert_eq(ItemCatalog.describe("battery"),
		"Battery  ·  Uncommon  ·  stacks to 8  ·  Breaks down into 2 metal, 4 power in 20s")


func test_tables_are_consistent() -> void:
	for kind: String in ExplorationLevel.SEARCHABLE.values():
		assert_true(LootTables.STACKS.has(kind), "stack range for %s" % kind)
		assert_true(LootTables.RARITY_WEIGHTS.has(kind), "rarity weights for %s" % kind)
	for kind: String in LootTables.RARITY_WEIGHTS:
		var weights: Array = LootTables.RARITY_WEIGHTS[kind]
		assert_eq(weights.size(), 4, kind)
		var total := 0
		for w: int in weights:
			assert_true(w >= 0)
			total += w
		assert_eq(total, 100, "%s weights add up to 100" % kind)
	for type_id: String in LootTables.POI_FAVOURS:
		for id: String in LootTables.POI_FAVOURS[type_id]:
			assert_true(ItemCatalog.has(id), "%s favours unknown %s" % [type_id, id])
	for type_id: String in ExplorationLevel.LOOT_ROOMS:
		assert_true(LootTables.POI_FAVOURS.has(type_id), "favours for %s" % type_id)


func test_rolls_are_deterministic() -> void:
	var a := LootTables.roll(SEED, _poi(), "c4", "crate")
	assert_eq(a, LootTables.roll(SEED, _poi(), "c4", "crate"))
	var differs := false
	for i in 20:
		if LootTables.roll(SEED, _poi(), "c%d" % i, "crate") != a:
			differs = true
	assert_true(differs, "different containers roll differently")
	assert_ne(LootTables.roll(SEED + 1, _poi(), "c4", "wreck"), LootTables.roll(SEED, _poi(), "c4", "wreck"))


func test_rolls_stay_in_range_and_within_stack_sizes() -> void:
	for kind: String in LootTables.STACKS:
		var span: Array = LootTables.STACKS[kind]
		for i in 40:
			var items := LootTables.roll(SEED, _poi("scrapyard", Vector2i(i, 1)), "c%d" % i, kind)
			assert_true(items.size() >= 1 and items.size() <= span[1], "%s rolled %d stacks" % [kind, items.size()])
			for item in items:
				assert_true(ItemCatalog.has(item.id))
				assert_true(item.count >= 1 and item.count <= ItemCatalog.stack_size(item.id), "%s ×%d" % [item.id, item.count])


func test_loot_rooms_beat_trash() -> void:
	var trash := _rare_share("trash")
	var room := _rare_share("loot_room")
	assert_true(room > trash * 3.0, "rare-or-better share: loot room %f vs trash %f" % [room, trash])


func test_poi_type_favours_its_items() -> void:
	var favoured := 0
	var total := 0
	for i in 300:
		for item in LootTables.roll(SEED, _poi("factory", Vector2i(i, 7)), "c1", "crate"):
			total += 1
			if item.id in LootTables.POI_FAVOURS.factory:
				favoured += 1
	assert_true(float(favoured) / total > 0.45, "factory items %d / %d" % [favoured, total])


func _rare_share(kind: String) -> float:
	var rare := 0
	var total := 0
	for i in 300:
		for item in LootTables.roll(SEED, _poi("settlement", Vector2i(i, 2)), "c%d" % i, kind):
			total += 1
			if ItemCatalog.rarity(item.id) >= ItemCatalog.Rarity.RARE:
				rare += 1
	return float(rare) / total
