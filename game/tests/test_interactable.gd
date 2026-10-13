extends TestCase

const SEED := 1337


func _crate(id: String, pos: Vector2, radius := 1.0) -> Interactable:
	return Interactable.make(id, Interactable.Kind.CONTAINER, pos, radius, radius + 1.2, 2.0, "crate")


func test_picks_the_nearest_in_reach() -> void:
	var near := _crate("near", Vector2(0, -1.5))
	var far := _crate("far", Vector2(0, -2.1))
	var targets: Array[Interactable] = [far, near]
	assert_eq(Interactable.pick(targets, Vector2.ZERO, Vector2(0, -1)), near)


func test_ignores_targets_out_of_reach() -> void:
	var targets: Array[Interactable] = [_crate("a", Vector2(0, -2.3))]
	assert_eq(Interactable.pick(targets, Vector2.ZERO, Vector2(0, -1)), null, "2.3 m > 2.2 m reach")


func test_ignores_targets_behind_or_beside() -> void:
	var behind := _crate("behind", Vector2(0, 1.5))
	var beside := _crate("beside", Vector2(1.5, -0.3))
	var targets: Array[Interactable] = [behind, beside]
	assert_eq(Interactable.pick(targets, Vector2.ZERO, Vector2(0, -1)), null)
	assert_eq(Interactable.pick(targets, Vector2.ZERO, Vector2(1, 0)), beside, "turning picks it up")


func test_compares_by_distance_to_the_edge() -> void:
	var barrel := _crate("barrel", Vector2(0, -1.5), 0.4)
	var wreck := _crate("wreck", Vector2(1.0, -2.6), 2.5)
	var targets: Array[Interactable] = [barrel, wreck]
	assert_eq(Interactable.pick(targets, Vector2.ZERO, Vector2(0, -1)), wreck, "the wreck's side is closer")


func test_standing_on_a_door_step_counts_as_facing() -> void:
	var door := Interactable.make("d1", Interactable.Kind.DOOR, Vector2(0.1, 0.1), 0.0, 1.8, 2.0)
	var targets: Array[Interactable] = [door]
	assert_eq(Interactable.pick(targets, Vector2.ZERO, Vector2(0, -1)), door)


func test_empty_list_picks_nothing() -> void:
	var targets: Array[Interactable] = []
	assert_eq(Interactable.pick(targets, Vector2.ZERO, Vector2(0, -1)), null)


func test_from_level_covers_every_spot_and_the_truck() -> void:
	var poi: PoiData = null
	for p in PoiGenerator.pois_in_rect(SEED, Rect2(-1024, -1024, 2048, 2048)):
		poi = ExplorationLevel.poi_with_layout(SEED, p.id)
		if poi != null and poi.type_id == "settlement":
			break
	assert_not_null(poi)
	var park := ExplorationLevel.parking(poi, null, 0.0)
	var level := ExplorationLevel.build(SEED, poi, park[0], park[1])
	var all := Interactable.from_level(level)
	assert_eq(all.size(), level.containers.size() + level.loot_rooms.size() + 1)
	var ids := {}
	for it in all:
		ids[it.id] = true
		assert_true(it.reach > it.radius, "%s can be reached from outside its edge" % it.id)
		if it.kind == Interactable.Kind.CONTAINER:
			assert_true(it.duration >= 1.0 and it.duration <= 3.0, "%s search time in 1–3 s" % it.id)
	assert_eq(ids.size(), all.size(), "ids are unique")
	assert_true(ids.has("truck"))
	var truck: Interactable = all[-1]
	assert_eq(truck.kind, Interactable.Kind.TRUCK)
	assert_near(truck.duration, 0.0)
	assert_eq(Interactable.pick(all, level.spawn, (level.truck_position - level.spawn).normalized()), truck,
		"facing the truck from the spawn picks it")


func test_every_container_kind_has_a_search_time() -> void:
	for kind: String in ExplorationLevel.SEARCHABLE.values():
		assert_true(Interactable.SEARCH_TIME.has(kind), "no search time for %s" % kind)


func test_prompts_name_the_target() -> void:
	assert_eq(_crate("c1", Vector2.ZERO).prompt(), "Press E / A to search the crate")
	assert_eq(_crate("c1", Vector2.ZERO).progress_text(), "Searching the crate…")
	var door := Interactable.make("d1", Interactable.Kind.DOOR, Vector2.ZERO, 0.0, 1.8, 2.0)
	assert_eq(door.prompt(), "Press E / A to unlock the loot room")
	assert_eq(door.prompt(true), "Press E / A to open the loot room")
	assert_eq(_crate("c1", Vector2.ZERO).prompt(true), "Press E / A to open the crate")


func test_loot_kind_matches_a_table() -> void:
	var door := Interactable.make("d1", Interactable.Kind.DOOR, Vector2.ZERO, 0.0, 1.8, 2.0)
	assert_eq(door.loot_kind(), "loot_room")
	assert_eq(_crate("c1", Vector2.ZERO).loot_kind(), "crate")
	assert_true(LootTables.STACKS.has(door.loot_kind()))


func test_timer_runs_to_completion_once() -> void:
	var timer := InteractionTimer.new(_crate("c1", Vector2.ZERO))
	assert_false(timer.advance(1.0))
	assert_near(timer.fraction(), 0.5)
	assert_true(timer.advance(1.0), "finishes at 2 s")
	assert_false(timer.advance(1.0), "only reports finishing once")
	assert_near(timer.fraction(), 1.0)


func test_instant_targets_are_done_straight_away() -> void:
	var truck := Interactable.make("truck", Interactable.Kind.TRUCK, Vector2.ZERO, 2.0, 5.0, 0.0)
	assert_true(InteractionTimer.new(truck).done())


func test_cancel_rules() -> void:
	var crate := _crate("c1", Vector2.ZERO)
	var other := _crate("c2", Vector2.ONE)
	assert_false(InteractionTimer.should_cancel(false, false, crate, crate))
	assert_true(InteractionTimer.should_cancel(true, false, crate, crate), "moving cancels")
	assert_true(InteractionTimer.should_cancel(false, true, crate, crate), "pressing again cancels")
	assert_true(InteractionTimer.should_cancel(false, false, crate, other), "a different target cancels")
	assert_true(InteractionTimer.should_cancel(false, false, crate, null), "losing the target cancels")
