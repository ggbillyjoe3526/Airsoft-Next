extends GutTest
## SaveFile's failure paths (QA): every copy damaged, missing or empty files, a forged header, a bad folder,
## quarantine and remove. Each test gets its own empty folder.

const ROOT := "user://test-save-failures"

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
	for d: String in DirAccess.get_directories_at(path):
		_wipe(path.path_join(d))
	for f: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)


func _path() -> String:
	return dir.path_join("thing.json")


func _write_raw(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_every_copy_damaged_reports_found_but_not_ok() -> void:
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	SaveFile.write(_path(), "thing", 1, {"n": 2})
	for suffix: String in ["", ".bak", ".tmp"]:
		_write_raw(_path() + suffix, "ASAVE thing 1 0000\n{}")
	var r := SaveFile.read(_path(), "thing")
	assert_false(r.ok)
	assert_true(r.found)


func test_damaged_tmp_and_main_fall_back_to_backup() -> void:
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	SaveFile.write(_path(), "thing", 1, {"n": 2})
	_write_raw(_path(), "garbage")
	_write_raw(_path() + ".tmp", "ASAVE thing 1")
	var r := SaveFile.read(_path(), "thing")
	assert_true(r.ok)
	assert_eq(r.source, "backup")
	assert_eq(int(r.data.n), 1)


func test_an_empty_file_counts_as_found() -> void:
	_write_raw(_path(), "")
	var r := SaveFile.read(_path(), "thing")
	assert_false(r.ok)
	assert_true(r.found)


func test_forged_checksum_is_rejected() -> void:
	var text := SaveFile.encode("thing", 1, {"n": 1})
	var nl := text.find("\n")
	var forged := text.substr(0, nl - 4) + "beef" + text.substr(nl)
	assert_eq(SaveFile.decode(forged, "thing").error, "checksum mismatch")


func test_payload_that_is_not_an_object_is_rejected() -> void:
	var payload := "[1, 2]"
	var r := SaveFile.decode("ASAVE thing 1 %s\n%s" % [payload.sha256_text(), payload], "thing")
	assert_false(r.ok)


func test_wrong_kind_says_so() -> void:
	var r := SaveFile.decode(SaveFile.encode("run", 1, {}), "profile")
	assert_false(r.ok)
	assert_string_contains(r.error, "wrong kind")


func test_write_into_a_missing_folder_fails_and_leaves_nothing() -> void:
	var p := dir.path_join("no/such/folder/thing.json")
	assert_false(SaveFile.write(p, "thing", 1, {"n": 1}))
	assert_false(FileAccess.file_exists(p))
	assert_false(FileAccess.file_exists(p + ".tmp"))


func test_a_stale_tmp_is_replaced_by_the_next_write() -> void:
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	_write_raw(_path() + ".tmp", "half a fi")
	assert_true(SaveFile.write(_path(), "thing", 1, {"n": 2}))
	assert_false(FileAccess.file_exists(_path() + ".tmp"))
	var r := SaveFile.read(_path(), "thing")
	assert_eq(r.source, "main")
	assert_eq(int(r.data.n), 2)


func test_quarantine_moves_every_copy_aside() -> void:
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	SaveFile.write(_path(), "thing", 1, {"n": 2})
	_write_raw(_path() + ".tmp", "junk")
	SaveFile.quarantine(_path())
	var r := SaveFile.read(_path(), "thing")
	assert_false(r.ok)
	assert_false(r.found, "nothing left under the save's own names")
	var moved := 0
	for f: String in DirAccess.get_files_at(dir):
		if f.contains(".corrupt-"):
			moved += 1
	assert_eq(moved, 3)


func test_remove_deletes_every_copy() -> void:
	SaveFile.write(_path(), "thing", 1, {"n": 1})
	SaveFile.write(_path(), "thing", 1, {"n": 2})
	_write_raw(_path() + ".tmp", "junk")
	SaveFile.remove(_path())
	assert_eq(DirAccess.get_files_at(dir).size(), 0)


func test_a_write_that_returns_true_can_be_read_back() -> void:
	# A kind with a space makes a five-field header that decode() refuses, so write() must refuse it too rather than
	# report success and later delete the file as "damaged".
	for kind: String in ["thing", "my profile"]:
		var p := dir.path_join("k%d.json" % kind.length())
		if SaveFile.write(p, kind, 1, {"n": 1}):
			assert_true(SaveFile.read(p, kind).ok, "write('%s') said true but read fails" % kind)
