class_name Aiming
## Aiming down sights (the browser game's sim/aiming.ts, M84): every replica aims through its iron sights. Not while
## reloading, bringing a replica up or with it holstered (the sight comes back up afterwards if the button is still held;
## an aim press draws a holstered replica: Armament). Aiming slows you to walking pace and rules out sprinting
## (Movement), and the sight comes up over aim_raise_time, tightening the aim as it does (Accuracy). Call before the
## movement step, for characters in play.


static func step(c: Character, cmd: PlayerCommand, cfg: MovementConfig, dt: float) -> void:
	var a := c.armament
	# Reload and draw are as the last tick left them: a reload started this tick lowers the sight on the next.
	# Not mid-vault: an aim held through one comes up again after it (BP5).
	c.aiming = cmd.aim and not a.holstered and not a.reloading() and not a.drawing() and not c.vault.active
	var raise := dt / cfg.aim_raise_time
	c.aim_raise = minf(1.0, c.aim_raise + raise) if c.aiming else maxf(0.0, c.aim_raise - raise)
