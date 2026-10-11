class_name TruckMotion
extends RefCounted


## Returns the new forward speed. Throttle is -1..1; reversing direction counts as braking.
static func step_speed(speed: float, throttle: float, delta: float, max_speed: float,
		reverse_speed: float, acceleration: float, braking: float) -> float:
	var target := throttle * (max_speed if throttle >= 0.0 else reverse_speed)
	var speeding_up := absf(target) > absf(speed) and (is_zero_approx(speed) or signf(target) == signf(speed))
	return move_toward(speed, target, (acceleration if speeding_up else braking) * delta)


## Pitch (nose up positive, about +X) and roll (right side up positive, about +Z) from terrain
## heights under the truck's front/back/left/right sample points.
static func tilt_from_heights(front: float, back: float, left: float, right: float,
		length: float, width: float) -> Vector2:
	return Vector2(atan2(front - back, length), atan2(right - left, width))


## True when the ground `distance` ahead rises more steeply than `max_grade` (rise over run).
static func blocked_by_slope(height_here: float, height_ahead: float, distance: float,
		max_grade: float) -> bool:
	return (height_ahead - height_here) / distance > max_grade
