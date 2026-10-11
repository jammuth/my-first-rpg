class_name ItemStacks
extends RefCounted

## Items are {"id": String, "count": int}. Stack limits and bag capacity arrive with the bag (step 5).


static func merge(into: Array[Dictionary], items: Array[Dictionary]) -> void:
	for item in items:
		var existing := find(into, item.id)
		if existing.is_empty():
			into.append({"id": item.id, "count": item.count})
		else:
			existing.count += item.count


## Returns the stack itself (not a copy) so callers can change its count, or {} when absent.
static func find(stacks: Array[Dictionary], id: String) -> Dictionary:
	for stack in stacks:
		if stack.id == id:
			return stack
	return {}


static func total(stacks: Array[Dictionary]) -> int:
	var n := 0
	for stack in stacks:
		n += stack.count
	return n
