extends GutTest
## Version edge cases (QA): game/core/version.gd must agree with tools/version.sh, which the release runs.


func test_two_digit_minor_and_build_numbers() -> void:
	assert_eq(Version.tag_for("0.10 Beta 12"), "0.10-beta.12")
	assert_eq(Version.name_for("0.10-beta.12"), "0.10 Beta 12")
	assert_eq(Version.name_for("1.0.0"), "1.0")


func test_leading_zeros_and_stray_spaces_are_refused() -> void:
	for bad: String in ["0.1 Dev 01", "00.1", "0.1.01", " 0.1 Dev 1", "0.1 Dev 1 ", "0.1  Dev 1", "0.1 Dev 10000"]:
		assert_eq(Version.tag_for(bad), "", bad)
	for bad: String in ["0.1-dev.01", "0.1-beta.0", "0.1.10000", "0.1-Dev.1", " 0.1.0", "0.1.0 "]:
		assert_eq(Version.name_for(bad), "", bad)


func test_a_trailing_newline_is_refused_like_tools_version_sh() -> void:
	# PCRE's $ also matches before a final newline; the patterns end in \z so these are refused like tools/version.sh.
	assert_eq(Version.tag_for("0.1 Dev 1\n"), "", "name with a trailing newline")
	assert_eq(Version.name_for("0.1-dev.1\n"), "", "tag with a trailing newline")
