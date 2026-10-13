class_name Refinery
extends RefCounted

## Breaks scrap down into elements at the truck, one item at a time per slot, on play time.
## Stacks wait in a queue; an idle slot pulls the next one. Upgrades will add slots later.

const DEFAULT_SLOTS := 1

## One entry per slot: {} when idle, else {"id", "count", "elapsed"} where elapsed is time spent on
## the item currently being broken down.
var slots: Array[Dictionary] = []
var queue: Array[Dictionary] = []


func _init(slot_count := DEFAULT_SLOTS) -> void:
	set_slot_count(slot_count)


func set_slot_count(n: int) -> void:
	while slots.size() < n:
		slots.append({})
	_fill_idle_slots()


func is_idle() -> bool:
	return queue.is_empty() and slots.all(func(s: Dictionary) -> bool: return s.is_empty())


## Moves a whole stack from the stash to the back of the queue.
func enqueue_from(stash: Array[Dictionary], index: int) -> void:
	var stack := stash[index]
	stash.remove_at(index)
	queue.append({"id": stack.id, "count": stack.count})
	_fill_idle_slots()


## Returns a queued stack to the stash.
func dequeue_to(stash: Array[Dictionary], index: int) -> void:
	var stack := queue[index]
	queue.remove_at(index)
	var back: Array[Dictionary] = [stack]
	ItemStacks.merge(stash, back)


## Stops a slot and returns the items it hasn't finished to the stash; progress on the current item
## is lost. The slot then pulls the next queued stack.
func cancel_slot(stash: Array[Dictionary], i: int) -> void:
	if slots[i].is_empty():
		return
	var back: Array[Dictionary] = [{"id": slots[i].id, "count": slots[i].count}]
	ItemStacks.merge(stash, back)
	slots[i] = {}
	_fill_idle_slots()


## Runs every slot for `delta` seconds and returns the elements produced, {element: amount}.
func advance(delta: float) -> Dictionary:
	var gained := {}
	for i in slots.size():
		var left := delta
		while left > 0.0 and not slots[i].is_empty():
			var s := slots[i]
			var need: float = ItemCatalog.refine_time(s.id) - s.elapsed
			if left < need:
				s.elapsed += left
				break
			left -= need
			var made := ItemCatalog.yield_of(s.id)
			for element: String in made:
				gained[element] = gained.get(element, 0) + made[element]
			s.count -= 1
			s.elapsed = 0.0
			if s.count <= 0:
				slots[i] = _next_from_queue()
	return gained


## 0–1 progress on the item a slot is working on.
func item_progress(i: int) -> float:
	var s := slots[i]
	return 0.0 if s.is_empty() else clampf(s.elapsed / ItemCatalog.refine_time(s.id), 0.0, 1.0)


## Seconds until a slot finishes its whole stack.
func slot_time_left(i: int) -> float:
	var s := slots[i]
	return 0.0 if s.is_empty() else ItemCatalog.refine_time(s.id) * s.count - s.elapsed


## Seconds until everything in the slots and queue is done (with one slot; upgrades share the work).
func total_time_left() -> float:
	var t := 0.0
	for i in slots.size():
		t += slot_time_left(i)
	for q in queue:
		t += ItemCatalog.refine_time(q.id) * q.count
	return t / slots.size()


func to_dict() -> Dictionary:
	return {"slots": slots.duplicate(true), "queue": queue.duplicate(true)}


## Skips malformed entries; a missing or bad save gives an empty refinery with the default slots.
static func from_dict(data: Variant, slot_count := DEFAULT_SLOTS) -> Refinery:
	var r := Refinery.new(slot_count)
	if not data is Dictionary:
		return r
	var saved_slots: Variant = data.get("slots")
	if saved_slots is Array:
		for i in mini(saved_slots.size(), r.slots.size()):
			var entry: Variant = saved_slots[i]
			var stack := ItemStacks.read([entry])
			if not stack.is_empty():
				var elapsed: Variant = entry.get("elapsed")
				stack[0].elapsed = clampf(elapsed, 0.0, ItemCatalog.refine_time(stack[0].id)) if elapsed is float else 0.0
				r.slots[i] = stack[0]
	var saved_queue: Variant = data.get("queue")
	if saved_queue is Array:
		# One at a time: reading the list whole would merge repeats and lose the order.
		for entry: Variant in saved_queue:
			r.queue.append_array(ItemStacks.read([entry]))
	r._fill_idle_slots()
	return r


func _fill_idle_slots() -> void:
	for i in slots.size():
		if slots[i].is_empty():
			slots[i] = _next_from_queue()


func _next_from_queue() -> Dictionary:
	if queue.is_empty():
		return {}
	var q: Dictionary = queue.pop_front()
	return {"id": q.id, "count": q.count, "elapsed": 0.0}
