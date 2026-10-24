extends GutTest
## The Follow me guard's "left behind" measure (MatchRunner.judge_follower, chasing; lead ruling, DP4): beyond
## catch_up a follower that kept close to its sprint speed over the last CHASE_TICKS without the gap growing is
## chasing, not left behind; one stuck, standing, lost or slower than it could be is. No level: a leader sprinting
## along +X and a follower moved by hand, 4 s each.

const DT := MatchRunner.DT

var squad: SquadConfig = SquadConfig.new()
var sprint: float = MovementConfig.new().sprint_speed


## The tally of `seconds` with the leader sprinting along +X from `gap` m ahead of a follower moving at `velocity`
## (m/s), turned by `turn` (rad/s) each tick, judged with the window's history as MatchRunner keeps it once the window
## is full (in a match the 3 s rejoin always fills it first).
func _chase(gap: float, velocity: Vector3, turn: float = 0.0, seconds: float = 4.0) -> MatchRunner.MatchTally:
	var t := MatchRunner.MatchTally.new()
	var leader := Character.new(0, 0)
	leader.velocity = Vector3(sprint, 0.0, 0.0)
	leader.position = Vector3(gap, 0.0, 0.0)
	var follower := Character.new(1, 0)
	follower.velocity = velocity
	var at := PackedVector3Array()
	at.resize(MatchRunner.CHASE_TICKS)
	var gaps := PackedFloat32Array()
	gaps.resize(MatchRunner.CHASE_TICKS)
	gaps.fill(-1.0)
	for i in roundi(seconds / DT):
		leader.position += leader.velocity * DT
		follower.velocity = follower.velocity.rotated(Vector3.UP, turn * DT)
		follower.position += follower.velocity * DT
		var slot := i % MatchRunner.CHASE_TICKS
		var then_at := at[slot]
		var then_gap := gaps[slot]
		at[slot] = follower.position
		gaps[slot] = Vector2(leader.position.x - follower.position.x, leader.position.z - follower.position.z).length()
		if i >= MatchRunner.CHASE_TICKS:
			MatchRunner.judge_follower(t, follower, leader, true, squad, sprint, then_at, then_gap)
	return t


func test_a_follower_sprinting_after_a_sprinting_leader_is_chasing_not_left_behind() -> void:
	var t := _chase(11.0, Vector3(sprint, 0.0, 0.0))
	assert_lt(t.follow_worst, squad.catch_up, "the guard passes")
	assert_eq(t.follow_chasing, t.follow_counted, "every tick beyond catch_up is a chase")


func test_a_stuck_standing_lost_or_slow_follower_is_left_behind() -> void:
	var stuck := _chase(9.0, Vector3.ZERO)
	assert_gt(stuck.follow_worst, squad.catch_up, "stuck: the guard fails")
	assert_eq(stuck.follow_standing, stuck.follow_counted, "and it stands while the leader moves")
	var lost := _chase(9.0, Vector3(-sprint, 0.0, 0.0))
	assert_gt(lost.follow_worst, squad.catch_up, "sprinting the wrong way")
	var sideways := _chase(9.0, Vector3(0.0, 0.0, sprint))
	assert_gt(sideways.follow_worst, squad.catch_up, "sprinting across the leader's line")
	var circling := _chase(9.0, Vector3(sprint, 0.0, 0.0), 3.0)
	assert_gt(circling.follow_worst, squad.catch_up, "sprinting in circles")
	var running := _chase(9.0, Vector3(4.2, 0.0, 0.0))
	assert_gt(running.follow_worst, squad.catch_up, "running when it could sprint")


func test_within_catch_up_the_distance_always_counts() -> void:
	var t := _chase(5.0, Vector3(sprint, 0.0, 0.0), 0.0, 1.0)
	assert_almost_eq(t.follow_worst, 5.0, 0.01, "near the leader, sprinting or not, the gap is measured")
	assert_eq(t.follow_chasing, 0)
