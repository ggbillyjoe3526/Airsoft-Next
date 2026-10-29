extends GutTest
## The GBB Pistol's slide in your hands (game/play/replica_view.gd): it locks back on the last BB, stays back through
## most of the reload and closes near its end; the AEG has no slide lock. The slide is a BoneAttachment3D the skeleton
## re-poses after the view's update, so its drawn position is read after process frames have run (_settle).

const DT := 1.0 / 60.0
const EPS := Vector3.ONE * 0.0001

var view: ReplicaView
var c: Character
var a: Armament
var cfg: ViewModelConfig


func before_each() -> void:
	cfg = ViewModelConfig.new()
	c = Character.new(1, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())
	a = c.armament
	view = ReplicaView.new()
	add_child_autofree(view)
	view.setup(cfg, a.replicas, BoxWorld.new())


func _frame() -> void:
	view.update(c, 0.0, 0.0, Vector3(0.0, 1.6, 0.0), Vector3.FORWARD, DT)


func _pistol() -> ReplicaView.Held:
	return view._held[1]


func _settle() -> void:
	await wait_process_frames(2)


## The slide as drawn after the skeleton's update.
func _drawn() -> Vector3:
	await _settle()
	return _pistol().slide.position


## The slide's drawn rest (loaded) and locked-back (empty, no reload) positions; leaves the pistol in hand, loaded.
func _poses() -> Dictionary:
	a.active = 1
	_frame()
	var home: Vector3 = await _drawn()
	var full := a.ammo[1].mag
	a.ammo[1].mag = 0
	_frame()
	var back: Vector3 = await _drawn()
	a.ammo[1].mag = full
	_frame()
	await _settle()
	return {"home": home, "back": back}


func test_only_the_gas_pistol_has_a_slide_to_lock() -> void:
	assert_eq(a.replicas[1].power, &"gas")
	assert_not_null(_pistol().slide, "the GBB Pistol's slide was found")
	assert_not_null(_pistol().slide_hold, "and what holds it back")
	assert_null(view._held[0].slide, "the AEG has none")
	var poses := await _poses()
	assert_gt(poses.home.distance_to(poses.back), 0.01, "locked back is drawn away from home")
	assert_false(_pistol().slide_locked, "loaded again: home")
	assert_almost_eq(await _drawn(), poses.home, EPS)


func test_the_slide_locks_back_on_empty_and_closes_late_in_the_reload() -> void:
	var poses := await _poses()
	assert_false(ReplicaView.slide_held_back(a))
	a.ammo[1].mag = 0
	_frame()
	assert_true(_pistol().slide_locked)
	assert_almost_eq(await _drawn(), poses.back, EPS, "locked back, no reload")
	_frame()
	assert_almost_eq(await _drawn(), poses.back, EPS, "and stays back")
	# A reload: back for most of it, home near the end.
	var r := a.replicas[1]
	a.reload_left = r.reload_time * 0.5
	_frame()
	assert_almost_eq(await _drawn(), poses.back, EPS, "still back mid-reload")
	a.reload_left = r.reload_time * (1.0 - cfg.slide_release_at) * 0.5
	_frame()
	assert_false(_pistol().slide_locked, "closed near the end")
	a.reload_left = 0.0
	a.ammo[1].mag = r.mag_size
	_frame()
	assert_false(_pistol().slide_locked)
	assert_almost_eq(await _drawn(), poses.home, EPS)


func test_a_new_round_with_full_magazines_closes_a_locked_slide() -> void:
	a.active = 1
	a.ammo[1].mag = 0
	_frame()
	assert_true(_pistol().slide_locked)
	a.refill()
	a.active = 1
	_frame()
	assert_false(_pistol().slide_locked)


func test_the_aeg_runs_dry_without_a_slide_lock() -> void:
	a.ammo[0].mag = 0
	_frame()
	assert_false(view._held[0].slide_locked)


func test_the_slide_waits_out_the_last_shots_fire_clip_then_locks() -> void:
	a.active = 1
	_frame()
	view.on_shot()
	a.ammo[1].mag = 0
	_frame()
	assert_false(_pistol().slide_locked, "the Fire clip has only just started")
	# Let the clip run on; the lock must come once it is past the lock point or has ended.
	var guard := 0
	while not _pistol().slide_locked and guard < 120:
		_pistol().anim.advance(DT)
		_frame()
		guard += 1
	assert_true(_pistol().slide_locked, "locked after the last shot's cycle")


func test_switching_away_mid_reload_and_back_leaves_no_half_posed_slide() -> void:
	var poses := await _poses()
	a.ammo[1].mag = 0
	_frame()
	a.reload_left = a.replicas[1].reload_time * 0.5
	_frame()
	# Switch to the rifle; the reload is cancelled (the sim clears it), then back.
	a.active = 0
	a.reload_left = 0.0
	_frame()
	a.active = 1
	_frame()
	assert_false(_pistol().in_reload, "the cut-short reload clip was finished")
	# The magazine is still empty, so the slide is held back, not stuck between poses.
	assert_true(_pistol().slide_locked)
	assert_almost_eq(await _drawn(), poses.back, EPS)
	# A magazine with BBs: it closes.
	a.ammo[1].mag = 5
	_frame()
	assert_false(_pistol().slide_locked)
	assert_almost_eq(await _drawn(), poses.home, EPS)


func test_a_reload_that_ends_empty_with_no_spare_keeps_the_slide_locked() -> void:
	a.active = 1
	a.ammo[1].mag = 0
	a.ammo[1].pouch.fill(0)
	_frame()
	a.reload_left = a.replicas[1].reload_time * 0.1
	_frame()
	a.reload_left = 0.0
	_frame()
	assert_true(_pistol().slide_locked, "nothing to load: it stays back")


func test_a_reload_started_during_the_last_shots_fire_clip_still_locks_the_slide() -> void:
	# KI2: a reload begun before slide_lock_after of the last shot's Fire clip ran with the slide forward.
	var poses := await _poses()
	view.on_shot()
	a.ammo[1].mag = 0
	_frame()
	assert_false(_pistol().slide_locked, "the Fire clip has only just started")
	var r := a.replicas[1]
	a.reload_left = r.reload_time * 0.9
	_frame()
	assert_true(_pistol().slide_locked, "the reload of an empty magazine holds the slide back")
	assert_almost_eq(await _drawn(), poses.back, EPS, "drawn back early in the reload")
	a.reload_left = r.reload_time * 0.5
	_frame()
	assert_almost_eq(await _drawn(), poses.back, EPS, "still back mid-reload")
	a.reload_left = r.reload_time * (1.0 - cfg.slide_release_at) * 0.5
	_frame()
	assert_false(_pistol().slide_locked, "released near the end")
	a.reload_left = 0.0
	a.ammo[1].mag = r.mag_size
	_frame()
	assert_false(_pistol().slide_locked)
	assert_almost_eq(await _drawn(), poses.home, EPS, "home once loaded")


func test_a_reload_of_a_part_full_magazine_leaves_the_slide_forward() -> void:
	var poses := await _poses()
	a.ammo[1].mag = 3
	_frame()
	a.reload_left = a.replicas[1].reload_time * 0.5
	_frame()
	assert_false(_pistol().slide_locked)
	assert_almost_eq(await _drawn(), poses.home, EPS)
