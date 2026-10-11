class_name CharacterOptions
extends RefCounted

## Explorer looks, picked on the main menu. All share the KayKit Rig_Medium skeleton, so one
## animation set drives every option. Each option: base model, meshes to hide, meshes grafted from
## another model (scale/offset are in the bone's space, to fit a different head), meshes to tint.

const SURVIVALIST := "res://assets/characters/Survivalist.glb"
const HOARDER := "res://assets/characters/Hoarder.glb"
## Dusty khaki for the sand mask and scarf.
const KHAKI := Color(0.76, 0.66, 0.46)
const SAND_GEAR: Array[String] = ["Hoarder_FaceMask", "Hoarder_CollarArmor"]

const DEFAULT := "survivalist"
const ORDER: Array[String] = ["survivalist", "drifter", "hoarder"]

const OPTIONS := {
	"survivalist": {
		"label": "Survivalist",
		"base": SURVIVALIST,
		"hide": [],
		# The Survivalist's head is larger than the Hoarder's, so the mask is enlarged and pushed
		# forward to cover his beard and nose.
		"grafts": [
			{"from": HOARDER, "mesh": "Hoarder_FaceMask", "scale": 1.15, "offset": Vector3(0.0, 0.0, 0.04)},
			{"from": HOARDER, "mesh": "Hoarder_CollarArmor"},
		],
	},
	"drifter": {
		"label": "Drifter",
		"base": SURVIVALIST,
		"hide": ["Survivalist_Head"],
		"grafts": [
			{"from": HOARDER, "mesh": "Hoarder_Head"},
			{"from": HOARDER, "mesh": "Hoarder_FaceMask"},
			{"from": HOARDER, "mesh": "Hoarder_CollarArmor"},
		],
	},
	"hoarder": {
		"label": "Hoarder",
		"base": HOARDER,
		"hide": ["Hoarder_FrontPouch_Sword", "Hoarder_Backpack"],
		"grafts": [],
	},
}


static func is_valid(id: String) -> bool:
	return OPTIONS.has(id)


static func label(id: String) -> String:
	return OPTIONS[id].label


## Steps through ORDER, wrapping at both ends.
static func cycle(id: String, step: int) -> String:
	var i := ORDER.find(id)
	return ORDER[wrapi(i + step, 0, ORDER.size())]
