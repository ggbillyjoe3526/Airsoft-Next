extends GutTest
## QA's hunt on the bots' callouts (CO1): every kind of malformed row warns with its line and is left out, an empty or
## missing file leaves the director silent, the queue cap, bots that are not in play never call, and the ring and the
## director's stream stay apart from everything else.

const CalloutsTest := preload("res://tests/unit/test_callouts.gd")
const E := CalloutsFile.Event
const PEOPLE: Array[StringName] = [&"rusher", &"careful"]


## A file with every table, `row` appended to the table named by `table` (the line number it lands on is returned by
## `_line_of`).
static func _file_with(table: String, row: String) -> String:
	var text := CalloutsTest._text()
	var at := text.find("## %s" % table)
	var end := text.find("\n\n", at)
	if end < 0:
		end = text.length()
	return text.substr(0, end) + "\n" + row + text.substr(end)


static func _line_of(text: String, row: String) -> int:
	var lines := text.split("\n")
	for n in lines.size():
		if lines[n] == row:
			return n + 1
	return -1


static func _problems_naming(f: CalloutsFile, needle: String) -> Array[String]:
	var out: Array[String] = []
	for p in f.problems:
		if p.contains(needle):
			out.append(p)
	return out


func test_every_kind_of_bad_row_warns_with_its_line_and_is_left_out() -> void:
	var cases: Array[Array] = [
		["When they call", "| Contact | 0.5 | 3 |"],  # listed twice
		["When they call", "| Heard | abc | 3 |"],
		["When they call", "| Heard | 50% | 3 |"],
		["When they call", "| Heard | 0.5 | 999 |"],
		["When they call", "| Heard | 0.5 |"],  # a cell short
		["When they call", "| Nonsense | 0.5 | 3 |"],
		["Pace", "| Something else | 3 |"],
		["Pace", "| One bot's calls apart | 9 |"],  # twice
		["Pace", "| The team's calls apart | -2 |"],
		["Pace", "| A call waits at most | soon |"],
		["Personalities", "| Rusher | 2 |"],  # twice
		["Personalities", "| Sniper | 2 |"],
		["Personalities", "| Careful | 99 |"],
		["Personalities", "| Careful | lots |"],
		["Lines", "| Contact | Any |  |"],  # empty line
		["Lines", "| Nonsense | Any | Hello {area} |"],
		["Lines", "| Contact | Sniper | Contact {area} |"],
		["Lines", "| Contact | Any | Contact {nowhere} |"],
		["Lines", "| Contact | Any | Contact {area |"],
		["Lines", "| Reloading | Any | Reloading {area} |"],  # Reloading fills nothing
	]
	var people: Array[StringName] = [&"rusher", &"careful"]
	for c in cases:
		var text := _file_with(c[0], c[1])
		var f: CalloutsFile = CalloutsFile.parse(text, people)
		var line := _line_of(text, c[1])
		assert_gt(line, 0, "row found: %s" % c[1])
		var named := _problems_naming(f, "callouts.md:%d" % line)
		assert_gt(named.size(), 0, "%s warns with its line %d: %s" % [c[1], line, f.problems])


func test_a_bad_row_changes_nothing_else_in_the_file() -> void:
	var people: Array[StringName] = [&"rusher", &"careful"]
	var clean := CalloutsFile.parse(CalloutsTest._text(), people)
	assert_eq(clean.problems, [] as Array[String])
	var bad := CalloutsFile.parse(_file_with("Lines", "| Contact | Any | Contact {nowhere} |"), people)
	assert_eq(bad.lines[E.CONTACT].size(), clean.lines[E.CONTACT].size())
	var twice := CalloutsFile.parse(_file_with("When they call", "| Contact | 0.01 | 99 |"), people)
	assert_eq(twice.rules[E.CONTACT].chance, clean.rules[E.CONTACT].chance, "the first row stands")
	assert_eq(twice.rules[E.CONTACT].priority, clean.rules[E.CONTACT].priority)


func test_the_fills_come_out_right_at_a_sentence_start_and_inside_one() -> void:
	assert_eq(CalloutsFile.fill_line("{count} left, {area}.", "Dock", 5, 0), "Five left, Dock.")
	assert_eq(CalloutsFile.fill_line("Eyes up. {left} to go", "", 0, 11), "Eyes up. Eleven to go")
	assert_eq(CalloutsFile.fill_line("Still {left} left", "", 0, 12), "Still twelve left")
	assert_eq(CalloutsFile.fill_line("Still {left} left", "", 0, 13), "Still 13 left")
	assert_eq(CalloutsFile.number_word(0), "None")
	assert_eq(CalloutsFile.number_word(-1), "-1")


func test_an_empty_or_missing_file_keeps_the_game_running_and_the_bots_silent() -> void:
	var control: CalloutsTest.Rig = CalloutsTest.Rig.new(CalloutsFile.parse(CalloutsTest._text(), PEOPLE))
	control.sees(0, 2)
	assert_gt(control.run(3.0).size(), 0, "control: a good file says something")
	for text: String in ["", "   \n\n", "just some words\n| a | b |\n", "## Lines\n"]:
		var f := CalloutsFile.parse(text, PEOPLE)
		assert_gt(f.problems.size(), 0, "'%s' warns" % text.left(12))
		var rig: CalloutsTest.Rig = CalloutsTest.Rig.new(f)
		rig.sees(0, 2)
		var said: PackedStringArray = rig.tick()
		var hit: Array[Dictionary] = [rig.hit(3, 0)]
		said.append_array(rig.tick(hit))
		said.append_array(rig.run(5.0))
		assert_eq(said, PackedStringArray(), "an empty file says nothing")
	var none := CalloutsFile.read_file("res://data/not-there.md", PEOPLE)
	var rig2: CalloutsTest.Rig = CalloutsTest.Rig.new(none)
	rig2.sees(1, 3)
	assert_eq(rig2.run(3.0), PackedStringArray())


func test_an_event_ruled_but_with_no_lines_is_never_said() -> void:
	var people: Array[StringName] = [&"rusher", &"careful"]
	var text := CalloutsTest._text().replace("| Contact | Any | Contact, {area}! |\n", "")
	var f := CalloutsFile.parse(text, people)
	var rig: CalloutsTest.Rig = CalloutsTest.Rig.new(f)
	rig.sees(0, 2)
	assert_eq(rig.run(3.0), PackedStringArray())


func test_a_full_queue_drops_the_least_urgent_call_and_says_the_rest_in_order() -> void:
	# Pace: no bot gap, the team 1.5 s apart, a call waits up to 5 s.
	var people: Array[StringName] = [&"rusher", &"careful"]
	var f := CalloutsFile.parse(CalloutsTest._text({}, {}, [0, 1.5, 10, 5]), people)
	var rig: CalloutsTest.Rig = CalloutsTest.Rig.new(f)
	rig.bot(0).last_threat_at = rig.state.time
	rig.bot(1).last_threat_at = rig.state.time
	rig.sees(1, 3)
	var events: Array[Dictionary] = [
		rig.hit(2, 0), CalloutsTest._reload(0), CalloutsTest._reload(1),
	]
	var said: PackedStringArray = rig.tick(events)
	said.append_array(rig.run(6.0))
	# Last one, Contact (more urgent than the reloads, so it took a waiting reload's place), one Reloading; never four.
	assert_eq(said.size(), 3, str(said))
	assert_true(said[0].ends_with("Last one!"), str(said))
	assert_true(said[1].contains("Contact"), str(said))
	assert_true(said[2].contains("Reloading"), str(said))


func test_a_bot_that_is_not_in_play_never_calls_whatever_stage_of_leaving_it_is_at() -> void:
	var control: CalloutsTest.Rig = CalloutsTest.Rig.new(CalloutsFile.parse(CalloutsTest._text(), PEOPLE))
	control.sees(0, 2)
	assert_gt(control.run(3.0).size(), 0, "control: the same bot in play does call")
	for status: Character.Status in [Character.Status.CALLING, Character.Status.WALKING_OFF,
			Character.Status.LEAVING, Character.Status.OUT]:
		var rig: CalloutsTest.Rig = CalloutsTest.Rig.new(CalloutsFile.parse(CalloutsTest._text(), PEOPLE))
		rig.state.characters[0].status = status
		rig.state.characters[1].status = status
		rig.sees(0, 2)
		rig.bot(1).at_post = true
		var said: PackedStringArray = rig.run(3.0)
		assert_eq(said, PackedStringArray(), "status %d: a bot out of play says nothing" % status)


func test_a_hit_by_a_shooter_already_out_is_called_by_a_teammate_in_play_only() -> void:
	var rig: CalloutsTest.Rig = CalloutsTest.Rig.new(CalloutsFile.parse(CalloutsTest._text(), PEOPLE))
	rig.state.characters[0].status = Character.Status.WALKING_OFF
	var said: PackedStringArray = rig.tick([rig.hit(2, 0)])
	assert_eq(said.size(), 1, str(said))
	assert_true(said[0].begins_with("1: "), "bot 1 is the one in play: %s" % said)
	rig.state.characters[1].status = Character.Status.OUT
	var rig2: CalloutsTest.Rig = CalloutsTest.Rig.new(CalloutsFile.parse(CalloutsTest._text(), PEOPLE))
	rig2.state.characters[0].status = Character.Status.OUT
	rig2.state.characters[1].status = Character.Status.OUT
	assert_eq(rig2.tick([rig2.hit(2, 0)]), PackedStringArray(), "nobody in play to say it")


func test_the_log_is_a_fixed_ring_with_serials_that_only_grow() -> void:
	var ring := CalloutLog.new(16)
	var seen := {}
	var last := -1
	for n in 1000:
		ring.add(n % 4, n % 2, E.CONTACT, "call %d" % n, float(n))
		assert_eq(ring.total, n + 1)
		assert_gt(ring.total - 1, last, "serials only grow")
		last = ring.total - 1
		seen[ring.entry(n).get_instance_id()] = true
		assert_eq(ring.entry(n).line, "call %d" % n)
	assert_eq(seen.size(), 16, "16 entries, reused")
	assert_eq(ring.capacity(), 16)
	assert_null(ring.entry(1000), "not said yet")
	assert_null(ring.entry(1000 - 17), "overwritten")
	assert_not_null(ring.entry(1000 - 16))
	assert_eq(ring.oldest(), 984)
	assert_null(ring.entry(-1))
	assert_eq(CalloutLog.new(0).capacity(), 1, "a zero size still holds one")


func test_the_director_and_its_log_are_freed_when_the_match_lets_go() -> void:
	var rig: CalloutsTest.Rig = CalloutsTest.Rig.new(CalloutsFile.parse(CalloutsTest._text(), PEOPLE))
	rig.sees(0, 2)
	rig.run(1.0)
	var director: WeakRef = weakref(rig.director)
	var ring: WeakRef = weakref(rig.director.said)
	rig.director = null
	assert_null(director.get_ref(), "the director has no cycle keeping it")
	assert_null(ring.get_ref(), "nor its log")


func test_the_callout_stream_is_its_own_seed() -> void:
	for s: int in [0, 1, 2, 12345, 0x7fffffff, -1]:
		var c: int = Seeds.callout_seed(s)
		assert_ne(c, s & Seeds.MASK_32, "seed %d: not the match's own stream" % s)
		assert_ne(c, Seeds.roster_seed(s), "seed %d: not the roster's" % s)
		assert_eq(c, c & Seeds.MASK_32, "32 bits")
		assert_eq(c, Seeds.callout_seed(s), "deterministic")
