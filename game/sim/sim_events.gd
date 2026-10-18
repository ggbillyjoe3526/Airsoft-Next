class_name SimEvents
extends RefCounted
## The tick's events (GameEvent): a pool that grows to the busiest tick seen and is reused, so a tick allocates nothing
## once warm. Read items[0 .. count) after a step; the next step clears them.

var items: Array[GameEvent] = []
var count: int = 0


func clear() -> void:
	count = 0


## A fresh event of `kind`, appended to this tick's.
func add(kind: GameEvent.Kind) -> GameEvent:
	if count == items.size():
		items.append(GameEvent.new())
	var e := items[count]
	count += 1
	e.reset(kind)
	return e


## How many of this tick's events are of `kind` (for tests and tools).
func count_of(kind: GameEvent.Kind) -> int:
	var n := 0
	for i in count:
		if items[i].kind == kind:
			n += 1
	return n


## The first of this tick's events of `kind`, or null.
func first(kind: GameEvent.Kind) -> GameEvent:
	for i in count:
		if items[i].kind == kind:
			return items[i]
	return null
