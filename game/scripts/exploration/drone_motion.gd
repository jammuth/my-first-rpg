class_name DroneMotion
extends RefCounted

## Where the exploration drone hovers and how it gets there. Pure maths, world space. The scene
## measures clearance with the physics engine; the choices made from it live here.

## Hover spot relative to the explorer: beside a shoulder (the right by default), just above head
## height. Further back puts it between the chase camera and the explorer, where it blocks the view.
const OFFSET_BACK := 0.3
const OFFSET_SIDE := 1.1
const HOVER_HEIGHT := 2.0
const BOB_HEIGHT := 0.12
const BOB_SPEED := 2.2
## Higher = catches up with its hover spot faster.
const SHARPNESS := 4.0
## Beyond this it snaps back (after a respawn or a teleport) instead of flying across the map.
const SNAP_DISTANCE := 20.0
## Where clearance is measured from: inside the explorer's head, which is always in the open.
const HEAD_HEIGHT := 1.5
## The drone's collision radius for clearance checks.
const RADIUS := 0.4
## Moving slower than this (m/s) while short of its spot counts as stuck; after STUCK_TIME seconds
## it reappears at the spot.
const STUCK_MOVE := 0.05
const STUCK_TIME := 0.4
const RIGHT := 1
const LEFT := -1


## `facing` is the explorer's unit x/z facing; `side` is RIGHT or LEFT.
static func hover_point(explorer: Vector3, facing: Vector2, time: float, side := RIGHT) -> Vector3:
	var right := Vector2(-facing.y, facing.x)
	var flat := Vector2(explorer.x, explorer.z) - facing * OFFSET_BACK + right * OFFSET_SIDE * side
	return Vector3(flat.x, explorer.y + HOVER_HEIGHT + sin(time * BOB_SPEED) * BOB_HEIGHT, flat.y)


static func head(explorer: Vector3) -> Vector3:
	return explorer + Vector3.UP * HEAD_HEIGHT


## Which shoulder to hover by. `*_clear` is the share (0–1) of the way from the head to that side's
## hover point the drone can fly before touching something. It stays on its current side while that
## side is clear, so it doesn't flip back and forth along a wall.
static func choose_side(current: int, right_clear: float, left_clear: float) -> int:
	var here := right_clear if current == RIGHT else left_clear
	var there := left_clear if current == RIGHT else right_clear
	if here >= 1.0 or here >= there:
		return current
	return -current


## The hover point pulled in towards the head as far as `clear` allows, so it never sits in a wall.
static func pull_in(head_point: Vector3, hover: Vector3, clear: float) -> Vector3:
	return head_point.lerp(hover, clampf(clear, 0.0, 1.0))


## Eases towards the hover point, frame-rate independent.
static func step(current: Vector3, target: Vector3, delta: float) -> Vector3:
	if current.distance_to(target) > SNAP_DISTANCE:
		return target
	return current.lerp(target, 1.0 - exp(-SHARPNESS * delta))
