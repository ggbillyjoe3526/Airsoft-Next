extends GutTest
## Save files are crash safe: atomic writes, one backup, and corrupt or half-written files
## never trusted. Each test gets its own empty folder. Ported from katanashotgun with SaveFile.

const ROOT := "user://test-save"

var dir := ""
var _n := 0


func before_each() -> void:
	_n += 1
	dir = "%s/%d" % [ROOT, _n]
	_wipe(dir)
	DirAccess.make_dir_recursive_absolute(dir)


func after_all() -> void:
	_wipe(ROOT)


func _wipe(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for d in DirAccess.get_directories_at(path):
		_wipe(path.path_join(d))
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)


func _path() -> String:
	return dir.path_join("thing.json")


func _write_raw(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _corrupt(path: String) -> void:
	var text := SaveFile.read_text(path)
	_write_raw(path, text.substr(0, text.length() - 7) + "garbage")


# ---------------------------------------------------------------- SaveFile
func test_round_trip() -> void:
	assert_true(SaveFile.write(_path(), "thing", 3, {"a": 1, "b": "two"}))
	var r := SaveFile.read(_path(), "thing")
	assert_true(r.ok)
	assert_eq(r.version, 3)
	assert_eq(r.source, "main")
	assert_eq(int(r.data.a), 1)
	assert_eq(r.data.b, "two")
	assert_false(FileAccess.file_exists(_path() + ".tmp"), "no temp file left behind")


func test_second_write_keeps_a_backup() -> void:
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	SaveFile.write(_path(), "thing", 1, {"n": 2})
	assert_eq(int(SaveFile.decode(SaveFile.read_text(_path() + ".bak"), "thing").data.n), 1)
	assert_eq(int(SaveFile.read(_path(), "thing").data.n), 2)


func test_checksum_catches_damage() -> void:
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	_corrupt(_path())
	assert_false(SaveFile.decode(SaveFile.read_text(_path()), "thing").ok)


func test_damaged_file_falls_back_to_backup() -> void:
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	SaveFile.write(_path(), "thing", 1, {"n": 2})
	_corrupt(_path())
	var r := SaveFile.read(_path(), "thing")
	assert_true(r.ok)
	assert_eq(r.source, "backup")
	assert_eq(int(r.data.n), 1)


func test_half_written_file_falls_back() -> void:
	# a crash or full disk mid-write leaves a short file
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	SaveFile.write(_path(), "thing", 1, {"n": 2, "pad": "x".repeat(200)})
	var text := SaveFile.read_text(_path())
	_write_raw(_path(), text.substr(0, text.length() / 2))
	var r := SaveFile.read(_path(), "thing")
	assert_true(r.ok)
	assert_eq(int(r.data.n), 1)


func test_crash_during_temp_write_keeps_the_old_file() -> void:
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	_write_raw(_path() + ".tmp", SaveFile.encode("thing", 1, {"n": 2}).substr(0, 30))
	var r := SaveFile.read(_path(), "thing")
	assert_eq(r.source, "main")
	assert_eq(int(r.data.n), 1)


func test_crash_between_rotate_and_rename_uses_the_temp_file() -> void:
	# the old file became the backup, the new one is complete in .tmp, and
	# the game died before renaming it
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	DirAccess.rename_absolute(_path(), _path() + ".bak")
	_write_raw(_path() + ".tmp", SaveFile.encode("thing", 1, {"n": 2}))
	var r := SaveFile.read(_path(), "thing")
	assert_eq(r.source, "tmp")
	assert_eq(int(r.data.n), 2)
	# and the next write cleans up
	assert_true(SaveFile.write(_path(), "thing", 1, {"n": 3}))
	assert_eq(int(SaveFile.read(_path(), "thing").data.n), 3)
	assert_false(FileAccess.file_exists(_path() + ".tmp"))


func test_a_damaged_file_never_replaces_a_good_backup() -> void:
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	SaveFile.write(_path(), "thing", 1, {"n": 2})
	_corrupt(_path())
	SaveFile.write(_path(), "thing", 1, {"n": 3})
	assert_eq(int(SaveFile.decode(SaveFile.read_text(_path() + ".bak"), "thing").data.n), 1)


func test_wrong_kind_is_rejected() -> void:
	SaveFile.write(_path(), "run", 1, {"n": 1})
	assert_false(SaveFile.read(_path(), "profile").ok)


func test_garbage_and_empty_files_are_rejected() -> void:
	for text in ["", "{}", "ASAVE thing 1\n{}", "ASAVE thing x abc\n{}", "not a save at all"]:
		assert_false(SaveFile.decode(text, "thing").ok, "accepted: %s" % text)


func test_nothing_on_disk_reports_not_found() -> void:
	var r := SaveFile.read(_path(), "thing")
	assert_false(r.ok)
	assert_false(r.found)
