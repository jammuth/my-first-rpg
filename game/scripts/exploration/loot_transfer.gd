class_name LootTransfer
extends RefCounted

## Moving stacks between a container's contents (a plain stack list) and the bag.


## Takes as much of contents[index] as fits; the rest stays behind. Returns how many moved.
static func take(bag: Bag, contents: Array[Dictionary], index: int) -> int:
	var stack := contents[index]
	var left := bag.add(stack.id, stack.count)
	var moved: int = stack.count - left
	if left == 0:
		contents.remove_at(index)
	else:
		stack.count = left
	return moved


## Takes every stack in order until the bag is full. Returns how many items moved.
static func take_all(bag: Bag, contents: Array[Dictionary]) -> int:
	var moved := 0
	var i := 0
	while i < contents.size():
		var before := contents.size()
		moved += take(bag, contents, i)
		if contents.size() == before:
			i += 1
	return moved


## Moves a bag slot's stack into the container (containers have no slot limit).
static func drop(bag: Bag, slot: int, contents: Array[Dictionary]) -> void:
	var stack := bag.take_slot(slot)
	if not stack.is_empty():
		contents.append(stack)
