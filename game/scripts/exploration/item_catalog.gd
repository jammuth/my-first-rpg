class_name ItemCatalog
extends RefCounted

## Every scrap item: display name, rarity, stack size and what it's made of. What it breaks down
## into at the truck, and how long that takes, follow from its material and rarity.
## Placeholder content until the economy is tuned alongside drone building.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC }

const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic"]
const RARITY_COLORS := [Color("9a9a9a"), Color("3fbf5a"), Color("3a8ee6"), Color("b05ce6")]
const ELEMENTS := ["metal", "circuitry", "polymer", "power", "core"]
## Seconds of play time to break down one item, by rarity.
const REFINE_TIME := [10.0, 20.0, 45.0, 90.0]
## Units of an item's main element per item, by rarity; its secondary element gives half.
const MAIN_YIELD := [2, 4, 7, 12]
## Epic items also give this much of the rare core element.
const EPIC_CORE := 1

const ITEMS := {
	"scrap_metal": {"name": "Scrap Metal", "rarity": Rarity.COMMON, "stack": 20, "main": "metal"},
	"rusted_bolts": {"name": "Rusted Bolts", "rarity": Rarity.COMMON, "stack": 30, "main": "metal"},
	"plastic_scraps": {"name": "Plastic Scraps", "rarity": Rarity.COMMON, "stack": 20, "main": "polymer"},
	"wiring": {"name": "Wiring", "rarity": Rarity.COMMON, "stack": 15, "main": "circuitry", "secondary": "polymer"},
	"circuit_board": {"name": "Circuit Board", "rarity": Rarity.UNCOMMON, "stack": 10, "main": "circuitry"},
	"battery": {"name": "Battery", "rarity": Rarity.UNCOMMON, "stack": 8, "main": "power", "secondary": "metal"},
	"servo_motor": {"name": "Servo Motor", "rarity": Rarity.UNCOMMON, "stack": 5, "main": "metal", "secondary": "circuitry"},
	"rubber_hose": {"name": "Rubber Hose", "rarity": Rarity.UNCOMMON, "stack": 10, "main": "polymer"},
	"sensor_module": {"name": "Sensor Module", "rarity": Rarity.RARE, "stack": 5, "main": "circuitry", "secondary": "power"},
	"power_cell": {"name": "Power Cell", "rarity": Rarity.RARE, "stack": 5, "main": "power"},
	"alloy_plating": {"name": "Alloy Plating", "rarity": Rarity.RARE, "stack": 5, "main": "metal", "secondary": "polymer"},
	"drone_core": {"name": "Drone Core", "rarity": Rarity.EPIC, "stack": 1, "main": "circuitry", "secondary": "power"},
	"fusion_coil": {"name": "Fusion Coil", "rarity": Rarity.EPIC, "stack": 2, "main": "power", "secondary": "metal"},
}


static func has(id: String) -> bool:
	return ITEMS.has(id)


## Unknown ids (from a newer or edited save) still display and stack, as common singles.
static func item_name(id: String) -> String:
	return ITEMS[id].name if ITEMS.has(id) else id.capitalize()


static func rarity(id: String) -> Rarity:
	return ITEMS[id].rarity if ITEMS.has(id) else Rarity.COMMON


static func stack_size(id: String) -> int:
	return ITEMS[id].stack if ITEMS.has(id) else 1


static func rarity_color(id: String) -> Color:
	return RARITY_COLORS[rarity(id)]


static func ids_of(r: Rarity) -> Array[String]:
	var out: Array[String] = []
	for id: String in ITEMS:
		if ITEMS[id].rarity == r:
			out.append(id)
	return out


## Elements from breaking down one item: {element: amount}. Unknown items give nothing.
static func yield_of(id: String) -> Dictionary:
	if not ITEMS.has(id):
		return {}
	var item: Dictionary = ITEMS[id]
	var main: int = MAIN_YIELD[item.rarity]
	var out := {item.main: main}
	if item.has("secondary"):
		out[item.secondary] = out.get(item.secondary, 0) + maxi(1, main / 2)
	if item.rarity == Rarity.EPIC:
		out["core"] = out.get("core", 0) + EPIC_CORE
	return out


static func refine_time(id: String) -> float:
	return REFINE_TIME[rarity(id)]


static func yield_text(id: String) -> String:
	var parts: Array[String] = []
	var y := yield_of(id)
	for element: String in ELEMENTS:
		if y.has(element):
			parts.append("%d %s" % [y[element], element])
	return ", ".join(parts) if not parts.is_empty() else "nothing"


## One line about an item for the loot window's detail bar.
static func describe(id: String) -> String:
	if not ITEMS.has(id):
		return "%s  ·  Unknown scrap" % item_name(id)
	return "%s  ·  %s  ·  stacks to %d  ·  Breaks down into %s in %ds" % [item_name(id),
		RARITY_NAMES[rarity(id)], stack_size(id), yield_text(id), int(refine_time(id))]
