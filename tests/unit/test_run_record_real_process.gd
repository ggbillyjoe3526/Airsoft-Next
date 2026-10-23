extends GutTest
## SV3 QA: the second-copy checks with a real process, not an injected stand-in. On Godot 4.7.2
## OS.is_process_running knows only this process's own children (any other id logs an error and reads as gone), so a
## second copy took the first one's live run for a crash; ProcessCheck answers for any process, with no error.


func test_a_running_process_that_is_not_a_child_reads_as_running() -> void:
	var r := RunRecord.new()
	r.start("0.1 Dev 1", 100, OS.get_process_id())
	# the first copy is this very process, running; "me" is another copy's pid
	assert_true(r.held_by_other(OS.get_process_id() + 1, ProcessCheck.is_running))


func test_processes_running_and_gone() -> void:
	assert_true(ProcessCheck.is_running(OS.get_process_id()), "this one")
	assert_false(ProcessCheck.is_running(0))
	assert_false(ProcessCheck.is_running(-3))
	if OS.get_name() != "Linux":
		return
	assert_true(ProcessCheck.is_running(1), "init: running, and nobody's child here")
	var child := OS.create_process("sleep", ["30"])
	assert_gt(child, 0)
	assert_true(ProcessCheck.is_running(child), "a child")
	OS.kill(child)
	await wait_until(func() -> bool: return not ProcessCheck.is_running(child), 5.0)
	assert_false(ProcessCheck.is_running(child), "gone once killed")
	assert_false(ProcessCheck.is_running(4194304 + 7), "past Linux's highest pid")


const FILES: Array[String] = ["user://test-sv3-real-run.save", "user://test-sv3-real-guard.save",
		"user://test-sv3-real-renderer.cfg"]


func test_the_entry_scene_and_the_safe_start_ask_it_by_default() -> void:
	var main: Node = preload("res://game/main.tscn").instantiate()
	main.run_path = FILES[0]
	var g := GraphicsStartUp.new()
	g.guard_path = FILES[1]
	g.renderer_path = FILES[2]
	g.settings_path = "user://test-sv3-real-settings.save"
	g.restart = func() -> void: pass
	g.start(false)
	assert_eq(g.process_running, Callable(ProcessCheck.is_running))
	add_child(main)
	assert_eq(main.run_process_running, Callable(ProcessCheck.is_running))
	main.free()
	for path in FILES:
		SaveFile.remove(path)
