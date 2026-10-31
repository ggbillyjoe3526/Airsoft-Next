class_name JoltQuery
extends WorldQuery
## The simulation's WorldQuery on a map's Jolt colliders (docs/ARCHITECTURE.md › Contracts 4): BB rays and what is
## underfoot, through one RayCast3D the level owns, cast on demand (force_raycast_update allocates nothing, where
## intersect_ray returns a new Dictionary a call). Each surface's blocks are one static body, so the body a ray meets
## says what it is made of; each door's leaf (DO1) is a wooden body of its own, switched on and off with the door.

## What is underfoot is looked for from max_step above the feet down to this far below them (m), so a step's landing
## a little above the floor, or a ramp's slope, still counts (the browser game's map/underfoot.ts UNDERFOOT_REACH).
const UNDERFOOT_REACH := 0.35

var _cast: RayCast3D = null
## The static body of each RayHit.Surface, by its value.
var _surface_bodies: Array[RID] = []
var _body: BodyConfig = null
var _under: RayHit = RayHit.new()
## Each door's leaf (DO1), by door: the one shape of a wooden static body of its own, disabled while the door is open.
var _door_shapes: Array[CollisionShape3D] = []
var _door_bodies: Array[RID] = []


func _init(cast: RayCast3D, surface_bodies: Array[RID], body: BodyConfig) -> void:
	_cast = cast
	_surface_bodies = surface_bodies
	_body = body


func ray(from: Vector3, to: Vector3, hit: RayHit) -> bool:
	var segment := to - from
	var length := segment.length()
	if not (length > 0.0):
		return false
	_cast.position = from
	_cast.target_position = segment
	_cast.force_raycast_update()
	if not _cast.is_colliding():
		return false
	hit.position = _cast.get_collision_point()
	hit.normal = _cast.get_collision_normal()
	hit.fraction = clampf(from.distance_to(hit.position) / length, 0.0, 1.0)
	hit.surface = _surface_of(_cast.get_collider_rid())
	return true


## Door `i`'s leaf and its body as the level built them (MapLevel), after add_door.
func set_door_shape(i: int, shape: CollisionShape3D, body: RID) -> void:
	if _door_shapes.size() <= i:
		_door_shapes.resize(i + 1)
		_door_bodies.resize(i + 1)
	_door_shapes[i] = shape
	_door_bodies[i] = body


## A shape's switch takes effect on the physics server at once, for the next ray and the next mover's sweep.
func set_door_shut(i: int, shut: bool) -> void:
	_door_shapes[i].disabled = not shut


func surface_under(feet: Vector3) -> RayHit.Surface:
	var top := feet + Vector3(0.0, _body.max_step, 0.0)
	if not ray(top, feet - Vector3(0.0, UNDERFOOT_REACH, 0.0), _under):
		return RayHit.Surface.NONE
	return _under.surface


func _surface_of(rid: RID) -> RayHit.Surface:
	for s in _surface_bodies.size():
		if _surface_bodies[s] == rid:
			return s as RayHit.Surface
	# A door's leaf is plywood.
	for b in _door_bodies:
		if b == rid:
			return RayHit.Surface.WOOD
	return RayHit.Surface.NONE
