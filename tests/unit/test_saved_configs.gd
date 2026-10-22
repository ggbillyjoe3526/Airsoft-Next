extends GutTest
## Every config a saved .tres holds is written into the file. An export converts the .tres in the editor, where a
## script's `= SomeConfig.new()` default doesn't run, so a config left out of the file ships as null and the exported
## game crashes (flag and vault, 2026-10-22). Runs in the editor as well as the tests do, so it reads the file's text.

const FILES: Array[String] = ["res://game/config/sim_tuning.tres", "res://game/config/play_tuning.tres",
	"res://game/config/bot_tuning.tres", "res://game/config/replicas/aeg.tres",
	"res://game/config/replicas/cyber.tres", "res://game/config/replicas/pistol.tres"]


func test_every_config_in_a_saved_file_is_written_into_it() -> void:
	for path in FILES:
		var text := FileAccess.get_file_as_string(path)
		var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		assert_not_null(res, path)
		_check(res, text, path, "[resource]")


## Each Resource-valued stored property of `res` appears as `name = ` in its own block of `text`, recursively.
func _check(res: Resource, text: String, path: String, header: String) -> void:
	var block := _block(text, header)
	for p: Dictionary in res.get_property_list():
		if not (int(p.usage) & PROPERTY_USAGE_STORAGE) or int(p.type) != TYPE_OBJECT:
			continue
		var value: Variant = res.get(p.name)
		if not (value is Resource) or p.name == "script":
			continue
		var sub := value as Resource
		if not sub.resource_path.is_empty() and not sub.resource_path.contains("::"):
			continue # a file of its own
		var name: String = p.name
		assert_true(block.contains("\n%s = " % name), "%s writes %s out (%s)" % [path, name, header])
		if not sub.resource_scene_unique_id.is_empty():
			_check(sub, text, path, '[sub_resource type="Resource" id="%s"]' % sub.resource_scene_unique_id)


## The lines of `text` from `header` up to the next block.
static func _block(text: String, header: String) -> String:
	var at := text.find(header)
	if at < 0:
		return ""
	var end := text.find("\n[", at + header.length())
	return text.substr(at, (text.length() if end < 0 else end) - at)
