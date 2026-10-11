class_name ExplorerMotion
extends RefCounted

## Below this speed (m/s) the explorer counts as standing still.
const IDLE_SPEED := 0.15


## Stick/keys (x right, y back, as Input.get_vector returns) to a world direction relative to the
## camera's yaw. Diagonal keys are normalised; analog deflection under 1 is kept.
static func move_direction(input: Vector2, camera_yaw: float) -> Vector3:
	var local := Vector3(input.x, 0.0, input.y)
	if local.length() > 1.0:
		local = local.normalized()
	return Basis(Vector3.UP, camera_yaw) * local


static func target_speed(deflection: float, sprinting: bool, walk_speed: float, run_speed: float) -> float:
	return clampf(deflection, 0.0, 1.0) * (run_speed if sprinting else walk_speed)


## Moves horizontal velocity towards the target at a fixed rate, so starts and stops stay snappy.
static func approach(velocity: Vector3, target: Vector3, acceleration: float, delta: float) -> Vector3:
	return velocity.move_toward(target, acceleration * delta)


## Yaw for a model whose front is +Z (glTF convention) to face `direction`, eased the short way round.
static func turn_towards(yaw: float, direction: Vector3, sharpness: float, delta: float) -> float:
	if Vector2(direction.x, direction.z).length_squared() < 0.0001:
		return yaw
	var target := atan2(direction.x, direction.z)
	return lerp_angle(yaw, target, 1.0 - exp(-sharpness * delta))


## Drops the part of a horizontal velocity pushing out through a wall whose outward normal is
## `normal`, so the explorer slides along it (or stops, head on) instead of running in place.
static func slide_along(velocity: Vector2, normal: Vector2) -> Vector2:
	var into := velocity.dot(normal)
	return velocity - normal * into if into > 0.0 else velocity


static func animation_for(speed: float, walk_speed: float) -> String:
	if speed < IDLE_SPEED:
		return ExplorerAnimations.IDLE
	if speed <= walk_speed * 1.25:
		return ExplorerAnimations.WALK
	return ExplorerAnimations.RUN
