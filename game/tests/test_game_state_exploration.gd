extends TestCase

## Drives the GameState autoload through a run. Saving is disabled by the runner; the fields
## touched here are restored afterwards so other tests see a clean state.

var _gs: Node
var _backup: Dictionary


func _poi() -> PoiData:
	var poi := PoiData.new()
	poi.id = "7_-3"
	poi.display_name = "Test Scrapyard"
	return poi


func _begin() -> void:
	_gs = Engine.get_main_loop().root.get_node("GameState")
	_backup = {"stash": _gs.truck_stash.duplicate(true), "pois": _gs.poi_states.duplicate(),
		"start": _gs.start_position, "yaw": _gs.start_yaw, "pos": _gs.truck_world_position}
	_gs.truck_stash = [] as Array[Dictionary]
	_gs.poi_states = {}


func _end() -> void:
	_gs.end_exploration()
	_gs.truck_stash = _backup.stash
	_gs.poi_states = _backup.pois
	_gs.start_position = _backup.start
	_gs.start_yaw = _backup.yaw
	_gs.truck_world_position = _backup.pos


func test_run_unload_and_leave() -> void:
	_begin()
	_gs.truck_world_position = Vector2(500.0, -20.0)
	_gs.start_exploration(_poi())
	assert_eq(_gs.start_position, Vector2(500.0, -20.0), "the overworld comes back where the truck parked")
	var items: Array[Dictionary] = [{"id": "scrap_metal", "count": 2}]
	LootTransfer.take_all(_gs.exploration.bag, _gs.exploration.open("c1", items, _gs.play_time))
	_gs.unload_at_truck()
	assert_eq(ItemStacks.total(_gs.truck_stash), 2)
	LootTransfer.take_all(_gs.exploration.bag, _gs.exploration.open("c2", items, _gs.play_time))
	_gs.end_exploration()
	assert_eq(ItemStacks.total(_gs.truck_stash), 4, "leaving unloads what is carried")
	assert_eq(_gs.exploration, null)
	assert_eq(_gs.poi_state("7_-3").looted.size(), 2)
	_end()


func test_defeat_keeps_only_unloaded_scrap() -> void:
	_begin()
	_gs.start_exploration(_poi())
	var items: Array[Dictionary] = [{"id": "scrap_metal", "count": 3}]
	LootTransfer.take_all(_gs.exploration.bag, _gs.exploration.open("c1", items, 0.0))
	_gs.unload_at_truck()
	LootTransfer.take_all(_gs.exploration.bag, _gs.exploration.open("c2", items, 0.0))
	_gs.exploration.defeat()
	_gs.end_exploration()
	assert_eq(ItemStacks.total(_gs.truck_stash), 3)
	assert_eq(_gs.poi_state("7_-3").looted.keys(), ["c1"])
	_end()
