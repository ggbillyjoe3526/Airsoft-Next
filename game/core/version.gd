class_name Version
## The game's version (docs/PROCESS.md › Versioning): names read "0.1 Dev 1", "0.1 Beta 2", "0.1" or "0.1.1" (owner,
## 2026-10-18) and tags read "0.1-dev.1", "0.1-beta.2", "0.1.0" or "0.1.1" (owner, 2026-10-05). The owner's tag is the source:
## the release workflow writes its name into project.godot (config/version) before it exports, and the title shows it.

const NAME_PATTERN := "^(0|[1-9][0-9]{0,3})\\.(0|[1-9][0-9]{0,3})(?:( (Dev|Beta) ([1-9][0-9]{0,3}))|\\.([1-9][0-9]{0,3}))?$"
const TAG_PATTERN := "^(0|[1-9][0-9]{0,3})\\.(0|[1-9][0-9]{0,3})(?:-(dev|beta)\\.([1-9][0-9]{0,3})|\\.(0|[1-9][0-9]{0,3}))$"


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
