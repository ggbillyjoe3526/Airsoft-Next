extends GutTest
## HD2: the big "HIT!", its walk-off line and a round's banner hang under the score bar and never overlap it or each other,
## at every window shape, HUD size and with or without the banner; the banner keeps its place as the hit call ends; the
## cards under the stack (the round's table, the match summary) hang from its foot.

const HudSizeTest := preload("res://tests/unit/test_hud_size.gd")
const WINDOWS: Array[Vector2] = [Vector2(1280.0, 720.0), Vector2(1920.0, 1080.0), Vector2(3840.0, 2160.0),
		Vector2(1024.0, 768.0), Vector2(2560.0, 1080.0)]
const SIZES: Array[float] = [0.8, 1.0, 1.5]
## Rects may touch within this (px, float rounding).
const SLACK := 0.5

var you: Character = null
var state: GameState = null


func before_each() -> void:
	you = Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	you.prev_position = you.position
	state = GameState.new(1)
	state.characters.append(you)


## A HUD on a screen of `window` (the game's canvas for that window) at `hud_size`, laid out.
func _hud(window: Vector2, hud_size: float) -> Hud:
	var area := HudSizeTest.canvas_of(window)
	var frame := Control.new()
	frame.size = area
	add_child_autofree(frame)
	var hud := Hud.new()
	frame.add_child(hud)
	hud.setup(HudConfig.new(), TeamConfig.new(), ViewConfig.new(), SimTuning.new(), you)
	var prefs := HudPrefs.new()
	prefs.hud_size = hud_size
	hud.apply_prefs(prefs)
	hud._stats = MatchStats.new()
	hud._names = PackedStringArray(["You"])
	return hud


## The stack's parts that show, top to bottom, as the HUD's own screen rects.
func _stack(hud: Hud) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for part: Control in [hud._hit_label, hud._hit_sub, hud._banner]:
		if part.is_visible_in_tree():
			rects.append(part.get_global_rect())
	return rects


func _check(hud: Hud, label: String) -> void:
	var bar := hud._top.get_global_rect()
	var rects := _stack(hud)
	for i in rects.size():
		assert_gte(rects[i].position.y, bar.end.y - SLACK, "%s: part %d is under the score bar" % [label, i])
		if i > 0:
			assert_gte(rects[i].position.y, rects[i - 1].end.y - SLACK, "%s: part %d clears the one above" % [label, i])


func _show(hud: Hud, status: Character.Status, banner: bool) -> void:
	you.status = status
	if banner:
		hud._show_banner("LOST", "ROUND 1 · BETA TAKE THE ROUND")
	else:
		hud._banner.visible = false
	hud.update(state, 1.0, 0.0)


func test_the_hit_call_and_banner_stay_under_the_score_bar() -> void:
	var cases := 0
	for window in WINDOWS:
		for hud_size in SIZES:
			for banner: bool in [false, true]:
				for status: Character.Status in [Character.Status.CALLING, Character.Status.ALIVE]:
					var hud := _hud(window, hud_size)
					_show(hud, status, banner)
					await wait_process_frames(3)
					var label := "%s at %d%%, %s, banner %s" % [window, roundi(hud_size * 100.0), status, banner]
					_check(hud, label)
					cases += 1
					if status == Character.Status.CALLING:
						assert_true(hud._hit_label.is_visible_in_tree(), label + ": HIT! shows")
					hud.get_parent().queue_free()
	assert_eq(cases, 60)


func test_the_step_down_line_under_the_bar_pushes_the_stack_down() -> void:
	var hud := _hud(Vector2(1920.0, 1080.0), 1.0)
	_show(hud, Character.Status.CALLING, true)
	await wait_process_frames(3)
	var before := hud._hit_label.get_global_rect().position.y
	hud.show_graphics_step("Low", 5.0)
	hud.update(state, 1.0, 0.0)
	await wait_process_frames(3)
	_check(hud, "with the step-down line")
	assert_gt(hud._hit_label.get_global_rect().position.y, before, "HIT! made room for the line")


func test_the_banner_keeps_its_place_as_the_hit_call_ends() -> void:
	for hud_size in SIZES:
		var hud := _hud(Vector2(1920.0, 1080.0), hud_size)
		_show(hud, Character.Status.CALLING, true)
		await wait_process_frames(3)
		var at := hud._banner.get_global_rect().position.y
		_show(hud, Character.Status.OUT, true)
		await wait_process_frames(3)
		assert_false(hud._hit_label.is_visible_in_tree(), "the call is over")
		assert_almost_eq(hud._banner.get_global_rect().position.y, at, 0.01, "the banner did not move at %s" % hud_size)
		# The next round: the banner goes, and a banner alone sits right under the bar again.
		_show(hud, Character.Status.ALIVE, false)
		_show(hud, Character.Status.ALIVE, true)
		await wait_process_frames(3)
		assert_lt(hud._banner.get_global_rect().position.y, at, "no slot is kept for a hit call that is not there")
		hud.get_parent().queue_free()


func test_the_cards_hang_under_the_stack() -> void:
	for hud_size in SIZES:
		var hud := _hud(Vector2(1920.0, 1080.0), hud_size)
		_show(hud, Character.Status.CALLING, true)
		await wait_process_frames(3)
		var foot := hud._banner.get_global_rect().end.y
		assert_gte(hud._round_result.get_global_rect().position.y, foot - SLACK, "the round's table is under the banner")
		assert_gte(hud._summary._table.get_global_rect().position.y, foot - SLACK, "the summary is under the banner")
		hud.get_parent().queue_free()
