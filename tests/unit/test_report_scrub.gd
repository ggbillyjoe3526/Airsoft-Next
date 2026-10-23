extends GutTest
## ReportScrub (SV4): no folder path, account name, machine name or address reaches a report; with injected names,
## Windows and Linux paths, either slash and any case, and inside log lines.

const WIN_SAVE := "C:/Users/Jo Bloggs/AppData/Roaming/Airsoft"
const WIN_HOME := "C:\\Users\\Jo Bloggs"
const LINUX_SAVE := "/home/zandra/.local/share/Airsoft"
const LINUX_HOME := "/home/zandra"


func _windows() -> ReportScrub:
	return ReportScrub.new(WIN_SAVE, WIN_HOME, "Jo Bloggs", "DESKTOP-7QK2ZX")


func _linux() -> ReportScrub:
	return ReportScrub.new(LINUX_SAVE, LINUX_HOME, "zandra", "zandra-laptop")


func test_windows_save_folder_either_slash_and_case() -> void:
	var s := _windows()
	assert_eq(s.line("Saved to C:/Users/Jo Bloggs/AppData/Roaming/Airsoft/settings.save"),
			"Saved to <save folder>/settings.save")
	assert_eq(s.line("c:\\users\\JO BLOGGS\\appdata\\roaming\\airsoft\\logs\\godot.log"),
			"<save folder>\\logs\\godot.log")
	assert_eq(s.line("at C:\\Users\\Jo Bloggs\\AppData/Roaming\\Airsoft"), "at <save folder>")


func test_windows_home_and_the_account_name() -> void:
	var s := _windows()
	assert_eq(s.line("Loaded C:\\Users\\Jo Bloggs\\Documents\\x.txt"), "Loaded ~\\Documents\\x.txt")
	assert_eq(s.line("Hi, I'm jo bloggs from the club"), "Hi, I'm <you> from the club")


func test_linux_paths_and_the_account_name() -> void:
	var s := _linux()
	assert_eq(s.line("ERROR: Cannot open /home/zandra/.local/share/Airsoft/run.save."),
			"ERROR: Cannot open <save folder>/run.save.")
	assert_eq(s.line("   at: _load (/home/zandra/airsoft/game/x.gd:12)"), "   at: _load (~/airsoft/game/x.gd:12)")
	assert_eq(s.line("user Zandra played"), "user <you> played")


func test_the_account_name_is_a_whole_word() -> void:
	var s := _linux()
	assert_eq(s.line("zandras and alexzandra stay"), "zandras and alexzandra stay")


func test_a_home_that_only_starts_like_another_stays() -> void:
	var s := ReportScrub.new("", "/home/jo", "jo", "")
	assert_eq(s.line("/home/joanna/x"), "/home/<you>/x", "another account's folder still goes")
	assert_eq(s.line("/home/jo/x"), "~/x")


func test_a_short_account_name_goes_only_in_paths() -> void:
	var s := ReportScrub.new("", "/home/al", "al", "")
	assert_eq(s.line("Al shot al at /home/al/x"), "Al shot al at ~/x")


func test_another_users_folder_loses_its_name() -> void:
	var s := _windows()
	assert_eq(s.line("D:\\Users\\Someone Else\\Games\\Airsoft.exe"), "D:\\Users\\<you>\\Games\\Airsoft.exe")
	assert_eq(s.line("/Users/mac.person/Library/Application Support/Airsoft"),
			"/Users/<you>/Library/Application Support/Airsoft")


func test_the_machine_name() -> void:
	assert_eq(_windows().line("Connected from desktop-7qk2zx today"), "Connected from <machine> today")
	assert_eq(_linux().line("zandra-laptop kernel: oops"), "<machine> kernel: oops")


func test_addresses() -> void:
	var s := _linux()
	assert_eq(s.line("peer 192.168.1.20:7000 and 10.0.0.1"), "peer <address>:7000 and <address>")
	assert_eq(s.line("mail me@example.co.uk now"), "mail <address> now")
	assert_eq(s.line("nic 3c:22:fb:01:aa:9e"), "nic <address>")
	assert_eq(s.line("v6 2001:0db8:85a3:0000:0000:8a2e:0370:7334 end"), "v6 <address> end")


func test_versions_ticks_and_clocks_stay() -> void:
	var s := _windows()
	for kept: String in ["Godot: 4.7.2.stable.official.ed1daf0bf", "System: Windows 11 (10.0.22631), 16 threads",
			"Graphics card: NVIDIA GeForce RTX 3070 (driver 32.0.15.6636)", "Round: 4 (live), tick 11523, 3:12 in",
			"Time: Fri 23 Oct 2026 14:32 UTC, 12:40 after start", "  [1] RendererSceneRenderRD::_render_scene",
			"SCRIPT ERROR res://game/ui/hud_feed.gd:88 (_add_row): Invalid access to key \"name\""]:
		assert_eq(s.line(kept), kept)


func test_names_with_pattern_characters_and_accents() -> void:
	var s := ReportScrub.new("", "/home/j.o+", "Jöe (x)", "")
	assert_eq(s.line("/home/j.o+/a and /home/jxo+/b"), "~/a and /home/<you>/b")
	assert_eq(s.line("JÖE (X) said"), "<you> said")


func test_inside_a_whole_report() -> void:
	var info := BugReport.ReportInfo.new()
	info.crash = true
	info.note = "my name is zandra, the save is in /home/zandra/.local/share/Airsoft"
	info.errors = PackedStringArray(["ERROR /home/zandra/airsoft/game/a.gd:3 (f): zandra-laptop said no"])
	info.log_lines = PackedStringArray(["Loading /home/zandra/.local/share/Airsoft/settings.save",
			"OpenGL from 192.168.0.4 for Zandra"])
	info.log_count = 2
	info.scrub = _linux()
	var text := BugReport.write(info)
	for gone: String in ["zandra", "Zandra", "/home", "192.168"]:
		assert_false(text.contains(gone), "%s in:\n%s" % [gone, text])
	assert_true(text.contains("Note: my name is <you>, the save is in <save folder>"), text)
	assert_true(text.contains("  Loading <save folder>/settings.save"))
	assert_true(text.contains("  ERROR ~/airsoft/game/a.gd:3 (f): <machine> said no"))


func test_this_machine_takes_out_its_own() -> void:
	var s := ReportScrub.for_this_machine()
	assert_eq(s.line(OS.get_user_data_dir() + "/logs"), "<save folder>/logs")
	var home := OS.get_environment("HOME")
	if home != "":
		assert_eq(s.line(home + "/elsewhere"), "~/elsewhere")


## QA attempt 1: an IPv4 address ending a sentence came through.
func test_an_ipv4_address_ending_a_sentence() -> void:
	var s := ReportScrub.new()
	assert_eq(s.line("My IP is 192.168.1.5."), "My IP is <address>.")
	assert_eq(s.line("server 10.0.0.1. then"), "server <address>. then")
	assert_eq(s.line("ip:8.8.8.8."), "ip:<address>.")
	assert_eq(s.line("version 1.2.3.4.5 stays"), "version 1.2.3.4.5 stays", "five numbers are no address")


## QA attempt 1: compressed IPv6 came through; every form goes whole.
func test_every_ipv6_form_goes_whole() -> void:
	var s := ReportScrub.new()
	assert_eq(s.line("my ip is 2001:db8::8a2e:370:7334"), "my ip is <address>")
	assert_eq(s.line("fe80::1ff:fe23:4567:890a"), "<address>")
	assert_eq(s.line("[2001:db8::1]:443"), "[<address>]:443")
	assert_eq(s.line("peer ::ffff:c0a8:105"), "peer <address>")
	assert_eq(s.line("peer ::ffff:1.2.3.4."), "peer <address>.")
	assert_eq(s.line("loopback ::1 and fe80::"), "loopback <address> and <address>")


func test_clocks_and_cpp_names_stay() -> void:
	var s := ReportScrub.new()
	for kept: String in ["at 12:40:05 then", "00:01:02.5", "Round: 4, 3:12 in", "Face::bad and Node3D::_ready",
			"[1] RendererSceneRenderRD::_render_scene", "t11402 Beta 2 SHOT ×4"]:
		assert_eq(s.line(kept), kept)


func test_a_onedrive_for_business_folder_hides_the_employer() -> void:
	var s := _windows()
	assert_eq(s.line("C:\\Users\\Jo Bloggs\\OneDrive - Contoso Ltd\\Documents\\a.txt"),
			"~\\OneDrive - <organisation>\\Documents\\a.txt")
	assert_eq(s.line("D:/OneDrive - Fabrikam, Inc/x"), "D:/OneDrive - <organisation>/x")


func test_a_full_machine_name_and_its_short_form() -> void:
	var s := ReportScrub.new("", "", "", "box42.corp.example.com")
	assert_eq(s.line("box42.corp.example.com said hello to box42"), "<machine> said hello to <machine>")


func test_an_email_with_the_account_name_goes_whole() -> void:
	var s := ReportScrub.new("", "", "zandra", "")
	assert_eq(s.line("write to zandra@mail.example.org"), "write to <address>")


func test_paths_keep_what_follows_them() -> void:
	var s := ReportScrub.new("", "C:\\Users\\Bob", "bob", "")
	assert_eq(s.line("[C:\\Users\\Bob]"), "[~]")
	var t := ReportScrub.new("", "/home/bob", "bob", "")
	assert_eq(t.line("at /home/bob."), "at ~.")
	assert_eq(t.line("/var/home/bob/x"), "/var/home/<you>/x", "not the tail of a longer path")
	var u := ReportScrub.new()
	assert_eq(u.line("[C:\\Users\\Bob]"), "[C:\\Users\\<you>]")
	assert_eq(u.line("in /home/ann. Then"), "in /home/<you>. Then")
