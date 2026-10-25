class_name Leaves
## A BB pushing through a bush's leaves (the browser game's sim/leaves.ts, FO1): having crossed `depth` metres of them
## its speed and backspin drop to leaf_kept_per_metre^depth, and its line is thrown off by up to leaf_scatter_per_metre
## × depth radians, any way round it (an even pick of the angle, so most BBs come out only a little off and a few well
## off). BBStep finds the crossing (Foliage.first_leaves). Pure apart from `rng` (the match's seeded stream; without
## one the BB is only slowed). Allocates nothing.

## A line steeper than this (the share of it straight up or down) is turned about the x axis instead of the vertical.
const LEVEL := 0.9


static func deflect(bb: BB, depth: float, cfg: BallisticsConfig, rng: RandomNumberGenerator) -> void:
	var speed := bb.velocity.length()
	if not (speed > 0.0) or not (depth > 0.0):
		return
	var kept := pow(cfg.leaf_kept_per_metre, depth)
	bb.spin *= kept
	var u := bb.velocity / speed
	var n := u
	if rng != null:
		var angle := cfg.leaf_scatter_per_metre * depth * rng.randf()
		var round_at := rng.randf() * TAU
		# Two unit directions square to the line and to each other: across it from the axis least along it.
		var a := u.cross(Vector3.UP if absf(u.y) < LEVEL else Vector3.RIGHT).normalized()
		var b := u.cross(a)
		var s := sin(angle)
		n = u * cos(angle) + a * (cos(round_at) * s) + b * (sin(round_at) * s)
	bb.velocity = n * (speed * kept)
