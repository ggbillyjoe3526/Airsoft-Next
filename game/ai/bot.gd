class_name Bot
extends RefCounted
## One bot's mind as plain data (the browser game's ai/bot.ts, Elimination's part): what it has seen and heard, its aim,
## its route, its lane and its cover. The bot's body is an ordinary Character it drives through a PlayerCommand like the
## player's (docs/ARCHITECTURE.md › Contracts 2); BotBrain decides that command each tick from this.

## What it is doing: walking its lane (then hunting), fighting someone in sight, in cover, or going to where someone was
## seen or heard.
enum Mode { ADVANCE, FIGHT, COVER, SEARCH }
## In cover: down behind it, or up (over crouch cover, or leaning out round a corner) looking.
enum CoverPhase { DOWN, PEEK }
## Its route: none, asked for (the controller plans one a tick), walking one, or none to be had.
enum RouteState { NONE, WANTED, OK, FAILED }


## What a bot remembers of one enemy it has seen, kept for the match (one per enemy).
class Contact:
	extends RefCounted
	## Last seen (s), first seen in this contact, when its aim began settling, and when it may open fire.
	var seen_at: float = -INF
	var first_seen_at: float = -INF
	var acquired_at: float = 0.0
	var react_at: float = 0.0


var character: Character = null
var rng: RandomNumberGenerator = null
var skill: BotSkill = null
var mode: Mode = Mode.ADVANCE

## The view it turns (at the skill's turn rate) and its aim error: a wander, and a fresh contact's first aim off to one
## side (BotAim).
var aim_yaw: float = 0.0
var aim_pitch: float = 0.0
var err_yaw: float = 0.0
var err_pitch: float = 0.0
var goal_err_yaw: float = 0.0
var goal_err_pitch: float = 0.0
var wander_left: float = 0.0
var first_yaw: float = 0.0
var first_pitch: float = 0.0

## Each enemy's contact by character id (null until first seen), the current one, and who it fights.
var contacts: Array[Contact] = []
var contact: Contact = null
var target_id: int = -1
var target_visible: bool = false
## The part of the target it sees (a share of its height: chest, or head).
var target_part: float = 0.0
## Seconds to its next sight check.
var think_left: float = 0.0
## Last time anything gave an enemy away (seen, heard, shot at).
var last_threat_at: float = -INF
## Seconds sprinting without a break, and since the sprint last stopped (BotHolster).
var sprint_run: float = 0.0
var sprint_gap: float = 0.0
## Where it last saw or heard someone, and whether that is in mind; when it last heard something.
var last_known: Vector3 = Vector3.ZERO
var has_last_known: bool = false
var heard_at: float = -INF
## Someone heard while it fought someone else: kept for when that fight is over.
var heard_other: Vector3 = Vector3.ZERO
var heard_other_at: float = -INF
## Last near miss from an enemy BB.
var suppressed_at: float = -INF

## Its route: waypoints, the one it walks to, where the leg began, the goal and the route's state.
var route: PackedVector3Array = PackedVector3Array()
var route_leg: int = 0
var route_from: Vector3 = Vector3.ZERO
var route_goal: Vector3 = Vector3.ZERO
var route_state: RouteState = RouteState.NONE
var route_retry_at: float = -INF
## Seconds it has walked slower than BotConfig.stuck_speed.
var stuck_for: float = 0.0
## Walking the first half of a route's vault leg this tick (BotRoutes.follow): straight at it, Jump once it's there.
var vault_leg: bool = false
## No vault in its routes before this time (s): it got held up on a vault leg (BotConfig.vault_retry_delay).
var vaults_off_until: float = -INF
## The way it walks this tick (a unit vector on the ground; zero to coast).
var move_dir: Vector3 = Vector3.ZERO

## Its lane (index in the map's lanes, -1 none), the way it walks it (1 first to last, -1 back), the point last reached
## (-1 none yet), how many points it walks before hunting, and the point it walks to now.
var lane: int = -1
var lane_dir: int = 1
var lane_index: int = -1
var lane_points: int = 0
var lane_goal: Vector3 = Vector3.ZERO
## Its lane swept: it hunts the stalest spot its team hasn't checked.
var hunting: bool = false
var hunt_goal: Vector3 = Vector3.ZERO
var hunt_picked_at: float = -INF
## Pausing at a lane point: time left, time spent there, waiting for the team, holding (this tick), and crouching to.
var hold_left: float = 0.0
var team_wait: float = 0.0
var wait_for_team: bool = false
var holding: bool = false
var hold_crouch: bool = false
## Stepping into crouch cover by a lane point first, and that spot.
var hold_cover: bool = false
var hold_spot: BotCover.Spot = BotCover.Spot.new()

## In cover: the spot, ducked or peeking, seconds left down, to give up getting there, settled there, since the episode
## began, looks left and the one under way; fighting from it now, and for how long more.
var cover: BotCover.Spot = BotCover.Spot.new()
var cover_phase: CoverPhase = CoverPhase.DOWN
var cover_left: float = 0.0
var cover_give_up: float = 0.0
var cover_held: float = 0.0
var cover_since: float = -INF
var peeks_left: int = 0
var peek_left: float = 0.0
var from_cover: bool = false
var peek_fight_left: float = 0.0
## Seconds until the next cover search may run.
var cover_cooldown: float = 0.0

## The trigger: seconds left in the burst, and in the pause after it; sidestepping, and which way.
var burst_left: float = 0.0
var pause_left: float = 0.0
var strafe_left: float = 0.0
var strafe_dir: int = 1

## Searching: the look round at the end (left, all, from which way), and going round by a flank point first.
var search_look_left: float = 0.0
var search_look_time: float = 0.0
var search_look_yaw: float = 0.0
var flanking: bool = false
var flank_goal: Vector3 = Vector3.ZERO
## Glances taken (hunting by eye), for the even spread over its view.
var glances: int = 0
## Held angles (BotAngles; skill.holds_angles or slices_corners): the best found, how many, and when and where they
## were last looked for.
var held_angles: Array[BotAngles.HeldAngle] = []
var held_angle_count: int = 0
var held_angles_at: float = -INF
var held_angles_from: Vector3 = Vector3.ZERO
## Near the enemy with skill.slices_corners: walking and slicing each corner ahead (BotBrain).
var careful: bool = false
## Lost sight of someone in a fight: watching where they were until this time before going after them (s).
var watch_until: float = -INF
## Team play: when it heard a teammate's hit call (to trade), and whether it has tried for cover to trade from.
var trade_at: float = -INF
var trade_tried: bool = false
## Who it is this match (BotRoster): its name ("" without one) and the personality it plays (BotsFile), laid over its
## skill once (BotPersonality.personal_skill); the neutral style for a bot without one.
var bot_name: String = ""
var personality: StringName = &""
var style: BotsFile.Style = BotsFile.neutral()
## Settled at its post (an anchor's last lane point) since last tick: whether to crouch there is chosen on arrival.
var at_post: bool = false
## Pushing in: whether a step forward keeps the target in sight, looked at once a sidestep or for a new target.
var push_in_sight: bool = false
var push_look_for: int = -1


func _init(body: Character, seed_value: int, bot_skill: BotSkill, roster_size: int) -> void:
	character = body
	rng = Seeds.stream(seed_value)
	skill = bot_skill
	for i in roster_size:
		contacts.append(Contact.new())
	for i in BotAngles.KEPT:
		held_angles.append(BotAngles.HeldAngle.new())
	aim_yaw = body.yaw


## A fresh round: everything it knew forgotten, on `lane_id` (walked from its end) for `points` points, setting off after
## `start_hold` seconds.
func reset(lane_id: int, points: int, start_hold: float, cfg: BotConfig) -> void:
	aim_yaw = character.yaw
	aim_pitch = 0.0
	err_yaw = 0.0
	err_pitch = 0.0
	goal_err_yaw = 0.0
	goal_err_pitch = 0.0
	wander_left = 0.0
	first_yaw = 0.0
	first_pitch = 0.0
	mode = Mode.ADVANCE
	# Sight checks are staggered across bots.
	think_left = rng.randf() * cfg.think_interval
	forget_target()
	for c in contacts:
		if c != null:
			c.seen_at = -INF
	has_last_known = false
	heard_at = -INF
	heard_other_at = -INF
	last_threat_at = -INF
	sprint_run = 0.0
	sprint_gap = 0.0
	suppressed_at = -INF
	route.clear()
	route_leg = 0
	route_state = RouteState.NONE
	route_retry_at = -INF
	stuck_for = 0.0
	vault_leg = false
	vaults_off_until = -INF
	move_dir = Vector3.ZERO
	lane = lane_id
	# From end 0 the lane's points go first to last, from end 1 last to first.
	lane_dir = 1 if character.end == 0 else -1
	lane_index = -1
	lane_points = points
	hunting = false
	hunt_picked_at = -INF
	hold_left = start_hold
	team_wait = 0.0
	wait_for_team = false
	holding = false
	hold_crouch = false
	hold_cover = false
	cover_phase = CoverPhase.DOWN
	cover_left = 0.0
	cover_since = -INF
	from_cover = false
	cover_cooldown = 0.0
	burst_left = 0.0
	pause_left = 0.0
	strafe_left = 0.0
	search_look_left = 0.0
	flanking = false
	held_angle_count = 0
	held_angles_at = -INF
	careful = false
	watch_until = -INF
	trade_at = -INF
	trade_tried = false
	at_post = false
	push_look_for = -1


func forget_target() -> void:
	target_id = -1
	target_visible = false
	contact = null


## When it last saw the target it has in mind (-INF: none).
func last_seen_at() -> float:
	return contact.seen_at if contact != null else -INF


## Something seen or heard is still in mind (BotConfig.memory_time).
func threat_in_mind(time: float, cfg: BotConfig) -> bool:
	return has_last_known and time - maxf(last_seen_at(), heard_at) < cfg.memory_time


## Takes up the enemy heard during a fight now that the fight is over, if that is recent. True if there was one.
func recall_heard_other(time: float, cfg: BotConfig) -> bool:
	if time - heard_other_at >= cfg.memory_time:
		return false
	last_known = heard_other
	has_last_known = true
	heard_at = heard_other_at
	heard_other_at = -INF
	return true


## A draw from `span` (Vector2(min, max)) on its own stream.
func pick(span: Vector2) -> float:
	return rng.randf_range(span.x, span.y)
