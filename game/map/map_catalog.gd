class_name MapCatalog
extends RefCounted
## Which maps there are and which are listed (data/maps.md, the browser game's map/maps.ts MAPS): each map's name,
## kind (a match field or the practice range) and tag. A map tagged dev is listed only while the Dev settings' Dev
## content switch is on, and a match on one stays out of the records (docs/DECISIONS.md › Content tags and dev
## content). An unreadable row is left out with a warning; with no file at all, Depot alone is listed.

const PATH := "res://data/maps.md"
const FILE_NAME := "maps.md"
const TABLE := "Maps"
const KINDS: Array[StringName] = [&"field", &"range"]
const TAGS: Array[StringName] = [&"public", &"dev"]


class Entry:
	extends RefCounted
	var id: String = ""
	var display_name: String = ""
	var kind: StringName = &"field"
	var tag: StringName = &"public"
	var blurb: String = ""


## Every readable row, in the file's order.
var entries: Array[Entry] = []
## What couldn't be read, each "maps.md:line: …".
var problems: Array[String] = []

static var _shared: MapCatalog = null


## The catalogue as shipped, read once.
static func shared() -> MapCatalog:
	if _shared == null:
		_shared = read_file()
		for p in _shared.problems:
			push_warning("maps: %s" % p)
	return _shared


static func read_file(path: String = PATH) -> MapCatalog:
	if not FileAccess.file_exists(path):
		var built_in := MapCatalog.new()
		built_in.problems.append("%s can't be read: listing Depot only" % path)
		var depot := Entry.new()
		depot.id = "depot"
		depot.display_name = "Depot"
		built_in.entries.append(depot)
		return built_in
	return parse(FileAccess.get_file_as_string(path))


static func parse(text: String) -> MapCatalog:
	var m := MapCatalog.new()
	var tables := DataTable.read_all(text, FILE_NAME)
	var table := DataTable.find(tables, TABLE)
	if table == null:
		m.problems.append("%s: no \"%s\" table" % [FILE_NAME, TABLE])
		return m
	m.problems.append_array(table.problems)
	for row in table.rows:
		var e := Entry.new()
		e.id = row.key
		e.display_name = row.cell("Name")
		e.kind = StringName(row.cell("Kind"))
		e.tag = StringName(row.cell("Tag"))
		e.blurb = row.cell("Blurb")
		var at := "%s:%d" % [FILE_NAME, row.line]
		if e.id.is_empty() or e.display_name.is_empty():
			m.problems.append("%s: a map needs an Id and a Name" % at)
		elif not KINDS.has(e.kind):
			m.problems.append("%s: Kind \"%s\" is not field or range" % [at, e.kind])
		elif not TAGS.has(e.tag):
			m.problems.append("%s: Tag \"%s\" is not public or dev" % [at, e.tag])
		elif m.find(e.id) != null:
			m.problems.append("%s: %s is listed twice" % [at, e.id])
		else:
			m.entries.append(e)
	return m


## The entry for `map_id`, or null.
func find(map_id: String) -> Entry:
	for e in entries:
		if e.id == map_id:
			return e
	return null


## The match fields to offer: public ones, and dev ones too while `dev_content` is on.
func fields(dev_content: bool) -> Array[Entry]:
	var out: Array[Entry] = []
	for e in entries:
		if e.kind == &"field" and (dev_content or e.tag == &"public"):
			out.append(e)
	return out


## Whether a match on `map_id` uses dev content: tagged dev, or not in the catalogue at all.
func is_dev(map_id: String) -> bool:
	var e := find(map_id)
	return e == null or e.tag == &"dev"
