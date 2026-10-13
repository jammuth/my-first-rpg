class_name Bag
extends RefCounted

## Slot-based bag: each slot is empty ({}) or one stack {"id", "count"} no bigger than the item's
## stack size. No grid packing, so every item takes exactly one slot.

const SLOTS := 8

var slots: Array[Dictionary] = []


func _init(capacity := SLOTS) -> void:
	slots.resize(capacity)
	for i in capacity:
		slots[i] = {}


func capacity() -> int:
	return slots.size()


func used() -> int:
	return slots.filter(func(s: Dictionary) -> bool: return not s.is_empty()).size()


func is_empty() -> bool:
	return used() == 0


## How many of `id` would fit: room on its partial stacks plus whole empty slots.
func space_for(id: String) -> int:
	var size := ItemCatalog.stack_size(id)
	var room := 0
	for s in slots:
		if s.is_empty():
			room += size
		elif s.id == id:
			room += size - s.count
	return room


## Tops up partial stacks first, then fills empty slots. Returns how many didn't fit.
func add(id: String, count: int) -> int:
	var size := ItemCatalog.stack_size(id)
	for s in slots:
		if count == 0:
			return 0
		if not s.is_empty() and s.id == id and s.count < size:
			var moved := mini(count, size - s.count)
			s.count += moved
			count -= moved
	for i in slots.size():
		if count == 0:
			return 0
		if slots[i].is_empty():
			var moved := mini(count, size)
			slots[i] = {"id": id, "count": moved}
			count -= moved
	return count


func take_slot(i: int) -> Dictionary:
	var s := slots[i]
	slots[i] = {}
	return s


func swap(a: int, b: int) -> void:
	var tmp := slots[a]
	slots[a] = slots[b]
	slots[b] = tmp


## The contents merged into one stack per item, for the truck stash.
func items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in slots:
		if not s.is_empty():
			var one: Array[Dictionary] = [s]
			ItemStacks.merge(out, one)
	return out


func clear() -> void:
	for i in slots.size():
		slots[i] = {}
