class_name PoiCatalog
extends RefCounted

## Pieces POI layouts are built from. `size` is the X/Z footprint in metres after `scale` (before
## any rotation); it drives road-lane clearing and overlap checks, and tests keep it honest against
## the real model bounds. `ruinable` pieces can be broken off by the weathering shader.

const M := "res://assets/models/"

const PIECES := {
	# Kenney industrial (1 unit ~ 1 tile; scaled up to compound size).
	"i_a": {"path": M + "industrial/building-a.glb", "scale": 7.0, "size": Vector2(14.6, 8.7), "solid": true, "ruinable": true},
	"i_b": {"path": M + "industrial/building-b.glb", "scale": 7.0, "size": Vector2(14.6, 8.8), "solid": true, "ruinable": true},
	"i_d": {"path": M + "industrial/building-d.glb", "scale": 7.0, "size": Vector2(6.2, 9.9), "solid": true, "ruinable": true},
	"i_e": {"path": M + "industrial/building-e.glb", "scale": 7.0, "size": Vector2(11.8, 9.0), "solid": true, "ruinable": true},
	"i_f": {"path": M + "industrial/building-f.glb", "scale": 7.0, "size": Vector2(12.5, 9.0), "solid": true, "ruinable": true},
	"i_h": {"path": M + "industrial/building-h.glb", "scale": 7.0, "size": Vector2(9.2, 9.2), "solid": true, "ruinable": true},
	"i_k": {"path": M + "industrial/building-k.glb", "scale": 7.0, "size": Vector2(9.1, 6.4), "solid": true, "ruinable": true},
	"i_o": {"path": M + "industrial/building-o.glb", "scale": 7.0, "size": Vector2(6.2, 8.7), "solid": true, "ruinable": true},
	"i_r": {"path": M + "industrial/building-r.glb", "scale": 7.0, "size": Vector2(17.4, 8.9), "solid": true, "ruinable": true},
	"chimney_large": {"path": M + "industrial/chimney-large.glb", "scale": 7.0, "size": Vector2(7.6, 7.6), "solid": true, "ruinable": true},
	"chimney_medium": {"path": M + "industrial/chimney-medium.glb", "scale": 7.0, "size": Vector2(3.2, 3.2), "solid": true, "ruinable": true},
	"tank_large": {"path": M + "industrial/detail-tank-large.glb", "scale": 5.0, "size": Vector2(7.6, 8.3), "solid": true, "ruinable": false},
	"tank": {"path": M + "industrial/detail-tank.glb", "scale": 7.0, "size": Vector2(6.0, 3.6), "solid": true, "ruinable": false},
	"k_water_tower": {"path": M + "industrial/water-tower.glb", "scale": 7.0, "size": Vector2(6.0, 5.8), "solid": true, "ruinable": true},
	# Kenney commercial / suburban.
	"c_a": {"path": M + "commercial/building-a.glb", "scale": 7.0, "size": Vector2(6.2, 6.6), "solid": true, "ruinable": true},
	"c_b": {"path": M + "commercial/building-b.glb", "scale": 7.0, "size": Vector2(6.8, 6.6), "solid": true, "ruinable": true},
	"c_c": {"path": M + "commercial/building-c.glb", "scale": 7.0, "size": Vector2(6.2, 7.6), "solid": true, "ruinable": true},
	"c_d": {"path": M + "commercial/building-d.glb", "scale": 7.0, "size": Vector2(5.9, 6.3), "solid": true, "ruinable": true},
	"c_e": {"path": M + "commercial/building-e.glb", "scale": 7.0, "size": Vector2(11.5, 7.1), "solid": true, "ruinable": true},
	"c_f": {"path": M + "commercial/building-f.glb", "scale": 7.0, "size": Vector2(5.9, 7.2), "solid": true, "ruinable": true},
	"c_g": {"path": M + "commercial/building-g.glb", "scale": 7.0, "size": Vector2(6.8, 6.4), "solid": true, "ruinable": true},
	"c_h": {"path": M + "commercial/building-h.glb", "scale": 7.0, "size": Vector2(6.2, 7.1), "solid": true, "ruinable": true},
	"s_a": {"path": M + "suburban/building-type-a.glb", "scale": 7.0, "size": Vector2(9.1, 7.2), "solid": true, "ruinable": true},
	"s_c": {"path": M + "suburban/building-type-c.glb", "scale": 7.0, "size": Vector2(9.0, 7.2), "solid": true, "ruinable": true},
	"s_e": {"path": M + "suburban/building-type-e.glb", "scale": 7.0, "size": Vector2(9.1, 7.2), "solid": true, "ruinable": true},
	"s_h": {"path": M + "suburban/building-type-h.glb", "scale": 7.0, "size": Vector2(9.1, 6.4), "solid": true, "ruinable": true},
	"s_k": {"path": M + "suburban/building-type-k.glb", "scale": 7.0, "size": Vector2(6.4, 7.1), "solid": true, "ruinable": true},
	"s_n": {"path": M + "suburban/building-type-n.glb", "scale": 7.0, "size": Vector2(12.5, 9.7), "solid": true, "ruinable": true},
	"s_fence": {"path": M + "suburban/fence-1x3.glb", "scale": 7.0, "size": Vector2(9.0, 3.1), "solid": false, "ruinable": false},
	# Quaternius farm buildings (already in metres).
	"barn": {"path": M + "farm/Barn.fbx", "scale": 1.1, "size": Vector2(8.5, 9.0), "solid": true, "ruinable": true},
	"big_barn": {"path": M + "farm/BigBarn.fbx", "scale": 1.1, "size": Vector2(8.5, 9.0), "solid": true, "ruinable": true},
	"small_barn": {"path": M + "farm/SmallBarn.fbx", "scale": 1.1, "size": Vector2(6.7, 6.9), "solid": true, "ruinable": true},
	"open_barn": {"path": M + "farm/OpenBarn.fbx", "scale": 1.1, "size": Vector2(6.3, 6.8), "solid": true, "ruinable": true},
	"silo": {"path": M + "farm/Silo.fbx", "scale": 1.1, "size": Vector2(4.0, 3.9), "solid": true, "ruinable": true},
	"silo_house": {"path": M + "farm/Silo_House.fbx", "scale": 1.1, "size": Vector2(5.9, 3.9), "solid": true, "ruinable": true},
	"windmill": {"path": M + "farm/TowerWindmill.fbx", "scale": 1.1, "size": Vector2(8.7, 5.5), "solid": true, "ruinable": false},
	"farm_water_tower": {"path": M + "farm/WaterTower.fbx", "scale": 1.1, "size": Vector2(2.8, 2.7), "solid": true, "ruinable": false},
	"well": {"path": M + "farm/Well.fbx", "scale": 1.1, "size": Vector2(1.4, 1.6), "solid": true, "ruinable": false},
	"coop": {"path": M + "farm/ChickenCoop.fbx", "scale": 1.1, "size": Vector2(2.7, 2.4), "solid": true, "ruinable": true},
	"farm_fence": {"path": M + "farm/Fence.fbx", "scale": 1.1, "size": Vector2(6.5, 0.2), "solid": false, "ruinable": false},
	"farm_fence_2": {"path": M + "farm/Fence2.fbx", "scale": 1.1, "size": Vector2(6.5, 0.2), "solid": false, "ruinable": false},
	# Quaternius zombie-apocalypse props and vehicles (metres).
	"barrel": {"path": M + "zombie/Barrel.gltf", "scale": 1.0, "size": Vector2(0.7, 0.7), "solid": false, "ruinable": false},
	"container_green": {"path": M + "zombie/Container_Green.gltf", "scale": 1.0, "size": Vector2(5.7, 2.6), "solid": true, "ruinable": false},
	"container_red": {"path": M + "zombie/Container_Red.gltf", "scale": 1.0, "size": Vector2(5.7, 2.6), "solid": true, "ruinable": false},
	"couch": {"path": M + "zombie/Couch.gltf", "scale": 1.0, "size": Vector2(3.0, 1.2), "solid": false, "ruinable": false},
	"hydrant": {"path": M + "zombie/FireHydrant.gltf", "scale": 1.0, "size": Vector2(0.5, 0.4), "solid": false, "ruinable": false},
	"pallet": {"path": M + "zombie/Pallet.gltf", "scale": 1.0, "size": Vector2(0.9, 1.2), "solid": false, "ruinable": false},
	"pallet_broken": {"path": M + "zombie/Pallet_Broken.gltf", "scale": 1.0, "size": Vector2(0.9, 1.2), "solid": false, "ruinable": false},
	"pipes": {"path": M + "zombie/Pipes.gltf", "scale": 1.0, "size": Vector2(0.8, 3.4), "solid": false, "ruinable": false},
	"plastic_barrier": {"path": M + "zombie/PlasticBarrier.gltf", "scale": 1.5, "size": Vector2(1.6, 0.5), "solid": false, "ruinable": false},
	"street_light": {"path": M + "zombie/StreetLights.gltf", "scale": 1.0, "size": Vector2(0.4, 2.9), "solid": false, "ruinable": false},
	"town_sign": {"path": M + "zombie/TownSign.gltf", "scale": 1.0, "size": Vector2(6.0, 1.7), "solid": false, "ruinable": false},
	"barricade": {"path": M + "zombie/TrafficBarrier_1.gltf", "scale": 1.3, "size": Vector2(2.0, 1.1), "solid": false, "ruinable": false},
	"barricade_low": {"path": M + "zombie/TrafficBarrier_2.gltf", "scale": 1.3, "size": Vector2(2.0, 1.0), "solid": false, "ruinable": false},
	"cone": {"path": M + "zombie/TrafficCone_1.gltf", "scale": 1.0, "size": Vector2(0.5, 0.5), "solid": false, "ruinable": false},
	"trash": {"path": M + "zombie/TrashBag_1.gltf", "scale": 1.0, "size": Vector2(0.5, 0.5), "solid": false, "ruinable": false},
	"trash_pile": {"path": M + "zombie/TrashBag_2.gltf", "scale": 1.0, "size": Vector2(0.9, 0.5), "solid": false, "ruinable": false},
	"z_water_tower": {"path": M + "zombie/WaterTower.gltf", "scale": 1.3, "size": Vector2(3.4, 3.5), "solid": true, "ruinable": false},
	"tyres": {"path": M + "zombie/Wheels_Stack.gltf", "scale": 1.6, "size": Vector2(1.1, 0.9), "solid": false, "ruinable": false},
	"rubble_block": {"path": M + "zombie/CinderBlock.gltf", "scale": 3.5, "size": Vector2(1.6, 0.7), "solid": false, "ruinable": false},
	"pickup": {"path": M + "zombie/Vehicle_Pickup.gltf", "scale": 1.0, "size": Vector2(2.3, 5.2), "solid": true, "ruinable": false},
	"pickup_armored": {"path": M + "zombie/Vehicle_Pickup_Armored.gltf", "scale": 1.0, "size": Vector2(2.7, 5.5), "solid": true, "ruinable": false},
	"sports": {"path": M + "zombie/Vehicle_Sports.gltf", "scale": 1.0, "size": Vector2(2.7, 5.7), "solid": true, "ruinable": false},
	"van": {"path": M + "zombie/Vehicle_Truck.gltf", "scale": 1.0, "size": Vector2(2.7, 5.3), "solid": true, "ruinable": false},
	"van_armored": {"path": M + "zombie/Vehicle_Truck_Armored.gltf", "scale": 1.0, "size": Vector2(3.0, 5.6), "solid": true, "ruinable": false},
}

## Scattered around a ruined building's base.
const RUBBLE: Array[String] = ["rubble_block", "rubble_block", "pallet_broken", "trash_pile"]


static func piece(key: String) -> Dictionary:
	return PIECES[key]


static func radius(key: String) -> float:
	return (PIECES[key].size as Vector2).length() * 0.5
