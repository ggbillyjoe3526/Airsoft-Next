extends GutTest
## Accessibility's data (AC1): data/accessibility.md read by AccessibilityTable, each unreadable cell keeping its built-in
## value with an "accessibility.md:line:" warning; the team colour sets resolved by TeamColours for day and night; and
## AccessibilityConfig's numbers.

const COLOURS_HEAD := """## Team colours

| Set | Part | Alpha | Beta | Paint glow (day) |
|---|---|---|---|---|
"""
const MOTION_HEAD := """## Reduced motion

| ID | Motion | Share |
|---|---|---|
"""
## The plan's shares, by AccessibilityTable.MOTION_IDS.
const PLAN_MOTION: Dictionary[StringName, float] = {
	&"sway": 0.0, &"kick": 0.5, &"lean_roll": 0.25, &"vault_tip": 0.25, &"reload_cant": 0.5, &"dust": 0.0,
	&"hud_pulse": 0.0, &"hit_jolt": 0.5,
}
## A colour written as #rrggbb matches one within half a step of 8 bits each way.
const HEX_SLACK := 1.0 / 255.0 + 1e-6

var table: AccessibilityTable


func before_all() -> void:
	table = AccessibilityTable.read_file()


func _has_problem(t: AccessibilityTable, text: String) -> bool:
	for p in t.problems:
		if p.contains(text):
			return true
	return false


## The shipped file with `old` replaced by `new` once, and the line it was on.
func _edited(old: String, new: String) -> Array:
	var text := FileAccess.get_file_as_string(AccessibilityTable.PATH)
	var at := text.find(old)
	assert_gt(at, -1, "%s is in the file" % old)
	var line := text.substr(0, at).count("\n") + 1
	return [AccessibilityTable.parse(text.substr(0, at) + new + text.substr(at + old.length())), line]


func _assert_colour(a: Color, b: Color, what: String) -> void:
	var off := maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))
	assert_lt(off, HEX_SLACK, "%s: #%s against #%s" % [what, a.to_html(false), b.to_html(false)])


func test_the_shipped_file_reads_without_a_problem() -> void:
	assert_eq(table.problems, [] as Array[String], "data/accessibility.md reads cleanly")


func test_the_file_and_the_built_in_values_agree() -> void:
	var built := AccessibilityTable.parse("")
	assert_eq(built.problems, [] as Array[String])
	assert_eq(table.colours, built.colours, "colours")
	assert_eq(table.glow, built.glow, "glow")
	assert_eq(table.motion, built.motion, "shares")


func test_the_tables_are_complete_and_in_range() -> void:
	assert_eq(table.colours.size(), AccessibilityTable.SET_NAMES.size() * AccessibilityTable.PART_NAMES.size() * 2)
	assert_eq(table.glow.size(), AccessibilityTable.SET_NAMES.size())
	for g in table.glow:
		assert_between(g, 0.0, 1.0)
	assert_eq(table.motion.size(), AccessibilityTable.MOTION_IDS.size(), "every movement has a share")
	for id in AccessibilityTable.MOTION_IDS:
		assert_almost_eq(table.share(id), PLAN_MOTION[id], 1e-6, String(id))
	assert_eq(table.share(&"recoil_climb"), 1.0, "a movement not in the table stays whole")


func test_the_plans_colours() -> void:
	var std := table.pair(TeamColours.Set.STANDARD, TeamColours.Part.FIGURES)
	var hc := table.pair(TeamColours.Set.HIGH_CONTRAST, TeamColours.Part.FIGURES)
	var hc_hud := table.pair(TeamColours.Set.HIGH_CONTRAST, TeamColours.Part.HUD)
	assert_eq([hc[0].to_html(false), hc[1].to_html(false)], ["8ccfff", "b8460c"])
	assert_eq([hc_hud[0].to_html(false), hc_hud[1].to_html(false)], ["8ccfff", "e0601a"])
	assert_eq(table.pair(TeamColours.Set.STANDARD, TeamColours.Part.HUD), std, "Standard's HUD is its figures'")
	assert_eq(table.glow, [0.0, 0.3] as Array[float], "High contrast glows on day fields, Standard never")


func test_an_unreadable_colour_keeps_its_built_in_value_and_warns_with_its_line() -> void:
	var r := _edited("| #b8460c |", "| orange |")
	var t: AccessibilityTable = r[0]
	assert_eq(t.pair(TeamColours.Set.HIGH_CONTRAST, TeamColours.Part.FIGURES)[1], Color("b8460c"), "kept")
	assert_true(_has_problem(t, "accessibility.md:%d: Beta \"orange\"" % r[1]), str(t.problems))
	var short := _edited("| #8ccfff | #e0601a |", "| #8cf | #e0601a |")[0] as AccessibilityTable
	assert_eq(short.pair(TeamColours.Set.HIGH_CONTRAST, TeamColours.Part.HUD)[0], Color("8ccfff"), "#rgb isn't read")


func test_an_unreadable_share_or_glow_keeps_its_built_in_value_and_warns() -> void:
	var r := _edited("| reload_cant | The replica's tilt as you reload | 0.5 |", "| reload_cant | x | 1.5 |")
	var t: AccessibilityTable = r[0]
	assert_eq(t.share(&"reload_cant"), 0.5)
	assert_true(_has_problem(t, "accessibility.md:%d: Share \"1.5\"" % r[1]), str(t.problems))
	var glow := _edited("| #b8460c | 0.3 |", "| #b8460c | bright |")[0] as AccessibilityTable
	assert_eq(glow.glow[TeamColours.Set.HIGH_CONTRAST], 0.3)
	assert_true(_has_problem(glow, "Paint glow (day) \"bright\""))


func test_a_share_may_be_a_percentage() -> void:
	var t := AccessibilityTable.parse(MOTION_HEAD + "| kick | k | 40 % |\n")
	assert_almost_eq(t.share(&"kick"), 0.4, 1e-6)


func test_unknown_twice_and_missing_rows_are_reported() -> void:
	var t := AccessibilityTable.parse(COLOURS_HEAD + "| Standard | figures | #000000 | #ffffff | 0 |\n"
			+ "| Standard | figures | #111111 | #eeeeee | 0 |\n| Pastel | figures | #000000 | #ffffff | 0 |\n"
			+ "\n" + MOTION_HEAD + "| wobble | w | 0 |\n")
	assert_eq(t.pair(TeamColours.Set.STANDARD, TeamColours.Part.FIGURES)[0], Color("000000"), "the first row counts")
	assert_true(_has_problem(t, "accessibility.md:6: Standard figures appears twice"), str(t.problems))
	assert_true(_has_problem(t, "accessibility.md:7: \"Pastel\""))
	assert_true(_has_problem(t, "no High contrast hud row"))
	assert_true(_has_problem(t, "\"wobble\" is not a movement"))
	assert_true(_has_problem(t, "no kick row"))
	assert_eq(t.share(&"kick"), 0.5, "a missing row keeps its built-in share")
	assert_eq(t.pair(TeamColours.Set.HIGH_CONTRAST, TeamColours.Part.HUD)[1], Color("e0601a"))


func test_a_file_with_neither_table_uses_the_built_in_values() -> void:
	var t := AccessibilityTable.parse("# Nothing here\n")
	assert_eq(t.colours, AccessibilityTable.parse("").colours)
	assert_true(_has_problem(t, "no Team colours table"))
	assert_true(_has_problem(t, "no Reduced motion table"))
	var gone := AccessibilityTable.read_file("res://data/no-such-file.md")
	assert_true(gone.problems[0].contains("can't be read"))


func test_an_exception_needs_a_prop_a_colour_and_a_reason() -> void:
	var t := AccessibilityTable.parse("## Prop colour exceptions\n\n| Prop | Colour | Reason |\n|---|---|---|\n"
			+ "| crate | #bd9666 | plywood |\n| rack | brown | wood |\n| skip | #cfa133 | |\n")
	assert_eq(t.exceptions.keys(), ["crate"])
	assert_true(_has_problem(t, "accessibility.md:6: an exception needs"), str(t.problems))
	assert_true(_has_problem(t, "accessibility.md:7: an exception needs"))


func test_standard_resolves_to_todays_colours() -> void:
	var today := TeamConfig.new()
	for night: bool in [false, true]:
		var c := TeamColours.resolve(TeamColours.Set.STANDARD, night, table)
		for part: TeamConfig in [c.figures, c.hud]:
			for team in 2:
				_assert_colour(part.colours[team], today.colours[team], "Standard team %d" % team)
			assert_eq(part.names, today.names)
		assert_eq(c.figures.glow, 0.0, "Standard never glows")
		assert_eq(c.hud.glow, 0.0)


func test_high_contrast_resolves_by_part_with_the_glow_by_day_only() -> void:
	var day := TeamColours.resolve(TeamColours.Set.HIGH_CONTRAST, false, table)
	assert_eq(day.figures.colours, PackedColorArray([Color("8ccfff"), Color("b8460c")]))
	assert_eq(day.hud.colours, PackedColorArray([Color("8ccfff"), Color("e0601a")]))
	assert_almost_eq(day.figures.glow, 0.3, 1e-6, "0.3 of its colour on day fields")
	assert_eq(day.hud.glow, 0.0, "the HUD never glows")
	var night := TeamColours.resolve(TeamColours.Set.HIGH_CONTRAST, true, table)
	assert_eq(night.figures.colours, day.figures.colours)
	assert_eq(night.figures.glow, 0.0, "no glow at night")


func test_resolve_keeps_the_names_given_and_the_tables_own_objects() -> void:
	var base := TeamConfig.new()
	base.names = PackedStringArray(["RED", "GOLD"])
	var c := TeamColours.resolve(TeamColours.Set.HIGH_CONTRAST, false, table, base)
	assert_eq(c.figures.names, base.names)
	assert_eq(c.hud.names, base.names)
	c.figures.colours[0] = Color.BLACK
	c.figures.names[0] = "X"
	assert_eq(table.pair(TeamColours.Set.HIGH_CONTRAST, TeamColours.Part.FIGURES)[0], Color("8ccfff"), "a copy")
	assert_eq(base.names[0], "RED", "a copy")
	assert_eq(TeamColours.resolve(TeamColours.Set.STANDARD, false).figures.colours.size(), 2, "the shared table")


func test_the_accessibility_config_holds_the_browsers_numbers() -> void:
	var a := AccessibilityConfig.new()
	assert_eq([a.cue_life, a.cue_fade, a.cue_far_opacity, a.cue_markers, a.cue_ring_radius], [1.4, 0.6, 0.35, 10, 150.0])
	assert_eq(AccessibilityConfig.CUE_SIZE_RANGE, Vector2(0.6, 2.0))
	assert_almost_eq(AccessibilityConfig.CUE_SIZE_STEP, 0.1, 1e-6)
	assert_eq(AccessibilityConfig.HUD_SIZE_RANGE, Vector2(0.8, 1.5))
	assert_almost_eq(AccessibilityConfig.HUD_SIZE_STEP, 0.05, 1e-6)
	assert_eq(AccessibilityConfig.HUD_SIZE_DEFAULT, 1.0)
	assert_eq(HudPrefs.COLOURS[AccessibilityConfig.CUE_COLOUR_DEFAULT], Color("ff3b30"), "red")
