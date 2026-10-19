extends GutTest
## How the menus grow with the window (game/ui/menu_scale.gd): the window height over 1080, at most 1.5, and the
## content scale factor that takes the rest of the stretch back.


func test_1080p_draws_as_designed() -> void:
	assert_almost_eq(MenuScale.scale_for(Vector2(1920.0, 1080.0)), 1.0, 1e-5)
	assert_almost_eq(MenuScale.content_factor(Vector2(1920.0, 1080.0)), 1.0, 1e-5)


func test_a_taller_window_grows_the_menus_by_its_height() -> void:
	assert_almost_eq(MenuScale.scale_for(Vector2(2560.0, 1440.0)), 1440.0 / 1080.0, 1e-5)
	# the stretch already gives 4/3, so no factor is taken back below the cap
	assert_almost_eq(MenuScale.content_factor(Vector2(2560.0, 1440.0)), 1.0, 1e-5)


func test_4k_draws_at_the_cap_not_double() -> void:
	assert_almost_eq(MenuScale.scale_for(Vector2(3840.0, 2160.0)), 1.5, 1e-5)
	assert_almost_eq(MenuScale.content_factor(Vector2(3840.0, 2160.0)), 0.75, 1e-5, "2x stretch times 0.75 is 1.5x")


func test_a_small_window_shrinks_with_the_stretch() -> void:
	assert_almost_eq(MenuScale.scale_for(Vector2(1280.0, 720.0)), 720.0 / 1080.0, 1e-5)
	assert_almost_eq(MenuScale.content_factor(Vector2(1280.0, 720.0)), 1.0, 1e-5, "never enlarged back")


func test_a_narrow_tall_window_keeps_the_layouts_width() -> void:
	# aspect "expand" scales by the narrower side, so the 1920 px of width always fit
	assert_almost_eq(MenuScale.scale_for(Vector2(1000.0, 2000.0)), 1000.0 / 1920.0, 1e-5)


func test_an_unmeasured_window_is_left_alone() -> void:
	assert_eq(MenuScale.scale_for(Vector2.ZERO), 1.0)
	assert_eq(MenuScale.content_factor(Vector2(0.0, 1080.0)), 1.0)
	assert_eq(MenuScale.scale_for(Vector2(NAN, NAN)), 1.0)


func test_apply_sets_the_window_for_menus_and_resets_it_for_play() -> void:
	var window := Window.new()
	window.size = Vector2i(3840, 2160)
	MenuScale.apply(window, true)
	assert_almost_eq(window.content_scale_factor, 0.75, 1e-5)
	MenuScale.apply(window, false)
	assert_almost_eq(window.content_scale_factor, 1.0, 1e-5)
	window.free()
