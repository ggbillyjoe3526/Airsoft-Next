class_name BBTrails
extends RefCounted
## A short trail of recent positions for each BB slot in the pool: a ring buffer per slot, written once a tick, so the
## debug draw can show a shot's arc (hop-up lift, then drop). A slot's trail is cleared when its BB dies or the slot is
## given a new BB (a different serial). One flat array, allocated at construction; recording allocates nothing.

var _slots: int = 0
var _capacity: int = 0
var _points: PackedVector3Array = PackedVector3Array()
## Per slot: where the next point goes, how many points it holds, and the serial of the BB they belong to.
var _head: PackedInt32Array = PackedInt32Array()
var _count: PackedInt32Array = PackedInt32Array()
var _serial: PackedInt32Array = PackedInt32Array()


func _init(slots: int, capacity: int) -> void:
	_slots = maxi(slots, 0)
	_capacity = maxi(capacity, 2)
	_points.resize(_slots * _capacity)
	_head.resize(_slots)
	_count.resize(_slots)
	_serial.resize(_slots)


func slots() -> int:
	return _slots


func capacity() -> int:
	return _capacity


## Points held for `slot`.
func count(slot: int) -> int:
	return _count[slot]


## `slot`'s k-th point, 0 the oldest.
func point(slot: int, k: int) -> Vector3:
	var start := _head[slot] - _count[slot]
	if start < 0:
		start += _capacity
	return _points[slot * _capacity + (start + k) % _capacity]


## Adds each live BB's position to its slot's trail and clears the trail of any slot whose BB has died or been replaced.
func record(pool: BBPool) -> void:
	for i in mini(_slots, pool.bbs.size()):
		var bb := pool.bbs[i]
		if not bb.active:
			clear_slot(i)
			continue
		if bb.serial != _serial[i]:
			clear_slot(i)
			_serial[i] = bb.serial
		_points[i * _capacity + _head[i]] = bb.position
		_head[i] = (_head[i] + 1) % _capacity
		_count[i] = mini(_count[i] + 1, _capacity)


func clear_slot(slot: int) -> void:
	_count[slot] = 0
	_head[slot] = 0
	_serial[slot] = 0


func clear() -> void:
	for i in _slots:
		clear_slot(i)
