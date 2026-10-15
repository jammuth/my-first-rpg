class_name ScanRules
extends RefCounted

## What the drone's always-on scan counts as seen. The scene supplies the parts that need the
## engine (is it on screen, what does a ray hit); these are the rules around them.

const RANGE := 25.0
## A line-of-sight ray may hit the target's own collider, so a hit this close to its edge still counts.
const HIT_SLACK := 0.75
## How far out towards its edge (as a share of its radius) the side rays aim.
const SIDE_REACH := 0.6


static func in_range(explorer: Vector2, target: Vector2) -> bool:
	return explorer.distance_to(target) <= RANGE


## `hit` is where the ray towards the target stopped (x/z), or null if it hit nothing.
static func unobstructed(hit: Variant, target: Vector2, target_radius: float) -> bool:
	return hit == null or (hit as Vector2).distance_to(target) <= target_radius + HIT_SLACK


## Where to aim line-of-sight rays (x/z): the centre, then either side of the target as seen from
## `viewer`, so something half hidden behind a corner still counts once any part of it shows.
static func probe_points(target: Vector2, radius: float, viewer: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = [target]
	var to := target - viewer
	if radius <= 0.0 or to.length() < 0.001:
		return points
	var side := Vector2(-to.y, to.x).normalized() * radius * SIDE_REACH
	points.append(target + side)
	points.append(target - side)
	return points


## Marks everything in `visible_ids` as seen and returns the ones seen for the first time, in order.
static func record(visible_ids: Array[String], seen: Dictionary) -> Array[String]:
	var first: Array[String] = []
	for id in visible_ids:
		if not seen.has(id):
			seen[id] = true
			first.append(id)
	return first
