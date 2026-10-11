class_name FrameStats
extends RefCounted

## Rolling frame-time statistics (milliseconds).

var _samples := PackedFloat32Array()
var _capacity: int


func _init(capacity: int = 240) -> void:
	_capacity = capacity


func push(ms: float) -> void:
	_samples.append(ms)
	if _capacity > 0 and _samples.size() > _capacity:
		_samples = _samples.slice(_samples.size() - _capacity)


func count() -> int:
	return _samples.size()


func average() -> float:
	if _samples.is_empty():
		return 0.0
	var total := 0.0
	for s in _samples:
		total += s
	return total / _samples.size()


## Frame time that `fraction` of frames were at or under (0.99 = p99).
func percentile(fraction: float) -> float:
	if _samples.is_empty():
		return 0.0
	var sorted := _samples.duplicate()
	sorted.sort()
	return sorted[clampi(int(ceil(fraction * sorted.size())) - 1, 0, sorted.size() - 1)]


func worst() -> float:
	return percentile(1.0)


## How many frames took longer than `ms` (e.g. 16.7 for a missed 60 fps frame).
func count_over(ms: float) -> int:
	var n := 0
	for s in _samples:
		if s > ms:
			n += 1
	return n
