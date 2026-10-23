extends GutTest
## SaveKeeper (SV1): restore points (one a day, only a changed save, three, newest first, none for an empty save), and
## replace for a restore, Undo and delete: byte for byte, the Undo slot first, every store put back when one won't
## write, the stores held after, a newer save refused. Each test gets its own empty folder and clock; the player's
## own save is never read.

const ROOT := "user://test-save-keeper"
## 2026-10-20 12:00 UTC, and a day.
const DAY_ONE := 1792497600
const DAY := 86400

var dir := ""
var now: int = DAY_ONE
var keeper: SaveKeeper = null
var _n := 0


func before_each() -> void:
	_n += 1
	dir = "%s/%d" % [ROOT, _n]
	_wipe(dir)
	DirAccess.make_dir_recursive_absolute(dir)
	now = DAY_ONE
	keeper = SaveKeeper.new()
	keeper.store_paths = _paths()
	keeper.points_path = dir.path_join("restore_points.save")
	keeper.undo_path = dir.path_join("undo.save")
	keeper.clock = func() -> float: return float(now)
	keeper.utc_offset_minutes = 0


func after_each() -> void:
	SaveFile.release(PackedStringArray(_paths()))


func after_all() -> void:
	_wipe(ROOT)


func _wipe(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for d: String in DirAccess.get_directories_at(path):
		_wipe(path.path_join(d))
	for f: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)


func _paths() -> Array[String]:
	var out: Array[String] = []
	for path: String in SaveBundle.PATHS:
		out.append(dir.path_join(path.get_file()))
	return out


## A save marked `n`: each store with whole numbers, fractions and a whole float (written as an integer).
func _write_save(n: int) -> void:
	var p := keeper.store_paths
	for i in p.size():
		assert_true(SaveFile.write(p[i], SaveBundle.KINDS[i], 1, {"n": n, "f": 0.25 * n, "w": 1.0, "list": [n, "x"]}))


## Every file in the folder (not the folders) and its bytes.
func _files() -> Dictionary[String, PackedByteArray]:
	var out: Dictionary[String, PackedByteArray] = {}
	for f: String in DirAccess.get_files_at(dir):
		out[f] = FileAccess.get_file_as_bytes(dir.path_join(f))
	return out


## The four stores' main files' text.
func _mains() -> PackedStringArray:
	var out := PackedStringArray()
	for path: String in _paths():
		out.append(SaveFile.read_text(path))
	return out


# ---------------------------------------------------------------- restore points
func test_the_first_start_keeps_a_point() -> void:
	_write_save(1)
	assert_true(keeper.keep_today())
	var points := keeper.restore_points()
	assert_eq(points.size(), 1)
	assert_eq(points[0].day, "2026-10-20")
	assert_eq(points[0].taken_at, DAY_ONE)
	assert_true(points[0].save.same_as(SaveBundle.read(_paths())))


func test_a_days_second_start_keeps_no_new_point() -> void:
	_write_save(1)
	keeper.keep_today()
	_write_save(2)
	now += 3600
	assert_false(keeper.keep_today())
	var points := keeper.restore_points()
	assert_eq(points.size(), 1)
	assert_eq(int(points[0].save.stores["records"]["data"]["n"]), 1, "the day's first save kept")


func test_a_fourth_day_drops_the_oldest() -> void:
	for day in 4:
		_write_save(day + 1)
		now = DAY_ONE + day * DAY
		assert_true(keeper.keep_today(), "day %d" % (day + 1))
	var points := keeper.restore_points()
	assert_eq(points.size(), SaveKeeper.RESTORE_POINTS)
	var marks: Array[int] = []
	for p: SaveKeeper.Point in points:
		marks.append(int(p.save.stores["settings"]["data"]["n"]))
	assert_eq(marks, [4, 3, 2], "newest first, the oldest gone")
	assert_eq(points[0].day, "2026-10-23")


func test_an_unchanged_save_keeps_none() -> void:
	_write_save(1)
	keeper.keep_today()
	now += DAY
	_write_save(1)
	assert_false(keeper.keep_today())
	assert_eq(keeper.restore_points().size(), 1)


func test_an_empty_save_keeps_none() -> void:
	assert_false(keeper.keep_today())
	assert_false(FileAccess.file_exists(keeper.points_path))


func test_a_day_west_of_utc() -> void:
	_write_save(1)
	now = DAY_ONE - 10 * 3600 # 02:00 UTC
	keeper.utc_offset_minutes = -300
	keeper.keep_today()
	assert_eq(keeper.restore_points()[0].day, "2026-10-19")


func test_a_full_disk_drops_the_oldest_point_first() -> void:
	var tight := TightKeeper.new()
	tight.store_paths = keeper.store_paths
	tight.points_path = keeper.points_path
	tight.undo_path = keeper.undo_path
	tight.clock = func() -> float: return float(now)
	tight.utc_offset_minutes = 0
	for day in 3:
		_write_save(day + 1)
		now = DAY_ONE + day * DAY
		assert_true(tight.keep_today())
	tight.room = 2
	_write_save(4)
	now += DAY
	assert_true(tight.keep_today())
	var marks: Array[int] = []
	for p: SaveKeeper.Point in tight.restore_points():
		marks.append(int(p.save.stores["settings"]["data"]["n"]))
	assert_eq(marks, [4, 3], "today's kept, the oldest dropped till it fit")
	tight.room = 0
	_write_save(5)
	now += DAY
	assert_false(tight.keep_today(), "nothing fits: no point, the list as it was")
	assert_eq(tight.restore_points().size(), 2)


func test_a_damaged_points_file_is_set_aside_for_a_new_list() -> void:
	var f := FileAccess.open(keeper.points_path, FileAccess.WRITE)
	f.store_string("ASAVE restore_points 1 beef\n{}")
	f.close()
	_write_save(1)
	assert_true(keeper.keep_today())
	assert_eq(keeper.restore_points().size(), 1)
	assert_eq(_corrupt_copies(), 1, "the damaged list kept aside")


func test_the_day_is_the_players_local_day() -> void:
	_write_save(1)
	now = DAY_ONE + 11 * 3600 + 1800 # 23:30 UTC
	keeper.utc_offset_minutes = 60
	keeper.keep_today()
	assert_eq(keeper.restore_points()[0].day, "2026-10-21")


func test_a_newer_builds_points_file_is_never_written_over() -> void:
	SaveFile.write(keeper.points_path, SaveKeeper.POINTS_KIND, SaveKeeper.POINTS_VERSION + 1, {"points": []})
	var before := FileAccess.get_file_as_bytes(keeper.points_path)
	_write_save(1)
	assert_false(keeper.keep_today())
	assert_eq(FileAccess.get_file_as_bytes(keeper.points_path), before)
	assert_eq(keeper.restore_points().size(), 0)


# ---------------------------------------------------------------- replace
func test_restore_undo_and_delete_round_trip_byte_for_byte() -> void:
	_write_save(1)
	var first := _mains()
	keeper.keep_today()
	_write_save(2)
	var second := _mains()
	assert_ne(first, second)
	assert_true(keeper.replace(keeper.restore_points()[0].save, SaveKeeper.What.RESTORE))
	assert_eq(_mains(), first, "the restore point's save, byte for byte")
	assert_eq(keeper.undo_slot().what, SaveKeeper.What.RESTORE)
	after_each()
	assert_true(keeper.undo())
	assert_eq(_mains(), second, "Undo brings back the save it replaced")
	assert_null(keeper.undo_slot(), "Undo uses the slot up")
	assert_false(FileAccess.file_exists(keeper.undo_path))
	after_each()
	assert_true(keeper.delete_save())
	for path: String in _paths():
		for suffix: String in SaveFile.SUFFIXES:
			assert_false(FileAccess.file_exists(path + suffix), "every copy of %s%s gone" % [path.get_file(), suffix])
	assert_eq(keeper.undo_slot().what, SaveKeeper.What.DELETE)
	after_each()
	assert_true(keeper.undo())
	assert_eq(_mains(), second, "Undo brings back the deleted save")


func test_a_replace_holds_the_stores_until_the_restart() -> void:
	_write_save(1)
	assert_true(keeper.delete_save())
	for path: String in _paths():
		assert_true(SaveFile.held(path))
	assert_false(SaveFile.write(_paths()[0], "settings", 1, {"late": true}), "a late settings save is refused")
	assert_false(FileAccess.file_exists(_paths()[0]))
	assert_false(keeper.undo(), "nothing more replaces the save before the restart")
	assert_string_contains(keeper.last_error, "restart first")
	assert_false(keeper.replace(SaveBundle.read(_paths()), SaveKeeper.What.RESTORE))
	assert_string_contains(keeper.last_error, "restart first", "refused up front, not after a roll-back")


func test_a_store_that_wont_write_leaves_every_store_and_the_undo_slot_as_they_were() -> void:
	_write_save(1)
	_write_save(2) # every store has a backup too
	keeper.keep_today()
	_write_save(3)
	assert_true(keeper.delete_save())
	after_each()
	_write_save(4)
	# root ignores read-only folders, so a folder where the records' temp copy goes makes its write fail
	DirAccess.make_dir_absolute(_paths()[3] + SaveFile.TMP)
	var before := _files()
	var point := keeper.restore_points()[0].save
	assert_false(keeper.replace(point, SaveKeeper.What.RESTORE))
	assert_eq(_files(), before, "all four stores, their copies and the Undo slot as they were")
	assert_ne(keeper.last_error, "")
	assert_false(SaveFile.held(_paths()[0]), "a failed replace holds nothing")
	assert_false(keeper.undo())
	assert_eq(_files(), before, "Undo fails the same way and changes nothing")


func test_a_delete_that_cant_remove_a_store_puts_everything_back() -> void:
	var locked := dir.path_join("locked")
	DirAccess.make_dir_absolute(locked)
	keeper.store_paths[3] = locked.path_join("records.save")
	_write_save(1)
	_write_save(2)
	keeper.keep_today()
	_write_save(3)
	SaveFile.write(keeper.undo_path, SaveKeeper.UNDO_KIND, 1, {"what": "delete", "save": {}})
	if not _lock(locked):
		pending("no way to make a folder refuse removals here (chattr or a non-root chmod)")
		return
	var before := _files()
	var records := FileAccess.get_file_as_bytes(keeper.store_paths[3])
	var deleted := keeper.delete_save()
	_unlock(locked)
	assert_false(deleted)
	assert_eq(_files(), before, "three stores, their backups and the Undo slot put back")
	assert_eq(FileAccess.get_file_as_bytes(keeper.store_paths[3]), records)
	assert_false(SaveFile.held(_paths()[0]))


func test_a_restore_over_an_empty_save_keeps_the_undo_slot() -> void:
	# QA: play (save 2), Delete (the slot holds save 2), restart, then Restore a point: save 2 must stay undoable
	_write_save(1)
	keeper.keep_today()
	_write_save(2)
	assert_true(keeper.delete_save())
	after_each()
	var slot := FileAccess.get_file_as_bytes(keeper.undo_path)
	assert_true(keeper.replace(keeper.restore_points()[0].save, SaveKeeper.What.RESTORE))
	assert_eq(FileAccess.get_file_as_bytes(keeper.undo_path), slot, "the slot as it was")
	assert_eq(int(keeper.undo_slot().save.stores["records"]["data"]["n"]), 2)


func test_damaged_stores_are_set_aside_never_destroyed() -> void:
	_write_save(1)
	keeper.keep_today()
	for path: String in _paths():
		SaveFile.remove(path)
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string("ASAVE garbled 1 beef\n{}")
		f.close()
	SaveFile.write(keeper.undo_path, SaveKeeper.UNDO_KIND, 1, {"what": "delete", "save": {}})
	var slot := FileAccess.get_file_as_bytes(keeper.undo_path)
	assert_true(keeper.replace(keeper.restore_points()[0].save, SaveKeeper.What.RESTORE))
	assert_eq(_corrupt_copies(), 4, "each damaged store kept aside")
	assert_eq(FileAccess.get_file_as_bytes(keeper.undo_path), slot, "only damaged stores: the slot as it was")


func test_a_save_holding_a_newer_store_is_never_replaced() -> void:
	_write_save(1)
	keeper.keep_today()
	SaveFile.write(_paths()[2], "progress", Progress.VERSION + 1, {"n": 9})
	var before := _files()
	for what: SaveKeeper.What in [SaveKeeper.What.RESTORE, SaveKeeper.What.DELETE]:
		var b := keeper.restore_points()[0].save if what == SaveKeeper.What.RESTORE else SaveBundle.new()
		assert_false(keeper.replace(b, what))
		assert_string_contains(keeper.last_error, "progress is version %d" % (Progress.VERSION + 1))
		assert_eq(_files(), before, "nothing written")
	assert_false(keeper.delete_save())


func test_nothing_changes_when_the_undo_slot_wont_write() -> void:
	_write_save(1)
	keeper.undo_path = dir.path_join("no/such/folder/undo.save")
	var before := _files()
	assert_false(keeper.delete_save())
	assert_eq(_files(), before)
	assert_string_contains(keeper.last_error, "Undo")


func test_a_newer_store_is_refused_with_its_version() -> void:
	_write_save(1)
	var before := _files()
	var b := SaveBundle.read(_paths())
	b.stores["progress"]["version"] = Progress.VERSION + 1
	assert_false(keeper.replace(b, SaveKeeper.What.RESTORE))
	assert_string_contains(keeper.last_error, "version %d" % (Progress.VERSION + 1))
	assert_eq(_files(), before, "nothing written, not even the Undo slot")


func test_a_point_taken_by_a_newer_build_is_refused_with_its_version() -> void:
	_write_save(1)
	var b := SaveBundle.read(_paths())
	b.version = "99.0"
	assert_false(keeper.replace(b, SaveKeeper.What.RESTORE))
	assert_string_contains(keeper.last_error, "99.0")


func test_nothing_to_undo() -> void:
	_write_save(1)
	assert_null(keeper.undo_slot())
	assert_false(keeper.undo())
	assert_eq(keeper.last_error, "nothing to undo")


func test_an_empty_save_has_nothing_to_delete_and_keeps_the_undo_slot() -> void:
	_write_save(1)
	assert_true(keeper.delete_save())
	after_each()
	var slot := FileAccess.get_file_as_bytes(keeper.undo_path)
	assert_false(keeper.delete_save())
	assert_eq(keeper.last_error, "nothing to delete")
	assert_eq(FileAccess.get_file_as_bytes(keeper.undo_path), slot)


func _corrupt_copies() -> int:
	var n := 0
	for f: String in DirAccess.get_files_at(dir):
		if f.contains(".corrupt-"):
			n += 1
	return n


## Makes `folder` refuse removals: immutable as root (chattr), read-only otherwise. False when neither holds.
func _lock(folder: String) -> bool:
	var real := ProjectSettings.globalize_path(folder)
	if OS.get_name() != "Linux":
		return false
	if OS.execute("chattr", ["+i", real]) == 0:
		return true
	OS.execute("chmod", ["555", real])
	var probe := FileAccess.open(folder.path_join("probe"), FileAccess.WRITE)
	if probe == null:
		return true
	probe.close()
	DirAccess.remove_absolute(folder.path_join("probe"))
	_unlock(folder)
	return false


func _unlock(folder: String) -> void:
	var real := ProjectSettings.globalize_path(folder)
	OS.execute("chattr", ["-i", real])
	OS.execute("chmod", ["755", real])


## A keeper whose disk holds only `room` restore points.
class TightKeeper:
	extends SaveKeeper
	var room: int = SaveKeeper.RESTORE_POINTS

	func _write_points(points: Array[SaveKeeper.Point]) -> bool:
		return points.size() <= room and super(points)
