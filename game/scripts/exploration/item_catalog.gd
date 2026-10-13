class_name ItemCatalog
extends RefCounted

## Every scrap item: display name, rarity, stack size and what it breaks down into at the truck.
## Placeholder content until the economy is tuned alongside drone building.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC }

const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Epic"]
const RARITY_COLORS := [Color("9a9a9a"), Color("3fbf5a"), Color("3a8ee6"), Color("b05ce6")]
const ELEMENTS := ["metal", "circuitry", "polymer", "power", "core"]

const ITEMS := {
	"scrap_metal": {"name": "Scrap Metal", "rarity": Rarity.COMMON, "stack": 20, "yield": {"metal": 2}},
	"rusted_bolts": {"name": "Rusted Bolts", "rarity": Rarity.COMMON, "stack": 30, "yield": {"metal": 1}},
	"plastic_scraps": {"name": "Plastic Scraps", "rarity": Rarity.COMMON, "stack": 20, "yield": {"polymer": 2}},
	"wiring": {"name": "Wiring", "rarity": Rarity.COMMON, "stack": 15, "yield": {"circuitry": 1, "polymer": 1}},
	"circuit_board": {"name": "Circuit Board", "rarity": Rarity.UNCOMMON, "stack": 10, "yield": {"circuitry": 3}},
	"battery": {"name": "Battery", "rarity": Rarity.UNCOMMON, "stack": 8, "yield": {"power": 2, "metal": 1}},
	"servo_motor": {"name": "Servo Motor", "rarity": Rarity.UNCOMMON, "stack": 5, "yield": {"metal": 2, "circuitry": 2}},
	"rubber_hose": {"name": "Rubber Hose", "rarity": Rarity.UNCOMMON, "stack": 10, "yield": {"polymer": 3}},
	"sensor_module": {"name": "Sensor Module", "rarity": Rarity.RARE, "stack": 5, "yield": {"circuitry": 4, "power": 1}},
	"power_cell": {"name": "Power Cell", "rarity": Rarity.RARE, "stack": 5, "yield": {"power": 4}},
	"alloy_plating": {"name": "Alloy Plating", "rarity": Rarity.RARE, "stack": 5, "yield": {"metal": 5}},
	"drone_core": {"name": "Drone Core", "rarity": Rarity.EPIC, "stack": 1, "yield": {"core": 1, "circuitry": 3, "power": 2}},
	"fusion_coil": {"name": "Fusion Coil", "rarity": Rarity.EPIC, "stack": 2, "yield": {"core": 1, "power": 5}},
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


## One line about an item for the loot window's detail bar.
static func describe(id: String) -> String:
	var parts: Array[String] = []
	if ITEMS.has(id):
		for element: String in ITEMS[id].yield:
			parts.append("%d %s" % [ITEMS[id].yield[element], element])
	var yields := "Breaks down into " + ", ".join(parts) if not parts.is_empty() else "Unknown scrap"
	return "%s  ·  %s  ·  stacks to %d  ·  %s" % [item_name(id), RARITY_NAMES[rarity(id)], stack_size(id), yields]
