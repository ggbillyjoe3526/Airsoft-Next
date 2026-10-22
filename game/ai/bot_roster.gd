class_name BotRoster
## Who the bots are this match (the browser game's ai/botRoster.ts): each bot draws a name from bots.md's roster and plays
## the personality that name always plays. A team's bots take different personalities while there are enough (then
## round again), so a team is a mix; no name comes twice in a match. Seeded by the match on a stream of its own
## (Seeds.roster_seed), so a seed replays the same names and no other roll moves. Pure.


## A bot's name and the personality it plays.
class Identity:
	extends RefCounted
	var bot_name: String = ""
	var personality: StringName = &""
	var style: BotsFile.Style = null


## An identity for each bot (`ids[i]` on team `teams[i]`, players left out by the caller) in a match seeded
## `seed_value`, from `file`. A bot gets none once the roster has run out of names: it plays its difficulty as it is.
static func draw(seed_value: int, ids: PackedInt32Array, teams: PackedInt32Array, file: BotsFile) \
		-> Dictionary[int, Identity]:
	var out: Dictionary[int, Identity] = {}
	var rng := Seeds.stream(Seeds.roster_seed(seed_value))
	# The personalities somebody on the roster plays, in the file's order, so a seed's draw follows the file.
	var kinds: Array[StringName] = []
	for k in file.kinds:
		for e in file.roster:
			if e.personality == k:
				kinds.append(k)
				break
	if kinds.is_empty():
		return out
	var free: Array[BotsFile.Entry] = file.roster.duplicate()
	var deal: Array[StringName] = []
	var pool: Array[BotsFile.Entry] = []
	for team in 2:
		var members: Array[int] = []
		for i in ids.size():
			if teams[i] == team:
				members.append(ids[i])
		members.sort()
		deal.clear()
		for id in members:
			if deal.is_empty():
				deal.assign(kinds)
				_shuffle(deal, rng)
			var kind: StringName = deal.pop_back()
			# A name of that personality, or failing that any name left (it plays its own).
			pool.clear()
			for e in free:
				if e.personality == kind:
					pool.append(e)
			if pool.is_empty():
				pool.assign(free)
			if pool.is_empty():
				break
			var entry := pool[_below(rng, pool.size())]
			free.erase(entry)
			var who := Identity.new()
			who.bot_name = entry.bot_name
			who.personality = entry.personality
			who.style = file.style(entry.personality)
			out[id] = who
	return out


## A draw below `n`.
static func _below(rng: RandomNumberGenerator, n: int) -> int:
	return mini(n - 1, floori(rng.randf() * n))


## `list` shuffled in place (Fisher-Yates).
static func _shuffle(list: Array[StringName], rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := _below(rng, i + 1)
		var t := list[i]
		list[i] = list[j]
		list[j] = t
