class_name Pool
extends RefCounted
## The game's items (data/pool.md, the browser game's pool/poolFile.ts): each replica and power source with its ID,
## name, Key, Tags, Type, Fits and Access. What goes with what is by tags (pool.md › Tags and Fits): a part fits a
## replica that has any one of the tags in its Fits, or whose ID it names. An unreadable row is left out with a
## warning; a blank Access reads as public and any other word leaves the row out. Plain data, no engine state.

const PATH := "res://data/pool.md"
const FILE_NAME := "pool.md"
const REPLICAS_TABLE := "Replicas"
const POWER_TABLE := "Power sources"
const ACCESS: Array[StringName] = [&"public", &"dev"]
const POWER_TYPES: Array[StringName] = [&"battery", &"gas", &"spring"]
## A replica tag that means its power source is built in: nothing fits its power slot and it needs nothing.
const BUILT_IN_POWER := "built-in-power"
## Six digits, as pool.md › Identifiers has them.
const ID_LENGTH := 6

enum Kind { REPLICA, POWER }


class Item:
	extends RefCounted
	var id: String = ""
	var kind: Kind = Kind.REPLICA
	var display_name: String = ""
	## A replica's Key (stats.md's row and the built-in config); "" for a power source.
	var key: StringName = &""
	var tags: PackedStringArray = PackedStringArray()
	## A power source's Type and what it fits (tags, or replica IDs).
	var type: StringName = &""
	var fits: PackedStringArray = PackedStringArray()
	var access: StringName = &"public"

	func is_dev() -> bool:
		return access == &"dev"

	func has_built_in_power() -> bool:
		return tags.has(BUILT_IN_POWER)


## Every readable row of each table, in the file's order.
var replicas: Array[Item] = []
var powers: Array[Item] = []
## What couldn't be read, each "pool.md:line: …".
var problems: Array[String] = []

static var _shared: Pool = null


## The pool as shipped, read once.
static func shared() -> Pool:
	if _shared == null:
		_shared = read_file()
		for p in _shared.problems:
			push_warning("pool: %s" % p)
	return _shared


static func read_file(path: String = PATH) -> Pool:
	if not FileAccess.file_exists(path):
		var none := Pool.new()
		none.problems.append("%s can't be read: no items" % path)
		return none
	return parse(FileAccess.get_file_as_string(path))


static func parse(text: String) -> Pool:
	var p := Pool.new()
	var tables := DataTable.read_all(text, FILE_NAME)
	p._read(DataTable.find(tables, REPLICAS_TABLE), Kind.REPLICA, p.replicas)
	p._read(DataTable.find(tables, POWER_TABLE), Kind.POWER, p.powers)
	return p


## The item with `id`, or null.
func item(id: String) -> Item:
	for list: Array[Item] in [replicas, powers]:
		for it in list:
			if it.id == id:
				return it
	return null


## The replica whose Key is `key`, or null.
func replica_by_key(key: StringName) -> Item:
	for it in replicas:
		if it.key == key:
			return it
	return null


## True if `part` goes on `replica`: one of its Fits is a tag of the replica, or the replica's ID. Nothing fits the
## power slot of a replica with its power built in.
func fits(part: Item, replica: Item) -> bool:
	if part.kind == Kind.POWER and replica.has_built_in_power():
		return false
	for f in part.fits:
		if f == replica.id or replica.tags.has(f):
			return true
	return false


## The power sources that fit `replica`, in the file's order (dev ones only while `dev_content`).
func powers_for(replica: Item, dev_content: bool) -> Array[Item]:
	var out: Array[Item] = []
	for pw in powers:
		if (dev_content or not pw.is_dev()) and fits(pw, replica):
			out.append(pw)
	return out


func _read(t: DataTable, kind: Kind, into: Array[Item]) -> void:
	var table_name := REPLICAS_TABLE if kind == Kind.REPLICA else POWER_TABLE
	if t == null:
		problems.append("%s: no \"%s\" table" % [FILE_NAME, table_name])
		return
	problems.append_array(t.problems)
	for row in t.rows:
		var where := t.where(row.line)
		var it := Item.new()
		it.kind = kind
		it.id = row.cell("ID")
		it.display_name = row.cell("Name")
		var access := row.cell("Access").to_lower()
		it.access = &"public" if access == "" else StringName(access)
		if it.id.length() != ID_LENGTH or not it.id.is_valid_int():
			problems.append("%s: ID must be %d digits, not \"%s\"" % [where, ID_LENGTH, it.id])
			continue
		if item(it.id) != null:
			problems.append("%s: ID %s is listed twice" % [where, it.id])
			continue
		if it.display_name == "":
			problems.append("%s: %s has no Name" % [where, it.id])
			continue
		if not ACCESS.has(it.access):
			problems.append("%s: Access must be public or dev, not \"%s\": left out" % [where, access])
			continue
		if kind == Kind.REPLICA:
			it.key = StringName(row.cell("Key"))
			it.tags = _words(row.cell("Tags"))
			if it.key == &"":
				problems.append("%s: %s has no Key" % [where, it.id])
				continue
		else:
			it.type = StringName(row.cell("Type").to_lower())
			it.fits = _words(row.cell("Fits"))
			if not POWER_TYPES.has(it.type):
				problems.append("%s: Type must be battery, gas or spring, not \"%s\"" % [where, it.type])
				continue
		into.append(it)


## "pistol, gas, pistol-mag" as its words.
static func _words(cell: String) -> PackedStringArray:
	var out := PackedStringArray()
	for w in cell.split(","):
		var t := w.strip_edges().to_lower()
		if t != "":
			out.append(t)
	return out
