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
## Seconds played (stops while the tree is paused). Timestamps loot and will drive breakdown.
var play_time := 0.0
## POI id -> PoiState, banked progress only.
var poi_states: Dictionary = {}
## Unloaded scrap waiting at the truck.
var truck_stash: Array[Dictionary] = []
## The run in progress, or null in the overworld. Never saved: quitting mid-run behaves like
## walking away from the POI without unloading.
var exploration: ExplorationSession = null
var exploration_poi: PoiData = null
## Which CharacterOptions look the explorer uses; chosen on the main menu.
var character_id := CharacterOptions.DEFAULT
## True once a save file has been read, so the menu can offer Continue.
var has_save := false

var _autosave_timer := AUTOSAVE_INTERVAL


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--benchmark"):
		# Always the same route from spawn, and never overwrite the player's save.
		saving_enabled = false
		return
	if args.has("--new-game"):
		return
	load_game()


func _process(delta: float) -> void:
	play_time += delta
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


## Wipes progress back to a fresh world. The chosen character is kept.
func new_game() -> void:
	world_seed = DEFAULT_SEED
	visited_pois = {}
	start_position = null
	start_yaw = 0.0
	truck_world_position = Vector2.ZERO
	truck_yaw = 0.0
	origin = Vector3.ZERO
	play_time = 0.0
	poi_states = {}
	truck_stash = []
	exploration = null
	exploration_poi = null
	save_game()


func poi_state(poi_id: String) -> PoiState:
	if not poi_states.has(poi_id):
		poi_states[poi_id] = PoiState.new()
	return poi_states[poi_id]


## The truck stays parked where it is, so returning rebuilds the overworld at the same spot.
func start_exploration(poi: PoiData) -> void:
	exploration = ExplorationSession.new(poi.id, poi_state(poi.id))
	exploration_poi = poi
	start_position = truck_world_position
	start_yaw = truck_yaw
	save_game()


func unload_at_truck() -> void:
	if exploration == null:
		return
	ItemStacks.merge(truck_stash, exploration.bank())
	save_game()


## Leaving only happens at the truck, so whatever is carried gets unloaded on the way out.
func end_exploration() -> void:
	unload_at_truck()
	exploration = null
	exploration_poi = null
	save_game()


func save_game() -> void:
	if not saving_enabled:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("could not write save: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(SaveGame.to_json(world_seed, visited_pois, truck_world_position, truck_yaw, {
		"play_time": play_time,
		"poi_states": poi_states,
		"stash": truck_stash,
		"character": character_id,
	}))


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
	play_time = data.play_time
	poi_states = data.poi_states
	truck_stash = data.stash
	if CharacterOptions.is_valid(data.character):
		character_id = data.character
	has_save = true
