class_name MapStyle
extends Resource
## How a map's blocks are drawn and what they are made of, by block kind (the browser game's config/materials.ts for the
## surfaces; the colours follow docs/ART.md: warm concrete and cream for the field, site colours on containers and
## plant, plywood for crates, never a team colour). Read by MapData (surfaces) and MapLevel (the greybox). A block's own
## `surface` in the map data wins over its kind's.

## What a BB or a footstep meets on each kind (RayHit.Surface). Moulded plastic ticks hollow, nearest to wood; sand-filled
## bags and gabions soak BBs up like wood. Kinds not listed are concrete.
@export var surfaces: Dictionary[StringName, int] = {
	&"floor": RayHit.Surface.CONCRETE,
	&"ramp": RayHit.Surface.CONCRETE,
	&"wall": RayHit.Surface.CONCRETE,
	&"barrier": RayHit.Surface.CONCRETE,
	&"crate": RayHit.Surface.WOOD,
	&"container": RayHit.Surface.METAL,
	&"toilet": RayHit.Surface.WOOD,
	&"rack": RayHit.Surface.WOOD,
	&"gabion": RayHit.Surface.WOOD,
	&"wrapped": RayHit.Surface.WOOD,
	&"ibc": RayHit.Surface.METAL,
	&"sandbags": RayHit.Surface.WOOD,
	&"generator": RayHit.Surface.METAL,
	&"skip": RayHit.Surface.METAL,
}
## Each kind's greybox colour (sRGB). Kinds not listed take `default_colour`.
@export var colours: Dictionary[StringName, Color] = {
	&"floor": Color(0.63, 0.61, 0.57),
	&"ramp": Color(0.56, 0.57, 0.58),
	&"wall": Color(0.82, 0.78, 0.70),
	&"barrier": Color(0.74, 0.72, 0.67),
	&"crate": Color(0.72, 0.65, 0.47),
	&"toilet": Color(0.32, 0.55, 0.40),
	&"rack": Color(0.54, 0.49, 0.36),
	&"gabion": Color(0.56, 0.55, 0.51),
	&"wrapped": Color(0.86, 0.86, 0.83),
	&"ibc": Color(0.89, 0.89, 0.85),
	&"sandbags": Color(0.71, 0.64, 0.47),
	&"generator": Color(0.81, 0.70, 0.20),
	&"skip": Color(0.81, 0.70, 0.20),
}
## Containers take the site colours in turn (bottle green, mustard, slate, teal), so a row of them never reads as one.
@export var container_colours: Array[Color] = [
	Color(0.22, 0.40, 0.29), Color(0.79, 0.68, 0.19), Color(0.37, 0.43, 0.49), Color(0.18, 0.48, 0.48),
]
@export var default_colour: Color = Color(0.7, 0.7, 0.7)
## The ground beyond the field's walls, out to `ground_extent` metres each way from the middle, just below the floor.
@export var ground_colour: Color = Color(0.47, 0.49, 0.34)
@export var ground_extent: float = 120.0
@export var ground_drop: float = 0.02
## Greybox roughness, and the floor grid: one darker line every `grid_size` metres, `grid_shade` of the colour.
@export var roughness: float = 0.85
@export var grid_size: float = 1.0
@export var grid_shade: float = 0.86


## What blocks of `kind` are made of.
func surface_of(kind: StringName) -> RayHit.Surface:
	return surfaces.get(kind, RayHit.Surface.CONCRETE) as RayHit.Surface


## The colour of the `index`-th block of `kind` on its map.
func colour_of(kind: StringName, index: int) -> Color:
	if kind == &"container" and not container_colours.is_empty():
		return container_colours[index % container_colours.size()]
	return colours.get(kind, default_colour)
