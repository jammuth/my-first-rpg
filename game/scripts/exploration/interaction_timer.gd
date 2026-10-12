class_name InteractionTimer
extends RefCounted

## A search or unlock in progress. It runs by itself once started; the scene cancels it when the
## explorer moves, presses interact again, or loses the target.

var target: Interactable
var elapsed := 0.0


func _init(t: Interactable) -> void:
	target = t


func fraction() -> float:
	return 1.0 if target.duration <= 0.0 else clampf(elapsed / target.duration, 0.0, 1.0)


## Returns true on the tick it finishes.
func advance(delta: float) -> bool:
	if done():
		return false
	elapsed += delta
	return done()


func done() -> bool:
	return elapsed >= target.duration


## The search stops when the explorer moves, presses interact again, or would now pick another target.
static func should_cancel(moving: bool, interact_pressed: bool, current: Interactable,
		picked: Interactable) -> bool:
	return moving or interact_pressed or picked != current
