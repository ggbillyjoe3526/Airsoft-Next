extends GutTest
## IssueLink (SV4): the address, its title and body, the fence, and each cut step as the browser game cut it: lists
## 10, 3, 0, then Settings changed and Dev settings, then the first lines that fit; and a report too long for any.

const BASE := "https://github.com/ggbillyjoe3526/Airsoft-Next/issues/new"
const BugReportTest := preload("res://tests/unit/test_bug_report.gd")

var _config: ReportConfig


func before_each() -> void:
	_config = ReportConfig.new()


## A long report: 30 events, 20 errors and a long settings line, so every cut step makes it shorter.
func _long_info() -> BugReport.ReportInfo:
	var info := BugReportTest.picture_info()
	info.events = PackedStringArray()
	for i in _config.events:
		info.events.append("t%d Beta 2 SHOT ×%d GBB Pistol" % [1000 + i * 37, i + 1])
	info.errors = PackedStringArray()
	for i in _config.errors:
		info.errors.append("ERROR res://game/x%d.gd:%d (f): something went wrong number %d" % [i, i * 3, i])
	var changed := PackedStringArray()
	for i in 40:
		changed.append("hud.setting_%d %d" % [i, i])
	info.settings_changed = ", ".join(changed)
	info.dev_settings = "on: game_speed 2, ghost on, bottomless on"
	return info


static func _query(url: String, key: String) -> String:
	var start := url.find(key + "=") + key.length() + 1
	var end := url.find("&", start)
	return url.substr(start, end - start if end >= 0 else -1).replace("+", " ").uri_decode()


func test_the_address_title_and_body() -> void:
	var info := BugReportTest.picture_info()
	var link := IssueLink.make(info, _config)
	assert_false(link.cut)
	assert_string_starts_with(link.url, BASE + "?title=")
	assert_eq(_query(link.url, "title"), "Bug: " + BugReportTest.NOTE)
	var body := _query(link.url, "body")
	assert_eq(body, BugReportTest.NOTE + "\n\n```text\n" + BugReportTest.REPORT + "\n```")
	assert_false(link.url.contains(" "), "spaces as +")


func test_without_a_note_the_title_names_the_version_and_the_body_asks() -> void:
	var info := BugReportTest.picture_info()
	info.note = "  \n "
	var link := IssueLink.make(info, _config)
	assert_eq(_query(link.url, "title"), "Bug report (0.1 Dev 3 (exported, release))")
	assert_string_starts_with(_query(link.url, "body"), IssueLink.ASK_WHAT + "\n\n```text\nAirsoft bug report\nVersion:")
	assert_eq(IssueLink.issue_title("", "0.1 Dev 3", _config.title_chars), "Bug report (0.1 Dev 3)")


func test_the_title_is_the_notes_first_line_clipped() -> void:
	var long := "x".repeat(100)
	var title := IssueLink.issue_title(long + "\nsecond line", "v", _config.title_chars)
	assert_eq(title, "Bug: " + "x".repeat(_config.title_chars - 1) + "…")
	assert_eq(IssueLink.issue_title("\n\n  short   one \nmore", "v", _config.title_chars), "Bug: short one")


func test_a_note_is_cut_to_note_chars() -> void:
	var info := BugReportTest.picture_info()
	info.note = "y".repeat(_config.note_chars + 50)
	var body := _query(IssueLink.make(info, _config).url, "body")
	assert_string_starts_with(body, "y".repeat(_config.note_chars) + "\n\n```")


func test_a_note_with_backticks_and_a_hash_stays_inside_a_longer_fence() -> void:
	var info := BugReportTest.picture_info()
	info.note = "Same as #3: the `ammo` count and ```` four"
	var link := IssueLink.make(info, _config)
	var body := _query(link.url, "body")
	var fence := "`````"
	assert_string_contains(body, "\n" + fence + "text\nAirsoft bug report\nNote: Same as #3: the `ammo` count and ```` four\n")
	assert_true(body.ends_with("\n" + fence), "closed by the same fence")
	assert_eq(IssueLink.longest_backticks(body.substr(0, body.find(fence))), 4, "no longer run before it")
	assert_true(link.url.contains("%233"), "the # is encoded, not a fragment")
	assert_false(link.url.contains("#"))


## Each step in turn: the limit set to exactly that step's length gives that step, cut said when past the first.
func test_each_cut_step() -> void:
	var info := _long_info()
	var title := IssueLink.issue_title(info.note, info.version, _config.title_chars)
	var steps: Array[BugReport.Cut] = [BugReport.Cut.new(), BugReport.Cut.new(10), BugReport.Cut.new(3),
			BugReport.Cut.new(0), BugReport.Cut.new(0, _config.drop_fields)]
	var lengths: Array[int] = []
	for i in steps.size():
		var url := IssueLink.address(BASE, title, info.note, BugReport.write(info, steps[i]), i > 0)
		lengths.append(url.length())
		if i > 0:
			assert_lt(lengths[i], lengths[i - 1], "step %d is shorter" % i)
	var expect: Array[String] = ["Recent events (30):", "Recent events (newest 10 of 30):",
			"Recent events (newest 3 of 30):", "Recent events: 30 (left out to fit)", "Settings changed: (left out to fit)"]
	for i in steps.size():
		_config.max_url_chars = lengths[i]
		var link := IssueLink.make(info, _config)
		assert_eq(link.url.length(), lengths[i], "step %d" % i)
		assert_eq(link.cut, i > 0, "step %d says it cut" % i)
		var body := _query(link.url, "body")
		assert_string_contains(body, expect[i])
		assert_eq(body.contains(IssueLink.CUT_NOTE), i > 0, "the paste line, step %d" % i)
	assert_string_contains(_query(IssueLink.make(info, _config).url, "body"), "Dev settings: (left out to fit)")


func test_too_long_for_any_cut_gives_the_first_lines_that_fit() -> void:
	var info := _long_info()
	info.settings_changed = "z".repeat(9000)
	var link := IssueLink.make(info, _config)
	assert_true(link.cut)
	assert_lte(link.url.length(), _config.max_url_chars)
	var body := _query(link.url, "body")
	assert_string_contains(body, IssueLink.CUT_NOTE)
	assert_string_contains(body, "\nScreen: in play\n", "the first lines")
	assert_true(body.ends_with("\n```"), "the fence closes")
	# Tighter still: fewer lines, never over.
	_config.max_url_chars = 2000
	link = IssueLink.make(info, _config)
	assert_true(link.cut)
	assert_lte(link.url.length(), 2000)
	assert_string_contains(_query(link.url, "body"), "```text\nAirsoft bug report\nNote: ")


func test_a_limit_below_the_bare_address_still_answers() -> void:
	var info := _long_info()
	_config.max_url_chars = 10
	var link := IssueLink.make(info, _config)
	assert_true(link.cut)
	assert_string_ends_with(_query(link.url, "body"), "```text\n\n```")


func test_the_config_is_the_owners() -> void:
	var c := ReportConfig.load_default()
	assert_eq(c.issue_url, BASE)
	assert_eq(c.max_url_chars, 8000)
	assert_eq(c.keep_steps, PackedInt32Array([10, 3, 0]))
	assert_eq(c.drop_fields, PackedStringArray([BugReport.SETTINGS_CHANGED, BugReport.DEV_SETTINGS]))
	assert_eq(c.note_chars, 500)
	assert_eq(c.title_chars, 70)
	assert_eq(c.events, 30)
	assert_eq(c.burst_ticks, 60)
	assert_eq(c.frame_seconds, 10.0)
	assert_eq(c.hitch_ms, 50.0)
	assert_eq(c.log_lines, 40)


## QA: no scrub given still scrubs (for this machine), and the note is scrubbed before it is cut.
func test_fails_closed_and_scrubs_the_note_before_the_cut() -> void:
	var info := BugReportTest.picture_info()
	info.scrub = null
	info.note = "saved in " + OS.get_user_data_dir()
	var link := IssueLink.make(info, _config)
	assert_eq(_query(link.url, "title"), "Bug: saved in <save folder>")
	assert_false(link.url.uri_decode().contains(OS.get_user_data_dir()))
	info.scrub = ReportScrub.new("", "", "William", "")
	info.note = "a".repeat(_config.note_chars - 4) + " William"
	var body := _query(IssueLink.make(info, _config).url, "body")
	assert_false(body.contains("Willia"), "no part of the name")
	assert_string_starts_with(body, "a".repeat(_config.note_chars - 4) + " <yo\n")
