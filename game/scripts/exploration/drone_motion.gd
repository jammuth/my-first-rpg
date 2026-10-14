class_name DroneMotion
extends RefCounted

## Where the exploration drone hovers and how it gets there. Pure maths, world space.

## Hover spot relative to the explorer: beside the right shoulder, just above head height. Further
## back puts it between the chase camera and the explorer, where it blocks the view.
const OFFSET_BACK := 0.3
const OFFSET_SIDE := 1.1
const HOVER_HEIGHT := 2.0
const BOB_HEIGHT := 0.12
const BOB_SPEED := 2.2
## Higher = catches up with its hover spot faster.
const SHARPNESS := 4.0
## Beyond this it snaps back (after a respawn or a teleport) instead of flying across the map.
const SNAP_DISTANCE := 20.0


## `facing` is the explorer's unit x/z facing.
static func hover_point(explorer: Vector3, facing: Vector2, time: float) -> Vector3:
	var right := Vector2(-facing.y, facing.x)
	var flat := Vector2(explorer.x, explorer.z) - facing * OFFSET_BACK + right * OFFSET_SIDE
	return Vector3(flat.x, explorer.y + HOVER_HEIGHT + sin(time * BOB_SPEED) * BOB_HEIGHT, flat.y)


## Eases towards the hover point, frame-rate independent.
static func step(current: Vector3, target: Vector3, delta: float) -> Vector3:
	if current.distance_to(target) > SNAP_DISTANCE:
		return target
	return current.lerp(target, 1.0 - exp(-SHARPNESS * delta))
