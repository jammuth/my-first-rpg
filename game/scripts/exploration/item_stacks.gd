class_name ItemStacks
extends RefCounted

## Merged item stacks {"id": String, "count": int} with no size limit, as the truck stash and saves
## keep them. The bag (Bag) splits them into slots.


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


## Stacks from saved JSON, merging duplicates and skipping malformed entries.
static func read(data: Variant) -> Array[Dictionary]:
	var stacks: Array[Dictionary] = []
	if not data is Array:
		return stacks
	for entry: Variant in data:
		if not (entry is Dictionary and entry.get("id") is String):
			continue
		var count: Variant = entry.get("count")
		if (count is float or count is int) and count >= 1:
			var item: Array[Dictionary] = [{"id": entry.id, "count": int(entry.count)}]
			merge(stacks, item)
	return stacks
