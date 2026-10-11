class_name TruckMotion
extends RefCounted


## Returns the new forward speed. Throttle is -1..1; reversing direction counts as braking.
static func step_speed(speed: float, throttle: float, delta: float, max_speed: float,
		reverse_speed: float, acceleration: float, braking: float) -> float:
	var target := throttle * (max_speed if throttle >= 0.0 else reverse_speed)
	var speeding_up := absf(target) > absf(speed) and (is_zero_approx(speed) or signf(target) == signf(speed))
	return move_toward(speed, target, (acceleration if speeding_up else braking) * delta)
