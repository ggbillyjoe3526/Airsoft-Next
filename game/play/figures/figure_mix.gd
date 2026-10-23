class_name FigureMix
extends RefCounted
## Who is drawn as a robot (the browser's G7 mix): with robots on, half of each team's figures are robots (an odd
## team's extra one by a coin), picked from the match seed XOR FigureConfig.robot_salt on a generator of its own, so no
## gameplay stream (bot kits, names, wind, the rules) moves; off, everyone is human. The player gets a kind too, for the
## first-person arms (FI6). Presentation only: a robot is hit, seen and heard as a human is.

## A figure's kind: its index in FigureConfig.kinds.
const HUMAN := 0
const ROBOT := 1


## The kind of each character, by its index in `teams` (each character's team), for a match seeded with `match_seed`.
static func pick(match_seed: int, teams: PackedInt32Array, robots: bool, salt: int) -> PackedInt32Array:
	var kinds := PackedInt32Array()
	kinds.resize(teams.size())
	kinds.fill(HUMAN)
	if not robots:
		return kinds
	var rng := Seeds.stream(match_seed ^ salt)
	var team_ids := PackedInt32Array()
	for team in teams:
		if not team_ids.has(team):
			team_ids.append(team)
	team_ids.sort()
	var members := PackedInt32Array()
	for team in team_ids:
		members.clear()
		for i in teams.size():
			if teams[i] == team:
				members.append(i)
		var count := int(members.size() / 2.0)
		if members.size() % 2 == 1 and rng.randi_range(0, 1) == 1:
			count += 1
		# The first `count` of the team, shuffled (Fisher-Yates), are robots.
		for i in range(members.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var held := members[i]
			members[i] = members[j]
			members[j] = held
		for i in count:
			kinds[members[i]] = ROBOT
	return kinds
