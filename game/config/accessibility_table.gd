class_name AccessibilityTable
extends RefCounted
## The team colour sets, Reduced motion's shares and the prop colour exceptions, read from data/accessibility.md (the
## browser game's teams.ts TEAM_COLOUR_SETS and accessibility.ts REDUCED_MOTION). Never throws: a cell it can't read
## keeps its built-in value (the file as shipped) and is listed in `problems`, each "accessibility.md:line: …".

const PATH := "res://data/accessibility.md"
const FILE_NAME := "accessibility.md"
const COLOURS_HEADING := "Team colours"
const MOTION_HEADING := "Reduced motion"
const EXCEPTIONS_HEADING := "Prop colour exceptions"
## The Set and Part cells' words, in TeamColours.Set and TeamColours.Part order.
const SET_NAMES: PackedStringArray = ["Standard", "High contrast"]
const PART_NAMES: PackedStringArray = ["figures", "hud"]
const SET_COLUMN := "Set"
const PART_COLUMN := "Part"
const ALPHA_COLUMN := "Alpha"
const BETA_COLUMN := "Beta"
const GLOW_COLUMN := "Paint glow (day)"
const ID_COLUMN := "ID"
const SHARE_COLUMN := "Share"
const PROP_COLUMN := "Prop"
const COLOUR_COLUMN := "Colour"
const REASON_COLUMN := "Reason"
## The Team colours table as shipped: Alpha then Beta for each set's figures then hud (Standard first), so a colour is
## at (set * PART_NAMES.size() + part) * 2 + team. (Flat: a typed constant of packed arrays crashes the 4.7 parser.)
const BUILT_IN_COLOURS: Array[Color] = [
	Color("3b87f5"), Color("fa8c29"), Color("3b87f5"), Color("fa8c29"),
	Color("8ccfff"), Color("b8460c"), Color("8ccfff"), Color("e0601a"),
]
## Each set's paint glow on day fields, as shipped.
const BUILT_IN_GLOW: Array[float] = [0.0, 0.3]
## Reduced motion's IDs, in the file's order, and their shares as shipped.
const MOTION_IDS: Array[StringName] = [&"sway", &"kick", &"lean_roll", &"vault_tip", &"reload_cant", &"dust",
		&"hud_pulse", &"hit_jolt"]
const BUILT_IN_MOTION: Array[float] = [0.0, 0.5, 0.25, 0.25, 0.5, 0.0, 0.0, 0.5]

## Every set's colours, laid out as BUILT_IN_COLOURS.
var colours: Array[Color] = BUILT_IN_COLOURS.duplicate()
## Each set's paint glow on day fields, by TeamColours.Set.
var glow: Array[float] = BUILT_IN_GLOW.duplicate()
## Reduced motion's share of each movement, by MOTION_IDS.
var motion: Dictionary[StringName, float] = {}
## The props allowed near a team's hue: MapStyle's name ("crate", "container 2") to the colour written down.
var exceptions: Dictionary[String, Color] = {}
var problems: Array[String] = []

static var _shared: AccessibilityTable = null


## The table as shipped, read once; its problems go to the log.
static func shared() -> AccessibilityTable:
	if _shared == null:
		_shared = read_file()
		for p in _shared.problems:
			push_warning("accessibility: %s" % p)
	return _shared


static func read_file(path: String = PATH) -> AccessibilityTable:
	if not FileAccess.file_exists(path):
		var none := parse("")
		none.problems.push_front("%s can't be read: using the built-in colours and shares" % path)
		return none
	return parse(FileAccess.get_file_as_string(path))


static func parse(text: String) -> AccessibilityTable:
	var t := AccessibilityTable.new()
	for i in MOTION_IDS.size():
		t.motion[MOTION_IDS[i]] = BUILT_IN_MOTION[i]
	if text == "":
		return t
	var tables := DataTable.read_all(text, FILE_NAME)
	t._read_colours(DataTable.find(tables, COLOURS_HEADING))
	t._read_motion(DataTable.find(tables, MOTION_HEADING))
	t._read_exceptions(DataTable.find(tables, EXCEPTIONS_HEADING))
	for table in tables:
		t.problems.append_array(table.problems)
	return t


## Alpha's and Beta's colour for `colour_set`'s `part` (TeamColours.Set, TeamColours.Part), a new array.
func pair(colour_set: int, part: int) -> PackedColorArray:
	var at := _index(colour_set, part)
	return PackedColorArray([colours[at], colours[at + 1]])


## Reduced motion's share of `id` (MOTION_IDS), or 1 (unchanged) for an ID it doesn't know.
func share(id: StringName) -> float:
	return motion.get(id, 1.0)


static func _index(colour_set: int, part: int) -> int:
	return (colour_set * PART_NAMES.size() + part) * 2


## A "#rrggbb" cell's colour, or null.
static func _colour(cell: String) -> Variant:
	var text := cell.strip_edges()
	if text.length() != 7 or not text.begins_with("#") or not Color.html_is_valid(text):
		return null
	return Color.html(text)


## A share cell (0–1, or 0–100 %) as 0–1, or NAN if it isn't one.
static func _share(cell: String) -> float:
	var n := DataTable.parse_number(cell)
	if cell.strip_edges().ends_with("%"):
		n /= 100.0
	return n if not is_nan(n) and n >= 0.0 and n <= 1.0 else NAN


func _missing(table_name: String, what: String) -> void:
	problems.append("%s: no %s table: using the built-in %s" % [FILE_NAME, table_name, what])


func _read_colours(table: DataTable) -> void:
	if table == null:
		_missing(COLOURS_HEADING, "colours")
		return
	var seen: Dictionary[int, bool] = {}
	for r in table.rows:
		var s := SET_NAMES.find(r.cell(SET_COLUMN))
		var p := PART_NAMES.find(r.cell(PART_COLUMN))
		if s < 0 or p < 0:
			table.problem(r.line, "\"%s\" \"%s\" is not a set and part (%s; %s): row skipped" % [r.cell(SET_COLUMN),
					r.cell(PART_COLUMN), ", ".join(SET_NAMES), ", ".join(PART_NAMES)])
			continue
		var at := _index(s, p)
		if seen.has(at):
			table.problem(r.line, "%s %s appears twice: this row is skipped" % [SET_NAMES[s], PART_NAMES[p]])
			continue
		seen[at] = true
		for team in 2:
			var header := ALPHA_COLUMN if team == 0 else BETA_COLUMN
			var c: Variant = _colour(r.cell(header))
			if c == null:
				table.problem(r.line, "%s \"%s\" is not a #rrggbb colour: keeping %s" % [header, r.cell(header),
						"#" + colours[at + team].to_html(false)])
			else:
				colours[at + team] = c
		if p != TeamColours.Part.FIGURES:
			continue
		var g := _share(r.cell(GLOW_COLUMN))
		if is_nan(g):
			table.problem(r.line, "%s \"%s\" is not 0–1: keeping %s" % [GLOW_COLUMN, r.cell(GLOW_COLUMN), glow[s]])
		else:
			glow[s] = g
	for s in SET_NAMES.size():
		for p in PART_NAMES.size():
			if not seen.has(_index(s, p)):
				table.problem(table.line, "no %s %s row: using the built-in colours" % [SET_NAMES[s], PART_NAMES[p]])


func _read_motion(table: DataTable) -> void:
	if table == null:
		_missing(MOTION_HEADING, "shares")
		return
	var seen: Dictionary[StringName, bool] = {}
	for r in table.rows:
		var id := StringName(r.key)
		if not MOTION_IDS.has(id):
			table.problem(r.line, "\"%s\" is not a movement the game knows: row skipped" % r.key)
			continue
		if seen.has(id):
			table.problem(r.line, "%s appears twice: this row is skipped" % r.key)
			continue
		seen[id] = true
		var n := _share(r.cell(SHARE_COLUMN))
		if is_nan(n):
			table.problem(r.line, "%s \"%s\" is not 0–1: keeping %s" % [SHARE_COLUMN, r.cell(SHARE_COLUMN), motion[id]])
		else:
			motion[id] = n
	for id in MOTION_IDS:
		if not seen.has(id):
			table.problem(table.line, "no %s row: keeping %s" % [id, motion[id]])


func _read_exceptions(table: DataTable) -> void:
	if table == null:
		return
	for r in table.rows:
		var c: Variant = _colour(r.cell(COLOUR_COLUMN))
		if r.key == "" or c == null or r.cell(REASON_COLUMN) == "":
			table.problem(r.line, "an exception needs a prop, a #rrggbb colour and a reason: row skipped")
			continue
		if exceptions.has(r.key):
			table.problem(r.line, "%s appears twice: this row is skipped" % r.key)
			continue
		exceptions[r.key] = c
