extends GutTest
## Version names and tags follow docs/PROCESS.md › Versioning; the release workflow (tools/version.sh) refuses
## anything else, so a wrong value fails here first.


func test_project_version_is_a_version_name() -> void:
	assert_ne(Version.tag_for(Version.current()), "", "config/version '%s' must look like '0.1 Dev 1'" % Version.current())


func test_names_become_tags() -> void:
	assert_eq(Version.tag_for("0.1 Dev 1"), "0.1-dev.1")
	assert_eq(Version.tag_for("0.1 Dev 12"), "0.1-dev.12")
	assert_eq(Version.tag_for("0.1 Beta 2"), "0.1-beta.2")
	assert_eq(Version.tag_for("0.1"), "0.1.0")
	assert_eq(Version.tag_for("1.0"), "1.0.0")
	assert_eq(Version.tag_for("0.1.2"), "0.1.2")


func test_tags_become_names() -> void:
	assert_eq(Version.name_for("0.1-dev.1"), "0.1 Dev 1")
	assert_eq(Version.name_for("0.1-beta.2"), "0.1 Beta 2")
	assert_eq(Version.name_for("0.1.0"), "0.1")
	assert_eq(Version.name_for("0.1.2"), "0.1.2")


func test_bad_forms_are_refused() -> void:
	for bad: String in ["v0.1 Dev 1", "0.1 dev 1", "0.1 Dev 0", "0.1 Alpha 1", "0.1-dev.1", "0.1.0", "0.1.1 Dev 1"]:
		assert_eq(Version.tag_for(bad), "", bad)
	for bad: String in ["v0.1-dev.1", "0.1-dev-1", "0.1-dev.0", "0.1", "0.1.1-dev.1", "0.1 Dev 1"]:
		assert_eq(Version.name_for(bad), "", bad)


func test_newer_orders_builds() -> void:
	var order: Array[String] = ["0.1 Dev 1", "0.1 Dev 2", "0.1 Dev 10", "0.1 Beta 1", "0.1", "0.1.1", "0.2 Dev 1", "1.0"]
	for i in order.size():
		for j in order.size():
			assert_eq(Version.newer(order[i], order[j]), i > j, "%s after %s" % [order[i], order[j]])


func test_newer_knows_nothing_of_a_bad_name() -> void:
	assert_false(Version.newer("9.9 Dev 1x", "0.1 Dev 1"))
	assert_false(Version.newer("0.2 Dev 1", ""))
