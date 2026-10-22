class_name SquadOrders
## How bot teammates carry out a squad order (the browser game's ai/squadOrders.ts, M22): BotController hands an order
## out (start, end); each tick BotBrain puts an ordered bot in ORDER mode between fights and `move` walks it there. Hold
## here: the spot the giver looks at, the teammates side by side across their view, all looking their way. Follow me and
## Regroup are handed out and kept the same way; where they walk comes with SO2 (until then a bot under one stands).
## Tuning is BotConfig.squad (SquadConfig). Allocates nothing.

## What came of the last order given, for the presentation: CANCELLED, back to the team plan (the order given again, Team
## plan, or no teammate left to take it); ON_PLAN, Team plan with no order in force; NOBODY, no teammate in play to
## take it; NOT_NOW, given while out or between rounds.
enum Notice { NONE, CANCELLED, ON_PLAN, NOBODY, NOT_NOW }

## No spot: hold_point looking at nothing, held_centre with nobody holding.
const NO_SPOT := Vector3(NAN, NAN, NAN)

static var _hit: RayHit = RayHit.new()


## The last order given (BotController.order_outcome, one record reused): by whom, the order in force afterwards (NONE:
## the team plan), and its notice (NONE when an order was taken). `serial` counts every outcome, so a reader sees a new
## one even when it reads the same.
class Outcome:
	extends RefCounted
	var giver: int = -1
	var order: SquadOrder.Kind = SquadOrder.Kind.NONE
	var notice: SquadOrders.Notice = SquadOrders.Notice.NONE
	var serial: int = 0

	func record(giver_id: int, in_force: SquadOrder.Kind, what: SquadOrders.Notice) -> void:
		giver = giver_id
		order = in_force
		notice = what
		serial += 1


## True unless `p` is NO_SPOT.
static func is_spot(p: Vector3) -> bool:
	return not is_nan(p.x)


## `b` carries out `kind` for `giver` as the `slot`th of the teammates given it, from the next tick. A route to an
## earlier order's spot is dropped; any other is the brain's to drop once it turns to the order (a bot on its way to
## cover gets there first).
static func start(b: Bot, giver: Character, kind: SquadOrder.Kind, slot: int) -> void:
	b.order = kind
	b.order_giver = giver
	b.order_slot = slot
	b.order_yaw = giver.yaw
	if b.mode == Bot.Mode.ORDER:
		BotRoutes.drop(b)


## Back to the team plan: in Elimination the bot hunts from where it stands (its lane is behind it by now); in Attack /
## Defend it takes up its post or the pole again.
static func end(b: Bot, w: BotWorld) -> void:
	if b.order == SquadOrder.Kind.NONE:
		return
	b.order = SquadOrder.Kind.NONE
	b.order_giver = null
	if BotFlag.role(b, w) == BotFlag.Role.NONE:
		b.hunting = true


## Hold here: the spot `giver` looks at, on walkable ground hold_wall_gap short of what the view meets, stepped back
## towards them until the ground is walkable; NO_SPOT if they look at nothing within hold_range or no walkable ground
## is on that line.
static func hold_point(giver: Character, w: BotWorld) -> Vector3:
	var cfg := w.cfg.squad
	var eye := BotSenses.eye_of(giver, w.tuning)
	var view := giver.view_direction()
	if not w.query.ray(eye, eye + view * cfg.hold_range, _hit):
		return NO_SPOT
	var flat := Vector2(view.x, view.z).length()
	if flat < 1e-3:
		return NO_SPOT
	# How far along the ground the line of sight goes before it meets something.
	var reach := _hit.fraction * cfg.hold_range * flat - cfg.hold_wall_gap
	var nav := w.nav
	var back := 0.0
	while back <= reach:
		var d := reach - back
		back += nav.cell
		# The floor the line of sight passes over there: the street below when the giver looks down off a balcony, the
		# floor upstairs when they look up at it from below, the hall when they look up under its ceiling. A rising line
		# takes the highest floor under it (never lower than the eye's own reach); a falling one keeps node_at's reach.
		var line_y := eye.y + view.y / flat * d
		var at := Vector3(giver.position.x + view.x / flat * d, minf(line_y, maxf(eye.y, line_y - nav.pick_above)),
				giver.position.z + view.z / flat * d)
		if nav.is_walkable_at(at):
			return Vector3(at.x, nav.floor_at(at), at.z)
	return NO_SPOT


## Hold here for the teammates `bots` (by their place across `giver`'s view, left to right): each its own spot across the
## line of sight from `point`, hold_spacing apart (the point itself where that isn't walkable or isn't in a straight
## walkable line from it), or with no point (NO_SPOT), the spot it stands on.
static func place_hold(bots: Array[Bot], giver: Character, point: Vector3, w: BotWorld) -> void:
	var right := Vector3(cos(giver.yaw), 0.0, -sin(giver.yaw))
	var n := bots.size()
	for k in n:
		var b := bots[k]
		if not is_spot(point):
			b.order_goal = b.character.position
			continue
		var spot := point + right * ((k - (n - 1) * 0.5) * w.cfg.squad.hold_spacing)
		# A side spot must be walkable and in a straight walkable line from the point (M-05: not on the far side of a
		# thin wall, which would send the bot round by the next doorway). The line checks every step's height, so a spot
		# along a ramp passes and one on another level fails.
		if w.nav.is_walkable_at(spot) and w.nav.clear_line(point, spot):
			b.order_goal = Vector3(spot.x, w.nav.floor_at(spot), spot.z)
		else:
			b.order_goal = point


## The middle of the spots held for `giver` among `bots`, or NO_SPOT if nobody holds one for them.
static func held_centre(bots: Array[Bot], giver: Character) -> Vector3:
	var sum := Vector3.ZERO
	var n := 0
	for b in bots:
		if b.order == SquadOrder.Kind.HOLD and b.order_giver == giver:
			sum += b.order_goal
			n += 1
	return sum / n if n > 0 else NO_SPOT


## Moves an ordered bot this tick (BotMovement's ORDER mode). Returns whether it walks (direction in b.move_dir).
static func move(b: Bot, w: BotWorld, _cmd: PlayerCommand, dt: float) -> bool:
	match b.order:
		SquadOrder.Kind.HOLD:
			# No way there: it holds where it got to.
			if b.route_state == Bot.RouteState.FAILED:
				b.order_goal = b.character.position
				b.route_state = Bot.RouteState.NONE
			return _walk_to(b, w, b.order_goal, w.cfg.squad.hold_arrive, dt)
	return false


## Walks to `goal` until within `arrive`, or until at the end of a route planned for about there (a goal that stays
## put). Returns whether it walks.
static func _walk_to(b: Bot, w: BotWorld, goal: Vector3, arrive: float, dt: float) -> bool:
	var p := b.character.position
	if Vector2(goal.x - p.x, goal.z - p.z).length() <= arrive or _arrived_for(b, goal, w):
		if b.route_state != Bot.RouteState.WANTED:
			b.route_state = Bot.RouteState.NONE
		return false
	BotRoutes.want(b, goal, w.cfg)
	return BotRoutes.follow(b, w, dt, true)


## True if `b` got to the end of a route planned for about `goal` and stands there (nothing to replan).
static func _arrived_for(b: Bot, goal: Vector3, w: BotWorld) -> bool:
	return BotRoutes.arrived(b) and Vector2(goal.x - b.route_goal.x, goal.z - b.route_goal.z).length() \
			< w.cfg.replan_distance
