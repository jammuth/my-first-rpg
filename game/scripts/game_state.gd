extends Node

const DEFAULT_SEED := 1337
const SAVE_PATH := "user://savegame.json"
const AUTOSAVE_INTERVAL := 30.0

var world_seed: int = DEFAULT_SEED
var visited_pois: Dictionary = {}
## Where the truck should start, in world coordinates; null for the default spawn.
var start_position: Variant = null
var start_yaw := 0.0
## Set by main each frame so saves capture where the player actually is.
var truck_world_position := Vector2.ZERO
var truck_yaw := 0.0
var saving_enabled := true
## Floating origin: world = local + origin (see WorldOrigin). Owned by main.gd.
var origin := Vector3.ZERO

var _autosave_timer := AUTOSAVE_INTERVAL


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--new-game"):
		saving_enabled = not OS.get_cmdline_user_args().has("--benchmark")
		return
	load_game()


func _process(delta: float) -> void:
	_autosave_timer -= delta
	if _autosave_timer <= 0.0:
		_autosave_timer = AUTOSAVE_INTERVAL
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func mark_visited(poi_id: String) -> void:
	visited_pois[poi_id] = true
	save_game()


func is_visited(poi_id: String) -> bool:
	return visited_pois.has(poi_id)


func save_game() -> void:
	if not saving_enabled:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("could not write save: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(SaveGame.to_json(world_seed, visited_pois, truck_world_position, truck_yaw))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data := SaveGame.from_json(FileAccess.get_file_as_string(SAVE_PATH))
	if data.is_empty():
		push_warning("ignoring unreadable save at " + SAVE_PATH)
		return
	world_seed = data.world_seed
	visited_pois = data.visited
	start_position = data.truck_position
	start_yaw = data.truck_yaw
	truck_world_position = data.truck_position
	truck_yaw = data.truck_yaw
