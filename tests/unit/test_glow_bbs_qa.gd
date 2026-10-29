extends GutTest
## WL8 QA: Glowing BBs beyond the worker's tests: the choice surviving every loadout operation and a JSON round trip,
## the BB's slot following the replica that fired it (not the one in hand now) and resetting on pool reuse, and which
## BBs glow in a played match by field, Day / Night pick and Dev › Time of day.

const SAVE_PATH := "user://test_glow_bbs_qa.save"
const DT := 1.0 / 60.0
const EYE := Vector3(0.0, 1.6, 0.0)

var rules: LoadoutRules = null


func before_all() -> void:
	rules = LoadoutRules.standard()


func after_all() -> void:
	SaveFile.remove(SAVE_PATH)


func _ids(l: Loadout) -> Array[String]:
	return [l.replica_id(Loadout.Slot.PRIMARY), l.replica_id(Loadout.Slot.SECONDARY)]


func test_copying_renaming_replacing_and_deleting_loadouts_keep_each_choice() -> void:
	var saved := SavedLoadouts.new(rules)
	var ids := _ids(saved.carried())
	saved.carried().set_glow(ids[0], Loadout.Glow.ALWAYS)
	saved.carried().set_glow(ids[1], Loadout.Glow.OFF)
	var made := saved.create()
	assert_eq(saved.carried().glow_of(ids[0]), Loadout.Glow.ALWAYS, "a new loadout copies the carried one's")
	assert_eq(saved.carried().glow_of(ids[1]), Loadout.Glow.OFF)
	saved.carried().set_glow(ids[0], Loadout.Glow.NIGHT)
	assert_eq(saved.slots[0].glow_of(ids[0]), Loadout.Glow.ALWAYS, "the copy's own: the first is not touched")
	var dup := saved.duplicate_slot(0)
	assert_eq(saved.slots[dup].glow_of(ids[1]), Loadout.Glow.OFF, "duplicate keeps it")
	assert_true(saved.rename(dup, "Night ops"))
	assert_eq(saved.slots[dup].glow_of(ids[0]), Loadout.Glow.ALWAYS, "rename keeps it")
	saved.use(0)
	assert_true(saved.replace(made))
	assert_eq(saved.slots[made].glow_of(ids[0]), Loadout.Glow.ALWAYS, "replace copies the carried one's")
	assert_true(saved.remove(made))
	assert_eq(saved.carried().glow_of(ids[1]), Loadout.Glow.OFF, "deleting another leaves the carried one's")
	assert_true(saved.save(SAVE_PATH))
	var again := SavedLoadouts.new(rules)
	again.load_file(SAVE_PATH)
	assert_eq(again.load_message, "")
	for i in saved.slots.size():
		for id in ids:
			assert_eq(again.slots[i].glow_of(id), saved.slots[i].glow_of(id), "%d %s after a JSON round trip" % [i, id])


func test_a_choice_that_is_not_a_word_falls_back_with_a_warning() -> void:
	var saved := SavedLoadouts.new(rules)
	var id := _ids(saved.carried())[0]
	for bad: Variant in [null, 2, true, ["always"], {"a": 1}, "", "ALWAYS ", "Night"]:
		var data := saved.to_dict()
		(data["slots"][0] as Dictionary)["glow"] = {id: bad}
		var problems := saved.from_dict(data)
		assert_eq(saved.carried().glow_of(id), Loadout.Glow.NIGHT, "%s reads At Night" % [bad])
		assert_eq(problems.size(), 1, "%s said once: %s" % [bad, problems])
	for bad: Variant in [3, true, ["night"]]:
		var data := saved.to_dict()
		(data["slots"][0] as Dictionary)["glow"] = bad
		assert_eq(saved.from_dict(data).size(), 1, "a glow that is not a table: said")


func test_a_pooled_bb_reused_without_a_slot_forgets_the_old_one() -> void:
	var pool := BBPool.new(1)
	var bb := pool.spawn(1, Vector3.ZERO, Vector3.FORWARD, 90.0, 0.0, 0.0002, 0.0, 1)
	assert_eq(bb.slot, 1)
	bb = pool.spawn(1, Vector3.ZERO, Vector3.FORWARD, 90.0, 0.0, 0.0002, 0.0)
	assert_eq(bb.slot, -1, "the same slot of the pool, a new BB: no leftover glow")
	var view := BBView.new()
	view.setup(EffectsConfig.new(), 1)
	view.set_glowing(PackedByteArray([3, 3]))
	view.update(pool, 0, Vector3.ZERO, 0.0, DT, Vector3.ZERO)
	assert_eq(view.multimesh.visible_instance_count, 1, "drawn white")
	assert_false(view.draws()[1].visible)
	view.free()


func test_a_bb_keeps_the_glow_of_the_replica_that_fired_it_after_a_switch() -> void:
	var tuning := SimTuning.new()
	var loadout := ReplicaStats.default_loadout()
	var c := Character.new(1, 0, Vector3.ZERO, 0.0, loadout)
	var pool := BBPool.new(8)
	var cmd := PlayerCommand.new()
	var events := SimEvents.new()
	var rng := Seeds.stream(7)
	cmd.fire = true
	Armament.step(c, cmd, EYE, 1.0, true, pool, rng, events, tuning, DT)
	var first: BB = null
	for b in pool.bbs:
		if b.active:
			first = b
	assert_not_null(first, "a BB flew")
	assert_eq(first.slot, 0, "fired from the primary")
	cmd.fire = false
	cmd.switch_to = 1
	for i in 120:
		events.clear()
		Armament.step(c, cmd, EYE, 1.0, true, pool, rng, events, tuning, DT)
		cmd.switch_to = -1
	assert_eq(c.armament.active, 1)
	cmd.fire = true
	for i in 3:
		events.clear()
		Armament.step(c, cmd, EYE, 1.0, true, pool, rng, events, tuning, DT)
	var second: BB = null
	for b in pool.bbs:
		if b.active and b.serial > first.serial:
			second = b
	assert_not_null(second)
	assert_eq(second.slot, 1, "the pistol's BB is from slot 1")
	assert_eq(first.slot, 0, "the first still from slot 0")
	var view := BBView.new()
	view.setup(EffectsConfig.new(), 8)
	# only the primary's BBs glow
	view.set_glowing(PackedByteArray([0, 1]))
	for b in pool.bbs:
		b.owner_id = 1
	view.update(pool, -1, Vector3.ZERO, 0.0, DT, Vector3.ZERO)
	assert_eq(view.draws()[1].multimesh.visible_instance_count, 1, "one glowing (the primary's)")
	view.free()


## A PlaySession on `map_id`, built to its first tick; bots off.
func _session(map_id: String, kit: Kit, pick: StringName, time_of_day: StringName = &"") -> PlaySession:
	var s := Settings.new()
	if time_of_day != &"":
		s.dev_enabled = true
		s.dev.time_of_day = time_of_day
	var session := PlaySession.new()
	session.map_id = map_id
	session.settings = s
	session.kit = kit
	session.lighting_pick = pick
	session.bots_active = false
	add_child_autofree(session)
	return session


func _built(session: PlaySession) -> void:
	var frames := 0
	while frames < 600 and session.ticks() < 1:
		await wait_physics_frames(1)
		frames += 1
	assert_gt(session.ticks(), 0, "the session started")


func _kit(primary: Loadout.Glow, secondary: Loadout.Glow) -> Kit:
	var l := rules.default_loadout("A")
	l.set_glow(l.replica_id(Loadout.Slot.PRIMARY), primary)
	l.set_glow(l.replica_id(Loadout.Slot.SECONDARY), secondary)
	return rules.carried(l)


func test_at_night_always_and_off_glow_by_the_field_s_light() -> void:
	# Depot is day (a Night pick it doesn't offer changes nothing) and night only by Dev › Time of day.
	var cases := [
		["depot", &"", &"night", Loadout.Glow.NIGHT, Loadout.Glow.ALWAYS, 3],
		["depot", &"night", &"", Loadout.Glow.NIGHT, Loadout.Glow.ALWAYS, 2],
		["depot", &"", &"", Loadout.Glow.OFF, Loadout.Glow.OFF, 0],
		["depot", &"", &"night", Loadout.Glow.OFF, Loadout.Glow.OFF, 0],
		["depot", &"", &"", Loadout.Glow.ALWAYS, Loadout.Glow.OFF, 1],
		["depot", &"", &"night", Loadout.Glow.NIGHT, Loadout.Glow.NIGHT, 3],
		["depot", &"", &"day", Loadout.Glow.NIGHT, Loadout.Glow.NIGHT, 0],
	]
	for c: Array in cases:
		var session := _session(c[0], _kit(c[3], c[4]), c[1], c[2])
		await _built(session)
		var label := "%s pick %s dev %s: %s/%s" % [c[0], c[1], c[2], c[3], c[4]]
		var bits := session._bbs._glowing
		assert_eq(bits[PlaySession.PLAYER_ID], c[5], "yours, " + label)
		for ch in session.state.characters:
			if ch.id != PlaySession.PLAYER_ID:
				assert_eq(bits[ch.id], 3 if session.lighting().night else 0, "a bot's, " + label)
		session.queue_free()
		await wait_process_frames(2)
