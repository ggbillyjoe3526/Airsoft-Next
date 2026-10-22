extends GutTest
## The HUD in the menus' look (game/ui/hud_style.gd, hud_score.gd, hud_banner.gd): one pip per win needed, filled up to
## the wins and never past them; the clock and banner words; a banner's lines and colour; nothing redraws on an
## unchanged value.

var teams: TeamConfig
var score: HudScore


func before_each() -> void:
	teams = TeamConfig.new()
	score = HudScore.new()
	add_child_autofree(score)
	score.setup(teams, 5)


func test_five_pips_a_side_for_five_wins() -> void:
	assert_eq(score.pip_count(), 5)
	var wins := RoundConfig.new().wins_needed
	var other := HudScore.new()
	add_child_autofree(other)
	other.setup(teams, wins)
	assert_eq(other.pip_count(), wins, "as many pips as wins the match needs")


func test_pips_fill_up_to_the_wins() -> void:
	score.set_score(2, 1)
	assert_eq(score.pips_filled(0), 2)
	assert_eq(score.pips_filled(1), 1)
	score.set_score(0, 5)
	assert_eq(score.pips_filled(0), 0)
	assert_eq(score.pips_filled(1), 5)


func test_wins_past_the_target_fill_every_pip_and_no_more() -> void:
	assert_eq(HudStyle.pips_filled(7, 5), 5)
	assert_eq(HudStyle.pips_filled(-1, 5), 0)
	assert_eq(HudStyle.pips_filled(3, 0), 0)


func test_the_score_shows_as_numbers() -> void:
	score.set_score(3, 4)
	assert_eq(score.score_text(0), "3")
	assert_eq(score.score_text(1), "4")


func test_the_clock_reads_minutes_and_two_digit_seconds() -> void:
	assert_eq(HudStyle.clock_text(107), "1:47")
	assert_eq(HudStyle.clock_text(60), "1:00")
	assert_eq(HudStyle.clock_text(5), "0:05")
	assert_eq(HudStyle.clock_text(-3), "0:00", "never negative")


func test_the_round_line_is_in_capitals() -> void:
	score.set_round(4)
	assert_eq(HudStyle.round_title(4), "ROUND 4")


func test_the_aim_line_names_the_wins_needed() -> void:
	assert_eq(HudStyle.first_to(5), "FIRST TO 5")


func test_the_side_block_grows_with_its_pips() -> void:
	assert_almost_eq(HudStyle.side_width(5), 32.0 + 5.0 * 16.0 + 4.0 * 6.0, 0.001)
	assert_gt(HudStyle.side_width(6), HudStyle.side_width(5))


func test_half_time_is_named_on_the_round_after_the_half_only() -> void:
	var half := RoundConfig.new().half_time_after
	assert_eq(HudStyle.round_sub(half + 1, half), "HALF TIME · ENDS SWAPPED")
	assert_eq(HudStyle.round_sub(half, half), "")
	assert_eq(HudStyle.round_sub(1, half), "")


func test_the_won_banners_name_the_team_in_capitals() -> void:
	assert_eq(HudStyle.round_won(teams.names[0]), "ALPHA TAKE THE ROUND")


func test_a_banner_shows_its_two_lines_and_hides_an_empty_one() -> void:
	var banner := HudBanner.new()
	add_child_autofree(banner)
	banner.setup()
	assert_false(banner.visible, "hidden until shown")
	banner.show_text("ROUND 4", "HALF TIME · ENDS SWAPPED")
	assert_true(banner.visible)
	assert_eq(banner.big_text(), "ROUND 4")
	assert_eq(banner.sub_text(), "HALF TIME · ENDS SWAPPED")
	banner.show_text("", "RICOCHET: PLAY ON")
	assert_eq(banner.big_text(), "")
	assert_eq(banner.sub_text(), "RICOCHET: PLAY ON")


func test_the_backing_is_the_page_colour_at_its_opacity() -> void:
	var c := HudStyle.backing(HudStyle.BACKING_BANNER)
	assert_eq(Color(c, 1.0), GameTheme.BG)
	assert_almost_eq(c.a, HudStyle.BACKING_BANNER, 0.0001)
