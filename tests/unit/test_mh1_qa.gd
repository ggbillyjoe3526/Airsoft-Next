extends GutTest
## MH1's QA pass: the hand-off through Simulation.step in the awkward moments (a thrower or a catcher put out in the air,
## the round decided with asks standing and magazines flying, a catcher that reloads in flight, a match nobody presses
## in), and that its five events were appended after every older kind.

const DT := 1.0 / 60.0

var tuning: SimTuning = SimTuning.new()
var loadout: Array[ReplicaConfig] = []
var rifle: ReplicaConfig = null


func before_all() -> void:
	loadout = ReplicaStats.default_loadout()
	rifle = loadout[0]


## Three on team 0 (0, 1, 2) 4 m apart and an opponent far off (3), round 1 live: [Simulation, GameState, commands].
func _match(seed_value: int = 9) -> Array:
	var w := BoxWorld.new(tuning.body)
	w.add_floor(60.0, 30.0)
	var ends: Array[MapEnd] = []
	for e in 2:
		var end := MapEnd.new()
		for i in 3:
			end.spawns.append(SpawnPoint.new(Vector3(-10.0 if e == 0 else 10.0, 0.0, i * 2.0), 0.0))
			end.dead_zone.append(SpawnPoint.new(Vector3(-25.0 if e == 0 else 25.0, 0.0, 10.0), 0.0))
		ends.append(end)
	var sim := Simulation.new(tuning, w, w.mover(), ends, -10.0)
	var s := GameState.new(seed_value, tuning)
	for i in 4:
		s.characters.append(Character.new(i, 0 if i < 3 else 1, Vector3.ZERO, 0.0, loadout))
	sim.start_match(s)
	var spots: Array[Vector3] = [Vector3(0.0, 0.0, 0.0), Vector3(4.0, 0.0, 0.0), Vector3(0.0, 0.0, 4.0),
			Vector3(25.0, 0.0, -10.0)]
	for c in s.characters:
		c.position = spots[c.id] + Vector3(0.0, c.position.y, 0.0)
	var cmds: Array[PlayerCommand] = []
	for c in s.characters:
		var cmd := PlayerCommand.new()
		cmd.reset(c.yaw, c.pitch)
		cmds.append(cmd)
	return [sim, s, cmds]


## One tick; `pressing` press the hand-off this tick only. Returns the tick's hand-off event kinds.
func _tick(m: Array, pressing: Array = []) -> Array[int]:
	var sim: Simulation = m[0]
	var s: GameState = m[1]
	var cmds: Array[PlayerCommand] = m[2]
	for c in cmds:
		c.mag_hand_off = false
	for id: int in pressing:
		cmds[id].mag_hand_off = true
	sim.step(s, cmds, DT)
	var out: Array[int] = []
	for i in s.events.count:
		var k: int = s.events.items[i].kind
		if k >= GameEvent.Kind.MAG_ASK and k <= GameEvent.Kind.MAG_REFUSED:
			out.append(k)
	return out


## Ticks until a catch or a loss shows (at most 3 s); that kind, or -1.
func _until_landed(m: Array) -> int:
	for i in 180:
		for k in _tick(m):
			if k == GameEvent.Kind.MAG_CATCH or k == GameEvent.Kind.MAG_LOST:
				return k
	return -1


static func _held(s: GameState) -> int:
	var n := 0
	for c in s.characters:
		if c.team == 0:
			n += c.armament.ammo[0].mag + c.armament.ammo[0].spare_bbs()
	return n


static func _active(s: GameState) -> int:
	var n := 0
	for t in s.mag_tosses:
		if t.active:
			n += 1
	return n


func test_the_five_events_are_appended_after_every_older_kind() -> void:
	assert_eq(GameEvent.Kind.MAG_ASK, GameEvent.Kind.PING + 1, "no older id moved")
	assert_eq(GameEvent.Kind.MAG_TOSS, GameEvent.Kind.MAG_ASK + 1)
	assert_eq(GameEvent.Kind.MAG_CATCH, GameEvent.Kind.MAG_TOSS + 1)
	assert_eq(GameEvent.Kind.MAG_LOST, GameEvent.Kind.MAG_CATCH + 1)
	assert_eq(GameEvent.Kind.MAG_REFUSED, GameEvent.Kind.MAG_LOST + 1)
	assert_eq(GameEvent.Kind.GRENADE_PIN, GameEvent.Kind.MAG_REFUSED + 1, "the bombs' kinds come after (SF1)")


func test_a_thrower_put_out_in_the_air_still_lands_its_magazine() -> void:
	var m := _match()
	var s: GameState = m[1]
	var catcher := s.characters[1]
	catcher.armament.ammo[0].pouch.fill(0)
	catcher.mag.asked = 0
	var before := _held(s)
	assert_true(_tick(m, [0]).has(GameEvent.Kind.MAG_TOSS))
	s.characters[0].status = Character.Status.OUT
	assert_eq(_until_landed(m), GameEvent.Kind.MAG_CATCH, "the thrower's hit does not stop the flight")
	assert_eq(catcher.armament.ammo[0].spare_bbs(), rifle.mag_size)
	assert_eq(_held(s), before, "no BB made or lost")
	assert_eq(catcher.mag.asked, -1, "the ask ends with the landing")
	assert_eq(catcher.mag.coming, 0)
	assert_eq(_active(s), 0)


func test_a_catcher_put_out_in_the_air_loses_only_that_magazine_and_its_ask() -> void:
	var m := _match()
	var s: GameState = m[1]
	var catcher := s.characters[1]
	catcher.armament.ammo[0].pouch.fill(0)
	catcher.mag.asked = 0
	var before := _held(s)
	assert_true(_tick(m, [0]).has(GameEvent.Kind.MAG_TOSS))
	catcher.status = Character.Status.OUT
	assert_eq(_until_landed(m), GameEvent.Kind.MAG_LOST)
	assert_eq(_held(s), before - rifle.mag_size, "only the lost toss's BBs are gone")
	assert_eq(catcher.armament.ammo[0].spare_bbs(), 0)
	assert_eq(catcher.mag.asked, -1)
	assert_eq(catcher.mag.coming, 0)
	assert_eq(_active(s), 0)


func test_a_catcher_that_reloads_in_flight_still_gets_every_bb() -> void:
	var m := _match()
	var s: GameState = m[1]
	var catcher := s.characters[1]
	catcher.armament.ammo[0].mag = 0
	catcher.armament.ammo[0].pouch.fill(0)
	catcher.armament.ammo[0].pouch[0] = 10
	catcher.mag.asked = 0
	var before := _held(s)
	assert_true(_tick(m, [0]).has(GameEvent.Kind.MAG_TOSS))
	# The swap a reload makes in the air: the fullest spare in, the empty one back.
	catcher.armament.ammo[0].mag = 10
	catcher.armament.ammo[0].pouch[0] = 0
	assert_eq(_until_landed(m), GameEvent.Kind.MAG_CATCH)
	assert_eq(_held(s), before, "every BB landed")


func test_a_round_decided_with_asks_standing_and_a_magazine_flying_starts_the_next_clean() -> void:
	var m := _match()
	var s: GameState = m[1]
	s.characters[1].armament.ammo[0].pouch.fill(0)
	s.characters[2].armament.ammo[0].pouch.fill(0)
	s.characters[1].mag.asked = 0
	s.characters[2].mag.asked = 0
	assert_true(_tick(m, [0]).has(GameEvent.Kind.MAG_TOSS))
	assert_eq(_active(s), 1)
	s.characters[3].status = Character.Status.OUT
	var started := false
	var cleared_in_the_pause := false
	for i in 1200:
		_tick(m)
		if s.round_state.phase == RoundState.Phase.OVER and _active(s) == 0 and s.characters[2].mag.asked == -1:
			cleared_in_the_pause = true
		if s.events.count_of(GameEvent.Kind.ROUND_START) > 0:
			started = true
			break
	assert_true(started, "the next round started")
	assert_true(cleared_in_the_pause, "the magazine was lost and the ask ended while the round was over")
	assert_eq(_active(s), 0)
	for c in s.characters:
		assert_eq(c.mag.asked, -1)
		assert_eq(c.mag.coming, 0)
		assert_eq(c.armament.ammo[0].spare_bbs(), (rifle.mags - 1) * rifle.mag_size, "full spares again")


func test_a_respawn_clears_the_hand_but_not_who_the_player_is() -> void:
	var c := Character.new(0, 0, Vector3.ZERO, 0.0, loadout)
	c.mag.player = true
	c.mag.asked = 3
	c.mag.coming = 2
	c.mag.coming_from = 3
	c.mag.next_ask = 99.0
	c.respawn()
	assert_eq(c.mag.asked, -1)
	assert_eq(c.mag.coming, 0)
	assert_eq(c.mag.next_ask, -INF)
	assert_true(c.mag.player)


func test_a_match_nobody_presses_in_changes_nothing_however_low_they_run() -> void:
	var m := _match()
	var s: GameState = m[1]
	for id: int in [1, 2]:
		s.characters[id].armament.ammo[0].pouch.fill(0)
	var before := _held(s)
	for i in 1500:
		assert_eq(_tick(m).size(), 0, "no hand-off event unless someone presses")
	assert_eq(_held(s), before)
	assert_eq(_active(s), 0)
	for c in s.characters:
		assert_eq(c.mag.asked, -1)
		assert_eq(c.mag.coming, 0)


func test_a_press_on_the_range_is_not_now_and_moves_nothing() -> void:
	var m := _match()
	var s: GameState = m[1]
	s.round_state.practice = true
	s.characters[1].armament.ammo[0].pouch.fill(0)
	s.characters[1].mag.asked = 0
	var seen := _tick(m, [0, 1])
	assert_eq(seen, [GameEvent.Kind.MAG_REFUSED, GameEvent.Kind.MAG_REFUSED])
	assert_eq(_active(s), 0)


func test_an_ask_stands_while_its_magazine_is_in_the_air_even_past_the_giver_going_out() -> void:
	var m := _match()
	var s: GameState = m[1]
	var catcher := s.characters[1]
	catcher.armament.ammo[0].pouch.fill(0)
	catcher.mag.asked = 0
	assert_true(_tick(m, [0]).has(GameEvent.Kind.MAG_TOSS))
	s.characters[0].status = Character.Status.OUT
	_tick(m)
	assert_eq(catcher.mag.asked, 0, "the magazine is coming, so the ask stands")
