extends GutTest
## Bot names in a match (BN1, game/play/play_session.gd): every bot gets a name and personality drawn on the match's
## seed, the Dev tab's bot intentions name each bot, and the HUD names whose eyes you watch through.

var session: PlaySession = null
var s: Settings = null


func before_each() -> void:
	s = Settings.new(PlayTuning.new())
	s.dev_enabled = true


func _play(autopilot: bool = true) -> void:
	session = PlaySession.new()
	session.settings = s
	session.map_id = "depot"
	session.match_seed = 11
	session.autopilot = autopilot
	add_child_autofree(session)
	await wait_physics_frames(2)


func test_every_bot_has_its_name_and_personality_drawn_on_the_match_seed() -> void:
	await _play(false)
	var ids := PackedInt32Array()
	var teams := PackedInt32Array()
	for c in session.state.characters:
		if c.id != PlaySession.PLAYER_ID:
			ids.append(c.id)
			teams.append(c.team)
	var drawn := BotRoster.draw(11, ids, teams, BotsFile.shared())
	var names: Array[String] = []
	for id in ids:
		var b: Bot = null
		for o in session._bots.world.bots:
			if o.character.id == id:
				b = o
		assert_eq(b.bot_name, drawn[id].bot_name)
		assert_eq(b.personality, drawn[id].personality)
		assert_false(names.has(b.bot_name), "no name twice")
		names.append(b.bot_name)
	assert_eq(session._bots.name_of(PlaySession.PLAYER_ID), "", "you are nobody's bot")


func test_bot_intentions_name_each_bot() -> void:
	s.dev.bot_intent = true
	await _play()
	await wait_process_frames(2)
	var view: BotIntentView = session.find_children("*", "BotIntentView", true, false)[0]
	for i in view._labels.size():
		var label := view._labels[i]
		if label.visible:
			assert_string_starts_with(label.text, session._bots.name_of(view._ids[i]) + " · ")


func test_the_hud_names_the_bot_you_watch_and_nobody_when_it_is_you() -> void:
	s.dev.spectate_bots = true
	await _play(false)
	await wait_process_frames(2)
	var watching := session._hud._watching
	assert_true(watching.visible)
	assert_eq(watching.text, tr("HUD_WATCHING") % session._bots.name_of(session.spectated().id))
	assert_true(watching.uppercase)
	s.dev.spectate_bots = false
	s.mark_changed()
	await wait_process_frames(2)
	assert_false(watching.visible, "through your own eyes: no line")
