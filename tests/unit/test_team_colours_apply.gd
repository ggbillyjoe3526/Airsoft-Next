extends GutTest
## The team colour sets in play and in the menus (AC2): the session resolves the saved set once at Play, the figures,
## their sign outline and the flag take its figures part (High contrast's paint glowing by day), every HUD part its HUD
## part, and the menus follow the saved set at once. Standard draws as the game always has.

## Today's colours are TeamConfig's floats; Standard's table holds them as 8-bit hex, so they agree to half a step.
const SAME := 0.5 / 255.0
const HC_FIGURES: Array[Color] = [Color("8ccfff"), Color("b8460c")]
const HC_HUD: Array[Color] = [Color("8ccfff"), Color("e0601a")]

var session: PlaySession = null


func after_each() -> void:
	get_tree().paused = false


func _session(colour_set: TeamColours.Set) -> PlaySession:
	var s := Settings.new(PlayTuning.new())
	s.team_colours = colour_set
	session = PlaySession.new()
	session.settings = s
	session.mode = MatchOptions.MODE_ATTACK_DEFEND
	session.bots_active = false
	add_child_autofree(session)
	await wait_physics_frames(2)
	return session


func _assert_colour(got: Color, want: Color, what: String) -> void:
	for i in 3:
		assert_almost_eq(got[i], want[i], SAME, "%s, channel %d" % [what, i])


## The figures, their signs, the flag and the HUD all in `figures` and `hud`, the figures glowing `glow`.
func _assert_drawn(figures: Array[Color], hud: Array[Color], glow: float) -> void:
	assert_false(session._figures.is_empty())
	for f in session._figures:
		var team := session.state.character(f.character_id).team
		_assert_colour(f._mat.albedo_color, figures[team], "figure %d" % f.character_id)
		_assert_colour(f._sign.outline_modulate, figures[team].darkened(FigureView.SIGN_OUTLINE_DARKEN),
				"sign %d" % f.character_id)
		assert_eq(f._mat.emission_enabled, glow > 0.0, "glows only with a glow")
		if glow > 0.0:
			assert_almost_eq(f._mat.emission_energy_multiplier, glow, 0.001)
			_assert_colour(f._mat.emission, figures[team], "the glow is the paint's own colour")
	var flag := session.flag_view()
	assert_not_null(flag)
	for side in 2:
		_assert_colour(flag._teams.colours[side], figures[side], "flag %d" % side)
	var attackers := session.state.round_state.attackers
	flag.refresh(session.state.round_state.flag, attackers)
	_assert_colour(flag._cloth_mat.get_shader_parameter(&"team_colour") as Color, figures[attackers], "the cloth")
	var teams := session.hud()._teams
	for side in 2:
		_assert_colour(teams.colours[side], hud[side], "HUD %d" % side)
	assert_same(session.hud().score()._teams, teams, "the score bar")
	assert_same(session.hud()._feed._teams, teams, "the hit feed")
	assert_same(session.hud().minimap()._teams, teams, "the minimap")
	assert_eq(teams.names, PlayTuning.new().teams.names, "the names stay the teams'")


func test_standard_draws_as_the_game_always_has() -> void:
	await _session(TeamColours.Set.STANDARD)
	var today := PlayTuning.new().teams.colours
	var colours: Array[Color] = [today[0], today[1]]
	_assert_drawn(colours, colours, 0.0)
	for side in 2:
		assert_eq(session.hud().score()._score_labels[side].get_theme_color("font_color"), GameTheme.TEXT,
				"white numbers on Standard's blocks, as today")


func test_high_contrast_reaches_every_consumer_and_glows_by_day() -> void:
	await _session(TeamColours.Set.HIGH_CONTRAST)
	_assert_drawn(HC_FIGURES, HC_HUD, 0.3)
	assert_eq(session.hud().score()._score_labels[0].get_theme_color("font_color"), GameTheme.BG,
			"a dark number on the light blue block")
	assert_eq(session.hud().score()._score_labels[1].get_theme_color("font_color"), GameTheme.TEXT)


func test_a_change_mid_match_shows_from_the_next_match() -> void:
	await _session(TeamColours.Set.STANDARD)
	var drawn := session.team_colours()
	session.settings.team_colours = TeamColours.Set.HIGH_CONTRAST
	session.settings.mark_changed()
	await wait_physics_frames(2)
	assert_same(session.team_colours(), drawn, "resolved once, at Play")
	var today := PlayTuning.new().teams.colours
	var colours: Array[Color] = [today[0], today[1]]
	_assert_drawn(colours, colours, 0.0)


func test_the_glow_is_0_on_a_night_preset() -> void:
	var s := Settings.new(PlayTuning.new())
	s.team_colours = TeamColours.Set.HIGH_CONTRAST
	var lighting := LightingConfig.new()
	assert_false(lighting.night, "every field is lit by day until step 26")
	var base := PlayTuning.new().teams
	assert_almost_eq(PlaySession.team_colours_for(s, lighting, base).figures.glow, 0.3, 0.001)
	lighting.night = true
	var night := PlaySession.team_colours_for(s, lighting, base)
	assert_eq(night.figures.glow, 0.0)
	_assert_colour(night.figures.colours[0], HC_FIGURES[0], "the same paint at night")
	assert_false(FigureView.material(HC_FIGURES[0], false, night.figures.glow).emission_enabled)


func test_ink_is_dark_only_on_a_light_team_colour() -> void:
	var today := PlayTuning.new().teams.colours
	for c: Color in [today[0], today[1], HC_HUD[1]]:
		assert_eq(HudStyle.ink_on(c), GameTheme.TEXT, str(c))
	assert_eq(HudStyle.ink_on(HC_HUD[0]), GameTheme.BG)


# --- the menus ---

func test_the_match_page_s_team_picks_follow_the_saved_set_at_once() -> void:
	var s := Settings.new(PlayTuning.new())
	s.team_colours = TeamColours.Set.HIGH_CONTRAST
	var page := MatchPage.new(MatchPicks.new(), s)
	add_child_autofree(page)
	for side in 2:
		_assert_colour(page.team_card(side).accent, HC_HUD[side], "team card %d" % side)
		_assert_colour(page.team_card(side).bar, HC_HUD[side], "team bar %d" % side)
	s.team_colours = TeamColours.Set.STANDARD
	s.mark_changed()
	var today := PlayTuning.new().teams.colours
	for side in 2:
		_assert_colour(page.team_card(side).accent, today[side], "team card %d, Standard" % side)
		_assert_colour(page.team_card(side).picked_fill, GameTheme.CARD.lerp(today[side], MatchPage.TEAM_TINT),
				"its tint")
	await wait_process_frames(1) # the rules' chips the change rebuilt go


## The glowing figure materials the prewarm draws for `colour_set`, as [faded, opaque] counts.
func _glowing_warmed(colour_set: TeamColours.Set) -> Array[int]:
	var s := Settings.new(PlayTuning.new())
	s.team_colours = colour_set
	var fresh := PlaySession.new()
	fresh.settings = s
	fresh.bots_active = false
	add_child_autofree(fresh)
	var warm := fresh.find_child("ShaderPrewarm", true, false) as ShaderPrewarm
	var counts: Array[int] = [0, 0]
	for speck in warm.find_children("*", "MeshInstance3D", true, false):
		var m := (speck as MeshInstance3D).material_override as StandardMaterial3D
		if m != null and m.emission_enabled:
			counts[0 if m.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA else 1] += 1
	return counts


func test_the_prewarm_draws_a_glowing_figure_both_ways_and_standard_none() -> void:
	assert_eq(_glowing_warmed(TeamColours.Set.HIGH_CONTRAST), [1, 1] as Array[int],
			"faded and opaque: the first bot seen is drawn opaque (performance)")
	assert_eq(_glowing_warmed(TeamColours.Set.STANDARD), [0, 0] as Array[int])
