extends GutTest
## FrameWindow (SV4): the last frame_seconds of frame times summed up (average, worst, hitches), the ring's wrap, and
## nothing allocated by a warm frame.

const FRAME := 1.0 / 100.0
const WARM_FRAMES := 2000
const TIMED_FRAMES := 100000

var _config: ReportConfig


func before_each() -> void:
	_config = ReportConfig.new()


func test_no_frames_say_nothing() -> void:
	var w := FrameWindow.new(_config)
	assert_eq(w.line(), "")
	assert_eq(w.frames, 0)


func test_sums_up_average_worst_and_hitches() -> void:
	var w := FrameWindow.new(_config)
	for i in 500:
		w.add(FRAME)
	w.add(0.06)
	w.add(0.03)
	w.add(0.08)
	w.summarise()
	assert_eq(w.frames, 503)
	assert_eq(w.hitches, 2, "over 50 ms")
	assert_almost_eq(w.worst_ms, 80.0, 0.01)
	assert_almost_eq(w.seconds, 5.17, 0.001)
	assert_eq(w.line(), "last 5 s 97 fps average, worst 80 ms, 2 hitches")


func test_only_the_last_frame_seconds_count() -> void:
	var w := FrameWindow.new(_config)
	w.add(0.2) # a hitch long ago
	for i in roundi(_config.frame_seconds / FRAME):
		w.add(FRAME)
	w.summarise()
	assert_eq(w.hitches, 0)
	assert_almost_eq(w.seconds, _config.frame_seconds, 0.001)
	assert_eq(w.line(), "last 10 s 100 fps average, worst 10 ms, 0 hitches")


func test_the_ring_wraps_and_a_faster_rate_than_it_holds_covers_less() -> void:
	var w := FrameWindow.new(_config)
	var fast := 1.0 / (_config.frame_rate_held * 2.0)
	for i in w.capacity() + 123:
		w.add(fast)
	w.summarise()
	assert_eq(w.frames, w.capacity())
	assert_almost_eq(w.seconds, _config.frame_seconds / 2.0, 0.01)
	assert_eq(w.line(), "last 5 s 1000 fps average, worst 1 ms, 0 hitches")


func test_one_hitch_is_a_hitch() -> void:
	var w := FrameWindow.new(_config)
	w.add(FRAME)
	w.add(_config.hitch_ms / 1000.0 + 0.001)
	assert_string_ends_with(w.line(), "1 hitch")


func test_clear_forgets() -> void:
	var w := FrameWindow.new(_config)
	w.add(FRAME)
	w.clear()
	assert_eq(w.line(), "")


## DebugPerf's counts: warm frames make no object and leave the ring's memory as it was.
func test_a_warm_frame_allocates_nothing() -> void:
	var w := FrameWindow.new(_config)
	for i in WARM_FRAMES:
		w.add(FRAME)
	var objects := Performance.get_monitor(Performance.OBJECT_COUNT)
	var memory := Performance.get_monitor(Performance.MEMORY_STATIC)
	for i in WARM_FRAMES:
		w.add(FRAME)
	var objects_after := Performance.get_monitor(Performance.OBJECT_COUNT)
	var memory_after := Performance.get_monitor(Performance.MEMORY_STATIC)
	assert_lte(objects_after, objects, "no objects")
	assert_lte(memory_after, memory, "no memory")


## The perf figures for the record: a frame's add, and a whole window's summary (made only with a report).
func test_frame_and_summary_cost() -> void:
	var w := FrameWindow.new(_config)
	for i in WARM_FRAMES:
		w.add(FRAME)
	var t := Time.get_ticks_usec()
	for i in TIMED_FRAMES:
		w.add(FRAME)
	var add_us := float(Time.get_ticks_usec() - t) / TIMED_FRAMES
	t = Time.get_ticks_usec()
	var text := w.line()
	var line_us := Time.get_ticks_usec() - t
	gut.p("FrameWindow.add: %.3f µs; a full window's line (%d frames): %d µs" % [add_us, w.frames, line_us])
	assert_ne(text, "")
	assert_lt(add_us, 20.0)
