extends GutTest
## BugReport (SV4): a full report and a crash report against the step 22 pictures' text, "-" for what isn't known,
## the cut (lists' newest entries, fields left out), and every line scrubbed.

const NOTE := "Bot on Beta walked through the container door while it was shut"
const CRASH_NOTE := "Threw myself over the low wall by the crates just as round 4 started"
const ERROR := "SCRIPT ERROR res://game/ui/hud_feed.gd:88 (_add_row): Invalid access to key \"name\" ×3"

const REPORT := """Airsoft bug report
Note: Bot on Beta walked through the container door while it was shut
Version: 0.1 Dev 3 (exported, release)
Godot: 4.7.2.stable.official.ed1daf0bf
System: Windows 11 (10.0.22631), 16 threads, 32 GB
Graphics card: NVIDIA GeForce RTX 3070 (driver 566.36)
Renderer: Forward+ (Vulkan) · High
Window: fullscreen 2560 × 1440 at 144 Hz
Language: en
Time: Fri 23 Oct 2026 14:32 UTC, 12:40 after start
Seed: 48213
Match: Depot · Elimination · Standard rules · 3v3 · Normal
Round: 4 (live), score 2–1, tick 11523, 3:12 in
Screen: in play
Player: at (12.4, 0.0, -8.1) facing 212°, crouched, AEG Rifle 17/60, 3 spare
Frames: last 10 s 141 fps average, worst 38 ms, 2 hitches
Dev settings: none
Settings changed: fov 100, sensitivity 2.1, team_colours high_contrast
Recent errors (1):
  SCRIPT ERROR res://game/ui/hud_feed.gd:88 (_add_row): Invalid access to key "name" ×3
Recent events (4):
  t11402 Beta 2 SHOT ×4 GBB Pistol
  t11455 You RELOAD_START AEG Rifle
  t11488 Alpha 3 HIT Beta 1
  t11520 Beta 2 SHOT ×2 GBB Pistol"""

const CRASH_REPORT := """Airsoft crash report
Note: Threw myself over the low wall by the crates just as round 4 started
Version: 0.1 Dev 3 (exported, release)
Godot: 4.7.2.stable.official.ed1daf0bf
System: Windows 11 (10.0.22631), 16 threads, 32 GB
Graphics card: NVIDIA GeForce RTX 3070 (driver 566.36)
Renderer: Forward+ (Vulkan) · High
Window: fullscreen 2560 × 1440 at 144 Hz
Language: en
Closed: about Fri 23 Oct 2026 14:32 UTC (the log's last line), 12:40 after start
Seed: 48213
Match: Depot · Elimination · Standard rules · 3v3 · Normal
Round: 4 had started, score 2–1
Screen: in play
Dev settings: none
Settings changed: fov 100, sensitivity 2.1, team_colours high_contrast
Recent errors (1):
  SCRIPT ERROR res://game/ui/hud_feed.gd:88 (_add_row): Invalid access to key "name" ×3
Last log lines (last 8 of 4,812):
  …
  [play] round 4 live
  ========================================
  CrashHandlerException: Program crashed
  Engine version: Godot Engine v4.7.2.stable.official
  [0] RenderingDevice::draw_list_draw
  [1] RendererSceneRenderRD::_render_scene
  … 6 more
  Airsoft crashed. Start it again: it offers to report the bug."""


static func picture_info(crash: bool = false) -> BugReport.ReportInfo:
	var info := BugReport.ReportInfo.new()
	info.crash = crash
	info.note = CRASH_NOTE if crash else NOTE
	info.version = "0.1 Dev 3 (exported, release)"
	info.godot = "4.7.2.stable.official.ed1daf0bf"
	info.system = "Windows 11 (10.0.22631), 16 threads, 32 GB"
	info.graphics_card = "NVIDIA GeForce RTX 3070 (driver 566.36)"
	info.renderer = "Forward+ (Vulkan) · High"
	info.window = "fullscreen 2560 × 1440 at 144 Hz"
	info.language = "en"
	info.seed_text = "48213"
	info.match_text = "Depot · Elimination · Standard rules · 3v3 · Normal"
	info.screen = "in play"
	info.dev_settings = "none"
	info.settings_changed = "fov 100, sensitivity 2.1, team_colours high_contrast"
	info.errors = PackedStringArray([ERROR])
	if crash:
		info.time = "about Fri 23 Oct 2026 14:32 UTC (the log's last line), 12:40 after start"
		info.round_text = "4 had started, score 2–1"
		info.log_lines = PackedStringArray(["[play] round 4 live", "=".repeat(40),
				"CrashHandlerException: Program crashed", "Engine version: Godot Engine v4.7.2.stable.official",
				"[0] RenderingDevice::draw_list_draw", "[1] RendererSceneRenderRD::_render_scene", "… 6 more",
				"Airsoft crashed. Start it again: it offers to report the bug."])
		info.log_count = 4812
	else:
		info.time = "Fri 23 Oct 2026 14:32 UTC, 12:40 after start"
		info.round_text = "4 (live), score 2–1, tick 11523, 3:12 in"
		info.player = "at (12.4, 0.0, -8.1) facing 212°, crouched, AEG Rifle 17/60, 3 spare"
		info.frames = "last 10 s 141 fps average, worst 38 ms, 2 hitches"
		info.events = PackedStringArray(["t11402 Beta 2 SHOT ×4 GBB Pistol", "t11455 You RELOAD_START AEG Rifle",
				"t11488 Alpha 3 HIT Beta 1", "t11520 Beta 2 SHOT ×2 GBB Pistol"])
	return info


func test_a_full_report_is_the_pictures() -> void:
	assert_eq(BugReport.write(picture_info()), REPORT)


func test_a_crash_report_is_the_pictures() -> void:
	assert_eq(BugReport.write(picture_info(true)), CRASH_REPORT)


func test_nothing_known_reads_dashes_and_no_note_no_note_line() -> void:
	var text := BugReport.write(BugReport.ReportInfo.new())
	assert_eq(text, "\n".join(PackedStringArray(["Airsoft bug report", "Version: -", "Godot: -", "System: -",
			"Graphics card: -", "Renderer: -", "Window: -", "Language: -", "Time: -", "Seed: -", "Match: -",
			"Round: -", "Screen: -", "Player: -", "Frames: -", "Dev settings: -", "Settings changed: -",
			"Recent errors: none", "Recent events: none"])))
	var crash := BugReport.ReportInfo.new()
	crash.crash = true
	assert_string_ends_with(BugReport.write(crash), "Closed: -\nSeed: -\nMatch: -\nRound: -\nScreen: -\n"
			+ "Dev settings: -\nSettings changed: -\nRecent errors: none\nLast log lines: -")


func test_the_note_is_one_line_in_the_report() -> void:
	var info := BugReport.ReportInfo.new()
	info.note = "  first line\n\tsecond   line\r\n"
	assert_string_contains(BugReport.write(info), "\nNote: first line second line\n")


func test_a_cut_keeps_each_lists_newest() -> void:
	var info := picture_info()
	var text := BugReport.write(info, BugReport.Cut.new(2))
	assert_string_contains(text, "Recent errors (1):\n  SCRIPT ERROR")
	assert_string_ends_with(text, "Recent events (newest 2 of 4):\n  t11488 Alpha 3 HIT Beta 1\n"
			+ "  t11520 Beta 2 SHOT ×2 GBB Pistol")
	assert_string_ends_with(BugReport.write(info, BugReport.Cut.new(0)), "Recent errors: 1 (left out to fit)\n"
			+ "Recent events: 4 (left out to fit)")


func test_a_cut_shortens_the_log_and_drops_fields() -> void:
	var info := picture_info(true)
	var text := BugReport.write(info, BugReport.Cut.new(3, PackedStringArray(["Settings changed", "Dev settings"])))
	assert_string_contains(text, "\nDev settings: (left out to fit)\nSettings changed: (left out to fit)\n")
	assert_string_ends_with(text, "Last log lines (last 3 of 4,812):\n  …\n  [1] RendererSceneRenderRD::_render_scene\n"
			+ "  … 6 more\n  Airsoft crashed. Start it again: it offers to report the bug.")
	assert_string_ends_with(BugReport.write(info, BugReport.Cut.new(0)), "Last log lines: 4,812 lines, (left out to fit)")


func test_a_whole_short_log_has_no_ellipsis() -> void:
	var info := BugReport.ReportInfo.new()
	info.crash = true
	info.log_lines = PackedStringArray(["a", "b"])
	info.log_count = 2
	assert_string_ends_with(BugReport.write(info), "Last log lines (last 2 of 2):\n  a\n  b")


func test_thousands() -> void:
	assert_eq(BugReport.thousands(0), "0")
	assert_eq(BugReport.thousands(999), "999")
	assert_eq(BugReport.thousands(4812), "4,812")
	assert_eq(BugReport.thousands(1234567), "1,234,567")


func test_every_line_goes_through_the_scrub() -> void:
	var info := picture_info(true)
	info.scrub = ReportScrub.new("", "/home/zed", "zed", "")
	info.note = "zed here"
	info.log_lines.append("Loading /home/zed/x.pck")
	info.errors.append("ERROR /home/zed/a.gd:1 (f): zed")
	var text := BugReport.write(info)
	assert_false(text.containsn("zed"), text)
	assert_string_contains(text, "Note: <you> here")
	assert_string_contains(text, "  Loading ~/x.pck")


## QA: the note is scrubbed, then cut, in the report's own Note line too.
func test_the_note_line_is_scrubbed_then_cut() -> void:
	var info := BugReport.ReportInfo.new()
	info.note_chars = 20
	info.note = "it was me William Smith all along"
	info.scrub = ReportScrub.new("", "", "William", "")
	assert_string_contains(BugReport.write(info), "\nNote: it was me <you> Smit\n")
	info.scrub = null
	info.note = "x".repeat(30)
	assert_string_contains(BugReport.write(info), "\nNote: %s\n" % "x".repeat(20))


func test_a_given_scrub_stands_in_for_the_infos() -> void:
	var info := BugReport.ReportInfo.new()
	info.note = "from bob"
	assert_string_contains(BugReport.write(info, null, ReportScrub.new("", "", "bob", "")), "Note: from <you>")


## QA: a log line's carriage return (a Windows log) goes.
func test_carriage_returns_go() -> void:
	var info := BugReport.ReportInfo.new()
	info.crash = true
	info.errors = PackedStringArray(["ERROR a\r"])
	info.log_lines = PackedStringArray(["one\r", "two\r"])
	info.log_count = 2
	assert_false(BugReport.write(info).contains("\r"))
