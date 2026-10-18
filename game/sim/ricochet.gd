class_name Ricochet
## A BB meeting a hard surface bounces off it (the browser game's sim/ricochet.ts, M20): the part of its velocity into
## the surface comes back scaled by the material's restitution, the part along it by `slide`, the direction scatters a
## little and the hop-up's backspin is lost. Pure apart from `rng` (the match's seeded stream; null: no scatter).


## Bounces `bb`, now at the surface `hit` met, off it. Returns false if it stops there instead (a soft material, too
## slow, or out of bounces); the caller then retires it.
static func bounce(bb: BB, hit: RayHit, cfg: RicochetConfig, rng: RandomNumberGenerator) -> bool:
	var e := cfg.restitution(hit.surface)
	if not (e > 0.0) or bb.bounces >= cfg.max_bounces:
		return false
	var n := hit.normal
	var v := bb.velocity
	var into := v.dot(n)
	if into >= 0.0:
		return false # grazing the back of a face: nothing to bounce off
	# Along the surface (friction), plus the bounce back out.
	var out_v := (v - n * into) * cfg.slide - n * (into * e)
	var speed := out_v.length()
	if speed < cfg.min_speed:
		return false
	# Scatter, then keep the speed and make sure it still leaves the surface.
	if rng != null:
		out_v += Vector3(rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0, rng.randf() * 2.0 - 1.0) * (cfg.scatter * speed)
	var leaving := out_v.dot(n)
	if leaving <= 0.0:
		out_v -= n * (2.0 * leaving) # scattered back into the surface: mirror that part out again
	bb.velocity = out_v * (speed / maxf(1e-9, out_v.length()))
	bb.position += n * cfg.lift_off
	bb.spin *= cfg.spin_kept
	bb.bounces += 1
	return true
