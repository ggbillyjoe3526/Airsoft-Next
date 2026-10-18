extends GutTest
## The GBB Pistol's slide in your hands (game/play/replica_view.gd): it locks back on the last BB, stays back through
## most of the reload and closes near its end; the AEG has no slide lock.

const DT := 1.0 / 60.0

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


func test_only_the_gas_pistol_has_a_slide_to_lock() -> void:
	assert_eq(a.replicas[1].power, &"gas")
	assert_not_null(_pistol().slide, "the GBB Pistol's slide was found")
	assert_null(view._held[0].slide, "the AEG has none")
	assert_ne(_pistol().slide_back, Vector3.ZERO)


func test_the_slide_locks_back_on_empty_and_closes_late_in_the_reload() -> void:
	a.active = 1
	_frame()
	var home := _pistol().slide.position
	assert_false(ReplicaView.slide_held_back(a))
	a.ammo[1].mag = 0
	_frame()
	assert_true(_pistol().slide_locked)
	assert_almost_eq(_pistol().slide.position, _pistol().slide_back, Vector3.ONE * 0.0001)
	# A reload: back for most of it, home near the end.
	var r := a.replicas[1]
	a.reload_left = r.reload_time * 0.5
	_frame()
	assert_almost_eq(_pistol().slide.position, _pistol().slide_back, Vector3.ONE * 0.0001, "still back mid-reload")
	a.reload_left = r.reload_time * (1.0 - cfg.slide_release_at) * 0.5
	_frame()
	assert_almost_eq(_pistol().slide.position, home, Vector3.ONE * 0.0001, "closed near the end")
	a.reload_left = 0.0
	a.ammo[1].mag = r.mag_size
	_frame()
	assert_false(_pistol().slide_locked)
	assert_almost_eq(_pistol().slide.position, home, Vector3.ONE * 0.0001)


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
