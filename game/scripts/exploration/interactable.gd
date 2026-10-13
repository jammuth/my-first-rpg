class_name Interactable
extends RefCounted

## Something the explorer can use in a level: a search spot, a loot-room door or the truck.
## Positions are world x/z. The scene decides which ones are still available (not yet looted or
## unlocked) and asks pick() for the one to prompt.

enum Kind { CONTAINER, DOOR, TRUCK }

## Seconds to search each container kind (the plan allows 1–3 s).
const SEARCH_TIME := {"barrel": 1.0, "trash": 1.5, "furniture": 1.5, "crate": 2.0, "wreck": 3.0}
## How far off the explorer's facing a target may be and still be picked.
const MAX_FACING_ANGLE := deg_to_rad(70.0)
const TRUCK_RADIUS := 2.0

var id: String
var kind: Kind
## Container kind ("crate", "wreck", …); empty for doors and the truck.
var label: String
var position: Vector2
## Rough size of the thing, so a big wreck and a small barrel compare by how far away their edges are.
var radius: float
var reach: float
## 0 means it happens at once.
var duration: float


static func make(id: String, kind: Kind, position: Vector2, radius: float, reach: float,
		duration: float, label := "") -> Interactable:
	var it := Interactable.new()
	it.id = id
	it.kind = kind
	it.position = position
	it.radius = radius
	it.reach = reach
	it.duration = duration
	it.label = label
	return it


static func from_level(level: ExplorationLevel) -> Array[Interactable]:
	var out: Array[Interactable] = []
	for c in level.containers:
		out.append(make(c.id, Kind.CONTAINER, c.position, c.reach - ExplorationLevel.REACH, c.reach,
			SEARCH_TIME.get(c.kind, 2.0), c.kind))
	for d in level.loot_rooms:
		out.append(make(d.id, Kind.DOOR, d.position, 0.0, ExplorationLevel.REACH + 0.6, 0.0))
	out.append(make("truck", Kind.TRUCK, level.truck_position, TRUCK_RADIUS,
		ExplorationLevel.EXTRACTION_RADIUS, 0.0))
	return out


## The nearest target in reach that the explorer is facing (`facing` is a unit vector), measured to
## each target's edge. Returns null when none qualifies.
static func pick(targets: Array[Interactable], explorer: Vector2, facing: Vector2) -> Interactable:
	var best: Interactable = null
	var best_gap := INF
	for t in targets:
		var to := t.position - explorer
		var dist := to.length()
		if dist > t.reach:
			continue
		# Standing on top of the spot (a door step) counts as facing it.
		if dist > 0.3 and absf(facing.angle_to(to)) > MAX_FACING_ANGLE:
			continue
		var gap := dist - t.radius
		if gap < best_gap:
			best_gap = gap
			best = t
	return best


## `opened`: already searched or unlocked, so using it again just opens the loot window.
func prompt(opened := false) -> String:
	match kind:
		Kind.CONTAINER:
			return "Press E / A to %s the %s" % ["open" if opened else "search", label]
		Kind.DOOR:
			return "Press E / A to %s the loot room" % ["open" if opened else "unlock"]
		_:
			return "Press E / A to use the truck"


func progress_text() -> String:
	return "Searching the %s…" % label


## Which LootTables entry fills it.
func loot_kind() -> String:
	return "loot_room" if kind == Kind.DOOR else label


func title() -> String:
	return "Loot room" if kind == Kind.DOOR else label.capitalize()
