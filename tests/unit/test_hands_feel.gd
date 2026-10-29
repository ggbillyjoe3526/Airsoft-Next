extends GutTest
## FB4 (the owner's 0.1 Dev 1 playtest, notes 5 and 7): fired on the run, the replica in your hands comes up out of the
## sprint carry, square to the view, while the trigger is held and sprint_fire_hold after the last shot; and it never
## draws into a wall: its materials (and its optic's glass) press their depth towards the eye, and aimed at a wall the
## sight stays at the eye.

const DT := 1.0 / 60.0
const SETTLE := 90
const EPS := 1e-4

var cfg: ViewModelConfig = null


func before_each() -> void:
	cfg = ViewModelConfig.new()


func _hands(c: Character, world: WorldQuery = null) -> ReplicaView:
	var hands := ReplicaView.new()
	add_child_autofree(hands)
	hands.setup(cfg, c.armament.replicas, world if world != null else BoxWorld.new())
	return hands


func _character() -> Character:
	return Character.new(0, 0, Vector3.ZERO, 0.0, ReplicaStats.default_loadout())


func _frames(hands: ReplicaView, c: Character, n: int) -> void:
	for i in n:
		hands.update(c, 0.0, 0.0, Vector3(0.0, 1.6, 0.0), Vector3.FORWARD, DT)


func _pose(hands: ReplicaView, c: Character) -> Transform3D:
	return hands._held[c.armament.active].root.transform


# --- note 5: firing on the run ---

func test_the_trigger_held_on_a_sprint_brings_it_square_to_the_view() -> void:
	var c := _character()
	var hands := _hands(c)
	_frames(hands, c, SETTLE)
	var ready := _pose(hands, c)
	c.sprinting = true
	_frames(hands, c, SETTLE)
	assert_gt(_pose(hands, c).basis.get_euler().length(), 0.1, "control: sprinting, it is carried low and tilted")
	c.armament.trigger_was_down = true
	_frames(hands, c, ceili(cfg.sprint_fire_raise / DT) + 1)
	assert_almost_eq(_pose(hands, c).basis.get_euler(), Vector3.ZERO, Vector3.ONE * EPS, "square to the view")
	assert_almost_eq(_pose(hands, c).origin.y, ready.origin.y, EPS, "at the hip, not carried low")
	_frames(hands, c, SETTLE)
	assert_almost_eq(_pose(hands, c).basis.get_euler(), Vector3.ZERO, Vector3.ONE * EPS, "and stays up while held")


func test_a_shot_holds_it_up_a_moment_then_the_carry_takes_it_again() -> void:
	var c := _character()
	var hands := _hands(c)
	c.sprinting = true
	_frames(hands, c, SETTLE)
	hands.on_shot()
	_frames(hands, c, ceili(cfg.sprint_fire_raise / DT) + 1)
	assert_almost_eq(_pose(hands, c).basis.get_euler(), Vector3.ZERO, Vector3.ONE * EPS, "up for the shot")
	_frames(hands, c, floori((cfg.sprint_fire_hold - cfg.sprint_fire_raise) / DT) - 2)
	assert_almost_eq(_pose(hands, c).basis.get_euler(), Vector3.ZERO, Vector3.ONE * EPS, "held up after it")
	_frames(hands, c, SETTLE)
	assert_gt(_pose(hands, c).basis.get_euler().length(), 0.1, "then carried again")


func test_the_tuning_is_the_browser_game_s() -> void:
	assert_almost_eq(cfg.sprint_fire_raise, 0.06, 1e-6)
	assert_almost_eq(cfg.sprint_fire_hold, 0.35, 1e-6)


# --- note 7: never into a wall ---

func test_every_surface_in_the_hands_presses_its_depth_and_shared_paints_stay_untouched() -> void:
	var c := _character()
	var hands := _hands(c)
	var seen := 0
	for held: ReplicaView.Held in hands._held:
		for node: Node in held.root.find_children("*", "MeshInstance3D", true, false):
			var m := node as MeshInstance3D
			if m.material_override != null:
				continue
			for i in m.mesh.get_surface_count():
				var worn := m.get_active_material(i) as BaseMaterial3D
				if worn == null:
					continue
				seen += 1
				assert_true(worn.use_z_clip_scale, "%s surface %d pressed" % [node.name, i])
				assert_almost_eq(worn.z_clip_scale, cfg.depth_scale, 1e-6)
				var painted := hands.painted(m, i) as BaseMaterial3D
				if painted != null:
					assert_false(painted.use_z_clip_scale, "the shared paint itself is untouched (figures, menus)")
				assert_false((m.mesh.surface_get_material(i) as BaseMaterial3D).use_z_clip_scale,
						"and so is the model's own")
	assert_gt(seen, 10, "control: the replicas' surfaces were seen")


func test_a_depth_scale_of_one_draws_it_as_before() -> void:
	cfg.depth_scale = 1.0
	var c := _character()
	var hands := _hands(c)
	for node: Node in hands._held[0].root.find_children("*", "MeshInstance3D", true, false):
		var m := node as MeshInstance3D
		for i in m.mesh.get_surface_count():
			var worn := m.get_active_material(i) as BaseMaterial3D
			if worn != null:
				assert_false(worn.use_z_clip_scale)


func test_aimed_at_a_wall_the_sight_stays_at_the_eye_at_the_hip_it_pulls_back() -> void:
	var wall := BoxWorld.new()
	wall.add_box(Vector3(0.0, 1.6, -0.6), Vector3(4.0, 4.0, 0.4))
	var c := _character()
	var open := _hands(c)
	var near := _hands(c, wall)
	_frames(open, c, SETTLE)
	_frames(near, c, SETTLE)
	assert_gt(_pose(near, c).origin.z - _pose(open, c).origin.z, 0.1, "at the hip, eased back from the wall")
	c.aim_raise = 1.0
	_frames(open, c, SETTLE)
	_frames(near, c, SETTLE)
	assert_almost_eq(_pose(near, c).origin, _pose(open, c).origin, Vector3.ONE * EPS, "aimed, the sight where it was")
