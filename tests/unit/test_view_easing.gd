extends GutTest
## The view's easing on rendered frames (game/play/first_person_view.gd; the browser game's renderView.ts leanCut): a
## lean a wall cuts short eases out instead of snapping, never drawn more than lean_cut_allowance metres out from the
## simulation's eye, and a normal release is drawn as it is.

const FRAME := 1.0 / 144.0
const HEIGHT := 1.62

var view: FirstPersonView
var cfg: ViewConfig
var hits: HitConfig


func before_each() -> void:
	view = FirstPersonView.new()
	cfg = ViewConfig.new()
	hits = HitConfig.new()
	view._view = cfg
	view._hits = hits


func after_each() -> void:
	view.free()


func eye_gap(drawn: float, sim: float) -> float:
	return (Lean.offset(HEIGHT, drawn, 0.0, 0.0, hits) - Lean.offset(HEIGHT, sim, 0.0, 0.0, hits)).length()


func test_a_cut_lean_eases_out_within_the_allowance() -> void:
	view._lean = 1.0
	var drawn := view._ease_lean(0.0, HEIGHT, 0.0, 0.0, FRAME, true)
	assert_gt(drawn, 0.0, "not snapped in one frame")
	assert_lte(eye_gap(drawn, 0.0), cfg.lean_cut_allowance + 1e-4, "never drawn into the wall")
	view._lean = drawn
	var frames := 0
	while view._lean > 0.0 and frames < 200:
		view._lean = view._ease_lean(0.0, HEIGHT, 0.0, 0.0, FRAME, true)
		frames += 1
	assert_almost_eq(frames * FRAME, cfg.lean_cut_ease_time * drawn, FRAME * 2.0, "out at a full lean per ease time")


func test_a_normal_lean_and_release_are_drawn_as_they_are() -> void:
	var step := FRAME / SimTuning.new().movement.lean_time
	var lean := 0.0
	for i in 40:
		lean = minf(1.0, lean + step)
		view._lean = view._ease_lean(lean, HEIGHT, 0.0, 0.0, FRAME, true)
		assert_almost_eq(view._lean, lean, 1e-6)
	for i in 40:
		lean = maxf(0.0, lean - step)
		view._lean = view._ease_lean(lean, HEIGHT, 0.0, 0.0, FRAME, true)
		assert_almost_eq(view._lean, lean, 1e-6)


func test_spectating_draws_the_lean_as_it_is() -> void:
	view._lean = 1.0
	assert_eq(view._ease_lean(0.0, HEIGHT, 0.0, 0.0, FRAME, false), 0.0)


func test_a_zero_ease_time_or_a_zero_frame_never_makes_the_lean_nan() -> void:
	view._lean = 1.0
	cfg.lean_cut_ease_time = 0.0
	var drawn := view._ease_lean(0.0, HEIGHT, 0.0, 0.0, FRAME, true)
	assert_false(is_nan(drawn), "ease time 0")
	cfg.lean_cut_ease_time = 0.1
	drawn = view._ease_lean(0.0, HEIGHT, 0.0, 0.0, 0.0, true)
	assert_false(is_nan(drawn), "a zero-length frame")
	cfg.lean_cut_ease_time = 0.0
	drawn = view._ease_lean(0.0, HEIGHT, 0.0, 0.0, 0.0, true)
	assert_false(is_nan(drawn), "both")


func test_a_long_frame_lands_on_the_simulation_lean() -> void:
	view._lean = 1.0
	assert_almost_eq(view._ease_lean(0.0, HEIGHT, 0.0, 0.0, 5.0, true), 0.0, 1e-6, "a stall doesn't overshoot")
