extends GutTest
## ReportFacts (SV4): each field's wording against the step 22 pictures, the settings that differ from a new player's,
## the errors a crashed run's log names, a live report from a real match (its events and frames fed by PlaySession),
## a crash report from a run record and its log, and what building a whole report costs.

const ROOT := "user://test-sv4-logs"
const OLD_LOG := "godot2026-10-23T14.20.00.log"
const PICTURE_TIME := 1792765920 # Fri 23 Oct 2026 14:32 UTC
const BUILDS := 20

var _config: ReportConfig


func before_each() -> void:
	_config = ReportConfig.new()
	DirAccess.make_dir_recursive_absolute(ROOT)


func after_each() -> void:
	for f: String in DirAccess.get_files_at(ROOT):
		DirAccess.remove_absolute(ROOT.path_join(f))
	get_tree().paused = false


func after_all() -> void:
	DirAccess.remove_absolute(ROOT)


func test_the_machines_fields_as_the_pictures() -> void:
	assert_eq(ReportFacts.version_text("0.1 Dev 3", true, false), "0.1 Dev 3 (exported, release)")
	assert_eq(ReportFacts.version_text("0.1 Dev 3", true, true), "0.1 Dev 3 (exported, debug)")
	assert_eq(ReportFacts.version_text("0.1 Dev 1", false, true), "0.1 Dev 1 (source run)")
	assert_eq(ReportFacts.version_text("", false, true), "- (source run)")
	assert_eq(ReportFacts.godot_text({"major": 4, "minor": 7, "patch": 2, "status": "stable", "build": "official",
			"hash": "ed1daf0bf001b61586d9930840f2f1394092c079"}), "4.7.2.stable.official.ed1daf0bf")
	assert_eq(ReportFacts.godot_text({}), "")
	assert_eq(ReportFacts.system_text("Windows 11", "10.0.22631", 16, 32 * 1024 * 1024 * 1024),
			"Windows 11 (10.0.22631), 16 threads, 32 GB")
	assert_eq(ReportFacts.system_text("Ubuntu 24.04.5 LTS", "24.04", 4, 16872804352), "Ubuntu 24.04.5 LTS, 4 threads, 16 GB")
	assert_eq(ReportFacts.card_text("NVIDIA GeForce RTX 3070", PackedStringArray(["nvidia", "566.36"])),
			"NVIDIA GeForce RTX 3070 (driver 566.36)")
	assert_eq(ReportFacts.card_text("", PackedStringArray()), "", "headless names no card")
	assert_eq(ReportFacts.renderer_text("forward_plus", "vulkan", "high"), "Forward+ (Vulkan) · High")
	assert_eq(ReportFacts.renderer_text("gl_compatibility", "opengl3", ""), "Compatibility (OpenGL)")
	assert_eq(ReportFacts.window_text(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, Vector2i(2560, 1440), 144.0),
			"fullscreen 2560 × 1440 at 144 Hz")
	assert_eq(ReportFacts.window_text(DisplayServer.WINDOW_MODE_WINDOWED, Vector2i(1280, 720), -1.0), "windowed 1280 × 720")


func test_times_and_clocks() -> void:
	assert_eq(ReportFacts.utc_text(PICTURE_TIME), "Fri 23 Oct 2026 14:32 UTC")
	assert_eq(ReportFacts.clock_text(760.9), "12:40")
	assert_eq(ReportFacts.clock_text(5.0), "0:05")
	assert_eq(ReportFacts.clock_text(3723.0), "1:02:03")
	assert_eq(ReportFacts.closed_text(PICTURE_TIME, PICTURE_TIME - 760),
			"about Fri 23 Oct 2026 14:32 UTC (the log's last line), 12:40 after start")
	assert_eq(ReportFacts.closed_text(PICTURE_TIME, 0), "about Fri 23 Oct 2026 14:32 UTC (the log's last line)")
	assert_eq(ReportFacts.closed_text(0, PICTURE_TIME), "")


func test_the_match_and_round() -> void:
	var sizes: Array[int] = [3, 3]
	assert_eq(ReportFacts.match_text("depot", "elimination", false, sizes, "normal", ""),
			"Depot · Elimination · Standard rules · 3v3 · Normal")
	assert_eq(ReportFacts.match_text("neonHeights", "attack_defend", true, sizes, "hard", "easy"),
			"Neon Heights · Attack Defend · Custom rules · 3v3 · Hard, teammates Easy")
	assert_eq(ReportFacts.match_text("", "elimination", false, sizes, "normal", ""), "")
	assert_eq(ReportFacts.practice_text("range"), "Practice · Range")
	var rounds := RoundState.new()
	rounds.number = 4
	rounds.score = PackedInt32Array([2, 1])
	assert_eq(ReportFacts.round_text(rounds, 11523, 11523 / 60.0), "4 (live), score 2–1, tick 11523, 3:12 in")
	rounds.phase = RoundState.Phase.OVER
	assert_string_starts_with(ReportFacts.round_text(rounds, 1, 0.0), "4 (over), ")
	assert_eq(ReportFacts.started_round_text(4, [2, 1]), "4 had started, score 2–1")
	assert_eq(ReportFacts.started_round_text(0, []), "")


func test_the_player() -> void:
	var rifle := ReplicaConfig.new()
	rifle.display_name = "AEG Rifle"
	rifle.mag_size = 60
	rifle.mags = 5
	var loadout: Array[ReplicaConfig] = [rifle]
	var c := Character.new(0, 0, Vector3(12.4, 0.0, -8.1), 0.0, loadout)
	c.yaw = deg_to_rad(212.0)
	c.crouch_amount = 1.0
	c.armament.ammo[0].mag = 17
	c.armament.ammo[0].pouch[3] = 0
	assert_eq(ReportFacts.player_text(c, _config), "at (12.4, 0.0, -8.1) facing 212°, crouched, AEG Rifle 17/60, 3 spare")
	c.status = Character.Status.WALKING_OFF
	c.crouch_amount = 0.0
	c.yaw = deg_to_rad(-90.0)
	assert_string_contains(ReportFacts.player_text(c, _config), "facing 270°, walking off, standing, ")
	assert_eq(ReportFacts.player_text(null, _config), "")


func test_settings_changed_only_from_a_new_players() -> void:
	var fresh := Settings.new()
	var s := Settings.new()
	assert_eq(ReportFacts.settings_text(s.to_dict(), fresh.to_dict()), "none")
	s.fov = 100.0
	s.sensitivity = 2.1
	s.team_colours = TeamColours.Set.HIGH_CONTRAST
	assert_eq(ReportFacts.settings_text(s.to_dict(), fresh.to_dict()), "fov 100, sensitivity 2.1, team_colours high_contrast")
	s.bindings.rebind(&"reload", KEY_T)
	s.vsync = false
	s.volumes[&"Master"] = 0.5
	s.first_start_seen = true
	assert_eq(ReportFacts.settings_text(s.to_dict(), fresh.to_dict()),
			"fov 100, sensitivity 2.1, team_colours high_contrast, volumes.Master 0.5, vsync off, bindings 1 changed")


func test_dev_settings() -> void:
	var fresh := DevSettings.new().to_dict()
	var dev := DevSettings.new()
	assert_eq(ReportFacts.dev_text(false, dev.to_dict(), fresh), "off")
	assert_eq(ReportFacts.dev_text(true, dev.to_dict(), fresh), "on, nothing changed")
	dev.ghost = true
	dev.game_speed = 2.0
	assert_eq(ReportFacts.dev_text(true, dev.to_dict(), fresh), "on: game_speed 2, ghost on")
	assert_eq(ReportFacts.dev_text(false, dev.to_dict(), fresh), "off", "unticked, the switches don't apply")


func test_the_errors_a_log_names() -> void:
	var lines := PackedStringArray(["Godot Engine v4.7.2.stable.official", "ERROR: boom one",
			"   at: push_error (core/variant/variant_utility.cpp:1023)", "   GDScript backtrace (most recent call first):",
			"       [0] _init (res://probe.gd:5)", "[play] round 4 live"])
	for i in 3:
		lines.append_array(["SCRIPT ERROR: Invalid access to key \"name\"", "          at: _add_row (res://game/ui/hud_feed.gd:88)"])
	lines.append_array(["WARNING: careful", "     at: push_warning (core/variant/variant_utility.cpp:1033)",
			"ERROR: no place"])
	assert_eq(ReportFacts.errors_in_log(lines, _config.errors), PackedStringArray([
		"ERROR res://probe.gd:5 (_init): boom one",
		"SCRIPT ERROR res://game/ui/hud_feed.gd:88 (_add_row): Invalid access to key \"name\" ×3",
		"WARNING core/variant/variant_utility.cpp:1033 (push_warning): careful",
		"ERROR -: no place",
	]))
	assert_eq(ReportFacts.errors_in_log(lines, 1), PackedStringArray(["ERROR -: no place"]), "the newest")


func test_newest() -> void:
	var list := PackedStringArray(["a", "b", "c"])
	assert_eq(ReportFacts.newest(list, 2), PackedStringArray(["b", "c"]))
	assert_eq(ReportFacts.newest(list, 9), list)
	assert_eq(ReportFacts.newest(list, 0), PackedStringArray())


func test_a_crash_report_from_the_run_record_and_its_log() -> void:
	var f := FileAccess.open(ROOT.path_join(OLD_LOG), FileAccess.WRITE)
	for i in 50:
		f.store_line("[play] line %d" % i)
	f.store_line("SCRIPT ERROR: Invalid access to key \"name\"")
	f.store_line("          at: _add_row (res://game/ui/hud_feed.gd:88)")
	f.store_line("Airsoft crashed. Start it again: it offers to report the bug.")
	f.close()
	var tail := LogTail.new()
	tail.dir = ROOT
	var record := RunRecord.new()
	record.start("0.1 Dev 3", PICTURE_TIME - 760, 4242)
	record.play(48213, "depot", "elimination", {}, 0, "normal", "", [3, 3] as Array[int])
	record.round_started(4, PackedInt32Array([2, 1]))
	record.start("0.1 Dev 4", PICTURE_TIME + 60, 4343) # the next start keeps it as `previous`
	var info := ReportFacts.crash(record.previous, tail, Settings.new(), "it froze", _config, null)
	var text := BugReport.write(info)
	assert_string_starts_with(text, "Airsoft crash report\nNote: it froze\nVersion: 0.1 Dev 3 (")
	assert_string_contains(text, "\nSeed: 48213\nMatch: Depot · Elimination · Standard rules · 3v3 · Normal\n"
			+ "Round: 4 had started, score 2–1\nScreen: in play\n")
	assert_string_contains(text, "\nClosed: about ")
	assert_string_contains(text, "\nRecent errors (1):\n  SCRIPT ERROR res://game/ui/hud_feed.gd:88 (_add_row): Invalid")
	assert_string_contains(text, "\nLast log lines (last 40 of 53):\n  …\n")
	assert_true(text.ends_with("\n  Airsoft crashed. Start it again: it offers to report the bug."))
	assert_false(text.contains("\nPlayer:") or text.contains("\nFrames:") or text.contains("Recent events"))


func test_a_crash_in_the_menus_and_with_no_log() -> void:
	var record := RunRecord.new()
	record.start("0.1 Dev 3", PICTURE_TIME, 1)
	record.start("0.1 Dev 3", PICTURE_TIME + 5, 2)
	var tail := LogTail.new()
	tail.dir = ROOT
	var text := BugReport.write(ReportFacts.crash(record.previous, tail, null, "", _config, null))
	assert_string_contains(text, "\nClosed: -\nSeed: -\nMatch: -\nRound: -\nScreen: in the menus\n")
	assert_true(text.ends_with("\nRecent errors: none\nLast log lines: -"))


## A real match (a bot plays you): its events and frames reach the report, and building a whole report (facts, text and
## the issue's address) is timed for the record.
func test_a_live_report_from_a_match() -> void:
	var session := PlaySession.new()
	session.autopilot = true
	add_child_autofree(session)
	await wait_physics_frames(240)
	var errors := ErrorLog.new()
	var traces: Array[ScriptBacktrace] = []
	for i in _config.errors:
		errors._log_error("f", "res://game/x%d.gd" % i, i, "", "went wrong %d" % i, false, Logger.ERROR_TYPE_ERROR, traces)
	var settings := Settings.new()
	var scrub := ReportScrub.for_this_machine(_config)
	var info := ReportFacts.live(session, settings, errors, "in play", "a note", _config, scrub)
	var text := BugReport.write(info)
	assert_string_starts_with(text, "Airsoft bug report\nNote: a note\nVersion: %s (source run)\n" % Version.current())
	assert_string_contains(text, "\nSeed: %d\nMatch: Depot · Elimination · Standard rules · " % session.state.match_seed)
	assert_string_contains(text, "\nRound: 1 (live), score 0–0, tick ")
	assert_string_contains(text, "\nScreen: in play\nPlayer: at (")
	assert_string_contains(text, "\nDev settings: off\nSettings changed: none\n")
	assert_string_contains(text, "\nRecent errors (%d):\n  ERROR res://game/x0.gd:0 (f): went wrong 0\n" % _config.errors)
	assert_string_contains(text, "\nRecent events (")
	assert_string_contains(text, "ROUND_START 1")
	assert_false(text.contains("\nFrames: -"), "frames fed")
	# A full ring of events, then the cost of a whole report.
	var events := SimEvents.new()
	for i in _config.events:
		events.clear()
		var e := events.add(GameEvent.Kind.CHARACTER_HIT)
		e.actor = 1
		e.target = 4
		session.recent_events().record(10000 + i, events, PlaySession.PLAYER_ID)
	var t := Time.get_ticks_usec()
	var link: IssueLink = null
	for i in BUILDS:
		info = ReportFacts.live(session, settings, errors, "in play", "a note", _config, scrub)
		text = BugReport.write(info)
		link = IssueLink.make(info, _config)
	var each := float(Time.get_ticks_usec() - t) / BUILDS / 1000.0
	gut.p("A whole report (facts, text, address; %d lines, %d-character address): %.2f ms" % [
			text.count("\n") + 1, link.url.length(), each])
	assert_eq(info.events.size(), _config.events)
	assert_lte(link.url.length(), _config.max_url_chars)
	assert_lt(each, 100.0)
