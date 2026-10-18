class_name SpawnPoint
extends RefCounted
## A spot on the map and the way it faces (map data): a spawn, or a dead-zone spot.

var position: Vector3 = Vector3.ZERO
var yaw: float = 0.0


func _init(at: Vector3 = Vector3.ZERO, facing: float = 0.0) -> void:
	position = at
	yaw = facing
