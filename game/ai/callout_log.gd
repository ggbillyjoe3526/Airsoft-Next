class_name CalloutLog
extends RefCounted
## The calls the bots said (Callouts), for the presentation to read: a fixed ring of entries made once a match and
## refilled, the oldest overwritten. Each call has a serial number, counting from 0 over the match; a reader keeps the
## serial it reads up to and asks for the ones after it (`total` is the next serial).


## One call said: who, on which team, the event (CalloutsFile.Event), the line as it reads and when (s of match time).
class Entry:
	extends RefCounted
	var speaker_id: int = -1
	var team: int = -1
	var event: CalloutsFile.Event = CalloutsFile.Event.CONTACT
	var line: String = ""
	var time: float = -INF


## Calls said so far this match (the serial the next one gets).
var total: int = 0
var _ring: Array[Entry] = []


func _init(size: int) -> void:
	for i in maxi(1, size):
		_ring.append(Entry.new())


## How many calls the ring keeps.
func capacity() -> int:
	return _ring.size()


## The call with serial `serial`, or null when it hasn't been said or the ring has overwritten it.
func entry(serial: int) -> Entry:
	if serial < 0 or serial >= total or serial < total - _ring.size():
		return null
	return _ring[serial % _ring.size()]


## The serial of the oldest call the ring still holds.
func oldest() -> int:
	return maxi(0, total - _ring.size())


## Writes a call said now into the ring's next entry.
func add(speaker_id: int, team: int, event: CalloutsFile.Event, line: String, time: float) -> void:
	var e := _ring[total % _ring.size()]
	e.speaker_id = speaker_id
	e.team = team
	e.event = event
	e.line = line
	e.time = time
	total += 1
