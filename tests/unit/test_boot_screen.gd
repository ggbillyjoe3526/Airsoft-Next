extends GutTest
## The boot screen (QA): credits start hidden, open and close with Esc, F3 toggles the overlay, and freeing the
## scene leaves no orphan nodes or node_added connections behind.

const MAIN := preload("res://game/main.tscn")


func _credits(main: Node) -> Credits:
	for c: Node in main.get_children():
		if c is Credits:
			return c
	return null


func _perf(main: Node) -> DebugPerf:
	for c: Node in main.get_children():
		if c is DebugPerf:
			return c
	return null


func _press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)


func test_credits_open_and_close_with_escape() -> void:
	var main: Node = add_child_autofree(MAIN.instantiate())
	await wait_process_frames(2)
	var credits := _credits(main)
	assert_not_null(credits)
	assert_false(credits.visible, "credits start hidden")
	credits.open()
	assert_true(credits.visible)
	assert_true(credits.has_notices(), "the licence notices are in the credits")
	assert_gt(credits.text_length(), 1000)
	_press("ui_cancel")
	await wait_process_frames(2)
	assert_false(credits.visible, "Esc closes the credits")


func test_f3_toggles_the_overlay() -> void:
	var main: Node = add_child_autofree(MAIN.instantiate())
	await wait_process_frames(2)
	var perf := _perf(main)
	assert_not_null(perf)
	var k := InputEventKey.new()
	k.physical_keycode = KEY_F3
	k.keycode = KEY_F3
	k.pressed = true
	Input.parse_input_event(k)
	await wait_process_frames(2)
	var label: Label = perf.get_child(1)
	assert_true(label.visible, "F3 shows the overlay")


func test_freeing_the_boot_screen_leaves_nothing_behind() -> void:
	var before_orphans := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	var before_nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var main: Node = MAIN.instantiate()
	add_child(main)
	await wait_process_frames(3)
	var perf := _perf(main)
	var cb := Callable(perf, "_on_node_added")
	assert_true(get_tree().node_added.is_connected(cb))
	main.queue_free()
	await wait_process_frames(2)
	assert_false(get_tree().node_added.is_connected(cb), "node_added disconnected")
	assert_eq(Performance.get_monitor(Performance.OBJECT_NODE_COUNT), before_nodes)
	assert_eq(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), before_orphans)
