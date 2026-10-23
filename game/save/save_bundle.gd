class_name SaveBundle
extends RefCounted
## The player's save as one (the browser game's save bundle): the four stores, settings (with the key bindings), saved
## loadouts, progress and records, each as SaveFile read it with its own kind and version, keyed by kind. Not in it:
## the machine's own files (MACHINE_KINDS: the safe start's record, the run record, the restore points and the Undo
## slot) and renderer.cfg. A store added later joins KINDS and PATHS here, the one list (a test checks every kind under
## game/ is in one list or the other). Shape: {saved_at, version, stores: {kind: {version, data}}}; a missing store is
## absent, a damaged one absent and named in `damaged`. Pure over its paths: SaveKeeper keeps restore points and Undo.

## The stores, in the same order in each list.
const KINDS: Array[String] = [Settings.KIND, SavedLoadouts.KIND, Progress.KIND, Records.KIND]
const PATHS: Array[String] = [Settings.PATH, SavedLoadouts.PATH, Progress.PATH, Records.PATH]
## The newest version of each store this build reads.
const VERSIONS: Array[int] = [Settings.VERSION, SavedLoadouts.VERSION, Progress.VERSION, Records.VERSION]
## SaveFile kinds that belong to this machine, never to the save.
const MACHINE_KINDS: Array[String] = ["graphics_guard", "run", "restore_points", "undo"]


## What the Save file tab shows of a save (concept settings-save-file.png and the restore confirm).
class Summary:
	extends RefCounted
	var saved_at: int = 0
	var version: String = ""
	var level: int = 0
	var xp: int = 0
	var unlocked: int = 0
	var matches: int = 0
	var loadouts: int = 0


## When the save was last written: the newest of its files (Unix seconds), 0 for an empty save.
var saved_at: int = 0
## The build that read it (Version.current()).
var version: String = ""
## kind -> {version: int, data: Dictionary}, for each store that was there and good.
var stores: Dictionary[String, Dictionary] = {}
## Kinds whose every copy was damaged.
var damaged: PackedStringArray = PackedStringArray()


## The save at `paths` (one per KINDS entry; the real files by default) as it is now.
static func read(paths: Array[String] = PATHS) -> SaveBundle:
	var b := SaveBundle.new()
	b.version = Version.current()
	for i in KINDS.size():
		var r := SaveFile.read(paths[i], KINDS[i])
		if r.ok:
			b.stores[KINDS[i]] = {"version": int(r.version), "data": r.data}
			b.saved_at = maxi(b.saved_at, _modified(paths[i]))
		elif r.found:
			b.damaged.append(KINDS[i])
	return b


## A bundle from `to_dict`'s shape; what doesn't fit (an unknown kind, a store without a whole version or with data
## that isn't an object) is left out.
static func from_dict(data: Dictionary) -> SaveBundle:
	var b := SaveBundle.new()
	b.saved_at = whole(data.get("saved_at"))
	b.version = str(data.get("version", ""))
	var raw: Variant = data.get("stores", {})
	if not raw is Dictionary:
		return b
	var in_stores: Dictionary = raw
	for kind: String in KINDS:
		var entry: Variant = in_stores.get(kind)
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry
		var v := whole(e.get("version"))
		if v < 1 or not e.get("data") is Dictionary:
			continue
		b.stores[kind] = {"version": v, "data": e["data"]}
	return b


func to_dict() -> Dictionary:
	return {"saved_at": saved_at, "version": version, "stores": stores.duplicate(true)}


## No store at all: a new player's save, or a deleted one.
func is_empty() -> bool:
	return stores.is_empty()


## Whether `other` holds the same stores, versions and data (when and by which build aside).
func same_as(other: SaveBundle) -> bool:
	return SaveFile.payload(stores) == SaveFile.payload(other.stores)


## Why this save can't be restored by this build, naming the version, or "": a store written in a version above this
## build's, or a bundle taken by a newer build.
func refusal() -> String:
	for i in KINDS.size():
		if stores.has(KINDS[i]) and int(stores[KINDS[i]]["version"]) > VERSIONS[i]:
			return "%s is version %d, newer than this build reads (%d)" % [KINDS[i], int(stores[KINDS[i]]["version"]),
					VERSIONS[i]]
	if Version.newer(version, Version.current()):
		return "taken by %s, newer than this build (%s)" % [version, Version.current()]
	return ""


## Writes every store to `paths` with its own version and data, and removes every copy of a store this save hasn't.
## Stops at the first store that won't write or go; returns false then (SaveKeeper puts the save back).
func write(paths: Array[String] = PATHS) -> bool:
	for i in KINDS.size():
		var ok := false
		if stores.has(KINDS[i]):
			var s: Dictionary = stores[KINDS[i]]
			ok = SaveFile.write(paths[i], KINDS[i], int(s["version"]), s["data"])
		else:
			ok = SaveFile.remove(paths[i])
		if not ok:
			push_warning("save bundle: %s couldn't be written at %s" % [KINDS[i], paths[i]])
			return false
	return true


## The tab's figures, read through fresh store instances (never the shared ones the running game holds). A store this
## build can't read (absent, or a newer version) counts as a new player's.
func summary() -> Summary:
	var out := Summary.new()
	out.saved_at = saved_at
	out.version = version
	var progress := Progress.new(LevelTable.shared())
	progress.from_dict(_readable(Progress.KIND))
	progress.grant_reached() # as the game reads it: what levels.md now gives up to its level
	out.level = progress.level()
	out.xp = progress.xp
	out.unlocked = progress.unlocked.size()
	var records := Records.new()
	records.from_dict(_readable(Records.KIND))
	for key: String in records.results:
		var wl: PackedInt32Array = records.results[key]
		out.matches += wl[0] + wl[1]
	var loadouts := SavedLoadouts.new(LoadoutRules.standard())
	loadouts.from_dict(_readable(SavedLoadouts.KIND))
	out.loadouts = loadouts.slots.size()
	return out


## The store's data when this build reads its version, else empty.
func _readable(kind: String) -> Dictionary:
	if not stores.has(kind) or int(stores[kind]["version"]) > VERSIONS[KINDS.find(kind)]:
		return {}
	return stores[kind]["data"]


static func _modified(path: String) -> int:
	var newest := 0
	for suffix: String in SaveFile.SUFFIXES:
		if FileAccess.file_exists(path + suffix):
			newest = maxi(newest, FileAccess.get_modified_time(path + suffix))
	return newest


## A whole number from JSON (a float), or 0.
static func whole(value: Variant) -> int:
	if value is int:
		return value
	if value is float and is_finite(value) and value == floorf(value):
		return int(value)
	return 0
