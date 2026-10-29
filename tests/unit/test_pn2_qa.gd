extends GutTest
## QA for PN2 (ping markers, the minimap and the pip): edge cases around the ping book's life, the pip's serial rule,
## switching the setting mid-ping and the pause, beyond tests/unit/test_ping_markers.gd.

const YOU := 0
const BRICK := 1
const ROOK := 2

var _cfg := HudConfig.new()
var _sim := SimTuning.new()
var _state: GameState = null
var _book: Pings = null
var _hud: Hud = null
var _camera: Camera3D = null


func before_each() -> void:
	_state = GameState.new()
	for i in 4:
		_state.characters.append(Character.new(i, 0 if i < 2 else 1))
	_book = Pings.new(_state.characters, _sim.pings)
	var frame := Control.new()
	frame.size = get_viewport().get_visible_rect().size
	add_child_autofree(frame)
	_hud = Hud.new()
	frame.add_child(_hud)
	_hud.setup(_cfg, TeamConfig.new(), ViewConfig.new(), _sim, _state.characters[YOU])
	_hud.setup_field(BoxWorld.new(), BodyConfig.new(), PackedStringArray(["", "Brick", "Rook", "Dash"]),
			_state.characters, null)
	_camera = Camera3D.new()
	add_child_autofree(_camera)
	_camera.global_position = Vector3(0.0, 1.6, 0.0)


func _ping(who: int, spot: Vector3, at: float, contact: bool = false, marked: bool = false) -> void:
	var p := _book.of(who)
	p.owner = who
	p.team = _state.characters[who].team
	p.kind = Pings.Kind.CONTACT if contact else Pings.Kind.SPOT
	p.spot = spot
	p.point = spot + Vector3.UP * 1.26 if contact else spot
	p.enemy_id = ROOK if contact else -1
	p.at = at
	p.marked = marked
	_book.placed += 1


func _place(now: float) -> void:
	_hud.update(_state, 1.0, 0.0)
	_hud.place_pings(_camera, _book, now, true)


func _audio() -> SimAudio:
	var audio := SimAudio.new()
	add_child_autofree(audio)
	audio.setup(SoundConfig.new(), [] as Array[StringName], BodyConfig.new(), null, null)
	return audio


func _pips(audio: SimAudio) -> int:
	var n := 0
	var pip: Array = audio._streams[&"ping_pip"]
	for v in audio._own:
		if v.playing and pip.has(v.stream):
			n += 1
	return n


func test_a_new_round_clears_the_markers_and_the_minimap() -> void:
	_hud.setup_minimap(MapData.new(), MinimapConfig.new(), MinimapHearing.new(MinimapConfig.new()), "Depot", 4)
	_ping(YOU, Vector3(0.0, 0.0, -9.0), 1.0)
	_ping(BRICK, Vector3(3.0, 0.0, -9.0), 1.0, true)
	_place(2.0)
	assert_eq(_hud.ping_markers().shown(), 2)
	_book.clear()
	_place(2.0)
	assert_eq(_hud.ping_markers().shown(), 0, "a new round clears the on-screen markers")
	_hud.update_minimap(_state, _state.characters[YOU], 0.0, 1.0, false, Vector3.ZERO, _book)
	assert_eq(_hud.minimap().view().ping_count(), 0, "and the minimap's")


func test_a_marker_is_gone_at_its_lifetime_and_back_whole_for_a_new_ping() -> void:
	_ping(YOU, Vector3(0.0, 0.0, -9.0), 0.0)
	_place(7.0)
	assert_almost_eq(_hud.ping_markers().marker_of(YOU).modulate.a, 1.0, 0.001, "still whole at 7 s")
	_place(_sim.pings.lifetime)
	assert_eq(_hud.ping_markers().shown(), 0, "gone at the lifetime")
	_ping(YOU, Vector3(1.0, 0.0, -9.0), 9.0)
	_place(9.0)
	var m := _hud.ping_markers().marker_of(YOU)
	assert_true(m.visible)
	assert_almost_eq(m.modulate.a, 1.0, 0.001, "a new ping after a fade starts whole")
	assert_almost_eq(m.scale.x, _cfg.ping_pop_from, 0.001, "and pops in again")


func test_markers_come_back_when_the_setting_goes_on_again_mid_ping() -> void:
	_ping(YOU, Vector3(0.0, 0.0, -9.0), 1.0)
	var prefs := HudPrefs.new()
	prefs.ping_markers = false
	_hud.apply_prefs(prefs)
	_place(2.0)
	assert_eq(_hud.ping_markers().shown(), 0)
	prefs.ping_markers = true
	_hud.apply_prefs(prefs)
	_place(2.0)
	assert_eq(_hud.ping_markers().shown(), 1, "On again shows the ping still up")


func test_off_hides_markers_only_the_pip_still_plays() -> void:
	var prefs := HudPrefs.new()
	prefs.ping_markers = false
	_hud.apply_prefs(prefs)
	var audio := _audio()
	_ping(YOU, Vector3(0.0, 0.0, -9.0), 1.0)
	audio.on_ping(_book, YOU)
	assert_eq(_pips(audio), 1, "Off does not mute the pip")


func test_two_own_pings_pip_twice_and_a_teammates_between_adds_none() -> void:
	var audio := _audio()
	_ping(YOU, Vector3(0.0, 0.0, -9.0), 1.0)
	audio.on_ping(_book, YOU)
	_ping(BRICK, Vector3(0.0, 0.0, -9.0), 1.5)
	audio.on_ping(_book, YOU)
	assert_eq(_pips(audio), 1)
	_ping(YOU, Vector3(2.0, 0.0, -9.0), 3.0)
	_ping(BRICK, Vector3(0.0, 0.0, -9.0), 3.0)
	audio.on_ping(_book, YOU)
	assert_eq(_pips(audio), 2, "your second ping pips though a teammate's landed in the same tick")


func test_your_ping_after_a_new_round_pips_again() -> void:
	var audio := _audio()
	_ping(YOU, Vector3(0.0, 0.0, -9.0), 1.0)
	audio.on_ping(_book, YOU)
	_book.clear()
	audio.on_ping(_book, YOU)
	_ping(YOU, Vector3(0.0, 0.0, -9.0), 20.0)
	audio.on_ping(_book, YOU)
	assert_eq(_pips(audio), 2)


func test_an_eliminated_teammates_ping_still_shows_only_until_its_lifetime() -> void:
	# A ping outlives its owner (the book keeps it its lifetime); it must not outlast it or crash the HUD.
	_ping(BRICK, Vector3(0.0, 0.0, -9.0), 1.0)
	_state.characters[BRICK].status = Character.Status.OUT
	_place(2.0)
	var shown := _hud.ping_markers().shown()
	_place(1.0 + _sim.pings.lifetime + 0.01)
	assert_eq(_hud.ping_markers().shown(), 0, "expired (it showed %d while within its life)" % shown)


func test_a_pinned_marker_behind_you_stays_inside_the_screen() -> void:
	_ping(YOU, Vector3(0.0, 0.0, 9.0), 1.0)
	_ping(BRICK, Vector3(-4.0, 0.0, 12.0), 1.0, true)
	_place(2.0)
	var area := _hud.size
	for id: int in [YOU, BRICK]:
		var m := _hud.ping_markers().marker_of(id)
		assert_true(m.visible and m.pinned(), "behind you is pinned")
		assert_true(m.position.x >= 0.0 and m.position.x + m.size.x <= area.x + 0.5, "inside horizontally")
		assert_true(m.position.y >= 0.0 and m.position.y + m.size.y <= area.y + 0.5, "inside vertically")
