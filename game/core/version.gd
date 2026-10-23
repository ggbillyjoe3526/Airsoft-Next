class_name Version
## The game's version (docs/PROCESS.md › Versioning): names read "0.1 Dev 1", "0.1 Beta 2", "0.1" or "0.1.1" (owner,
## 2026-10-18) and tags read "0.1-dev.1", "0.1-beta.2", "0.1.0" or "0.1.1" (owner, 2026-10-05). The owner's tag is the source:
## the release workflow writes its name into project.godot (config/version) before it exports, and the title shows it.

const NAME_PATTERN := "^(0|[1-9][0-9]{0,3})\\.(0|[1-9][0-9]{0,3})(?:( (Dev|Beta) ([1-9][0-9]{0,3}))|\\.([1-9][0-9]{0,3}))?\\z"
const TAG_PATTERN := "^(0|[1-9][0-9]{0,3})\\.(0|[1-9][0-9]{0,3})(?:-(dev|beta)\\.([1-9][0-9]{0,3})|\\.(0|[1-9][0-9]{0,3}))\\z"


## The version this build carries, as players see it.
static func current() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))


## "0.1 Dev 1" -> "0.1-dev.1", "0.1" -> "0.1.0", "0.1.1" -> "0.1.1". Returns "" for anything that isn't a version name.
static func tag_for(version_name: String) -> String:
	var m := RegEx.create_from_string(NAME_PATTERN).search(version_name)
	if m == null:
		return ""
	var base := "%s.%s" % [m.get_string(1), m.get_string(2)]
	if m.get_string(4) != "":
		return "%s-%s.%s" % [base, m.get_string(4).to_lower(), m.get_string(5)]
	return "%s.%s" % [base, m.get_string(6) if m.get_string(6) != "" else "0"]


## "0.1-dev.1" -> "0.1 Dev 1", "0.1.0" -> "0.1", "0.1.1" -> "0.1.1". Returns "" for anything that isn't a version tag.
static func name_for(tag: String) -> String:
	var m := RegEx.create_from_string(TAG_PATTERN).search(tag)
	if m == null:
		return ""
	var base := "%s.%s" % [m.get_string(1), m.get_string(2)]
	if m.get_string(3) != "":
		return "%s %s %s" % [base, m.get_string(3).capitalize(), m.get_string(4)]
	return base if m.get_string(5) == "0" else "%s.%s" % [base, m.get_string(5)]


## Whether version name `a` is a later build than `b`: "0.1 Dev 2" after "0.1 Dev 1", any Beta after every Dev, the
## release ("0.1") after its Betas, "0.1.1" after "0.1". False when either isn't a version name (nothing is known).
static func newer(a: String, b: String) -> bool:
	var ka := _order(a)
	var kb := _order(b)
	if ka.is_empty() or kb.is_empty():
		return false
	for i in ka.size():
		if ka[i] != kb[i]:
			return ka[i] > kb[i]
	return false


## A name's place in the order: [major, minor, stage (Dev 0, Beta 1, release 2), number or patch]; empty if it isn't one.
static func _order(version_name: String) -> PackedInt32Array:
	var m := RegEx.create_from_string(NAME_PATTERN).search(version_name)
	if m == null:
		return PackedInt32Array()
	var stage := 2
	var number := m.get_string(6).to_int()
	if m.get_string(4) != "":
		stage = 0 if m.get_string(4) == "Dev" else 1
		number = m.get_string(5).to_int()
	return PackedInt32Array([m.get_string(1).to_int(), m.get_string(2).to_int(), stage, number])
