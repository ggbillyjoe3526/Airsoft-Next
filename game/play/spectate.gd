class_name Spectate
## Who the Dev settings' Spectate any bot follows: any character in play but you, on either team, in turn. Pure.


## The next character in play after `after_id` (in roster order, wrapping round), never `player_id`; -1 if nobody is.
## An `after_id` of -1 starts from the first.
static func next_bot(characters: Array[Character], after_id: int, player_id: int) -> int:
	var n := characters.size()
	var start := 0
	for i in n:
		if characters[i].id == after_id:
			start = i + 1
			break
	for k in n:
		var c := characters[(start + k) % n]
		if c.id != player_id and Elimination.is_in_play(c):
			return c.id
	return -1
