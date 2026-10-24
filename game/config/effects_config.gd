class_name EffectsConfig
extends Resource
## BBs in the air, the puffs where they land, the dust in the air and underfoot, the gas puffs and the contact shadows
## (the browser game's config/renderEffects.ts and dressing.ts). Read by BBView, PuffView, WindDust, KickedDust,
## GasPuffs and FigureView. No blood, ever: a BB leaves a puff of dust, and a hit a brighter one.

## A BB drawn this wide (m): larger than a real 6 mm BB so it reads at range.
@export var bb_size: float = 0.012
@export var bb_colour: Color = Color(1.0, 0.98, 0.92)
## A BB you fired is drawn from the muzzle, joining its true path from the eye over this long (s).
@export var muzzle_join_time: float = 0.12
## Puffs: how many can show at once, how long one lasts (s), its size at the start and end (m).
@export var puff_pool: int = 48
@export var puff_life: float = 0.35
@export var puff_start_size: float = 0.05
@export var puff_end_size: float = 0.32
## A puff's colour on each surface (RayHit.Surface order: none, concrete, metal, wood, earth, gravel, grass, leaves),
## and on a body hit. Gravel, grass and leaves puff as earth.
@export var puff_colours: PackedColorArray = PackedColorArray([
	Color(0.8, 0.78, 0.72, 0.7), Color(0.82, 0.8, 0.75, 0.7), Color(0.78, 0.8, 0.82, 0.6), Color(0.76, 0.66, 0.5, 0.7),
	Color(0.6, 0.52, 0.4, 0.75), Color(0.6, 0.52, 0.4, 0.75), Color(0.6, 0.52, 0.4, 0.75), Color(0.6, 0.52, 0.4, 0.75),
])
@export var hit_puff_colour: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var hit_puff_scale: float = 1.6
## A run into a noisy prop (PROP_KNOCK, NP1): a puff of the prop's dust (its surface's colour) where it was hit, this
## many times a BB's (the browser game's PROP_BUMP_DUST), so the knock shows from across the yard. Dust, never debris.
@export var knock_puff_scale: float = 4.0
## Dust in the air round the eye, drifting with the breeze (WindDust): how many specks, how long each lives (s), the box
## round the eye they appear in (half extents, m), their size (m) and colour, and how often (s) their drift follows the
## wind's gusts.
@export var dust_count: int = 90
@export var dust_life: float = 6.0
@export var dust_box: Vector3 = Vector3(8.0, 2.5, 8.0)
@export var dust_size: float = 0.024
@export var dust_colour: Color = Color(1.0, 0.97, 0.88, 0.45)
@export var dust_refresh: float = 0.5
## Dust in the air takes the sun's light and its shadow (WindDust): a speck glints this bright in full sun (a share of
## the light on it) and gives nothing in shade; it fades out nearer the eye than `dust_fade_far` and is gone by
## `dust_fade_near` (m), so none balloons into a blur (the browser game's DUST_MOTES).
@export var dust_glint: float = 1.0
@export var dust_fade_near: float = 0.8
@export var dust_fade_far: float = 1.8
## A gas replica's breath (GasPuffs, the browser game's GAS_PUFFS): each shot of a replica of one of `gas_powers` puffs
## a cool, short breath from its muzzle, pushed forward (`gas_muzzle_speed`, m/s), and a smaller one (`gas_port_scale`
## of its size) out of the ejection port to the right (`gas_port_speed`), `gas_port_back` of the way back from the
## muzzle to the eye. The pool holds `gas_pool` puffs (two a shot; the oldest is reused). Each lives `gas_life` s,
## growing from `gas_start_scale` of its size over `gas_grow_time` s to `gas_radius` (m), rising at `gas_drift` (m/s),
## never smaller on screen than `gas_min_angle` (radians of view across its radius), in `gas_colour`: gas, not smoke; a
## cool grey pale enough never to read as a team's hue.
@export var gas_powers: Array[StringName] = [&"gas"]
@export var gas_pool: int = 16
@export var gas_life: float = 0.35
@export var gas_grow_time: float = 0.07
@export var gas_start_scale: float = 0.0
@export var gas_radius: float = 0.045
@export var gas_min_angle: float = 0.004
@export var gas_colour: Color = Color(0.88, 0.92, 0.92, 0.45)
@export var gas_drift: float = 0.12
@export var gas_muzzle_speed: float = 1.6
@export var gas_port_scale: float = 0.45
@export var gas_port_speed: float = 0.7
@export var gas_port_back: float = 0.15
## No breath beyond `gas_range` m of the eye (a far puff's least size would cover its shooter). Through a bot's eyes
## (spectating, no replica drawn) its breath leaves from `gas_view_muzzle` (m: right, up, back in the view's space).
@export var gas_range: float = 35.0
@export var gas_view_muzzle: Vector3 = Vector3(0.12, -0.12, -0.5)
## Dust kicked up by feet (KickedDust, the browser game's KICKED_DUST): a low, faint puff at a sprinting footfall and a
## bigger one (`kick_land` times) on landing, in the map's `dressing.kickedDust` tint and size (MapData), only within
## `kick_range` m of the eye. The pool holds `kick_pool`; each lives `kick_life` s, growing from `kick_start_scale` over
## `kick_grow_time` s to `kick_radius` (m), starting `kick_lift` m over the feet and rising at `kick_drift` (m/s), at
## `kick_opacity`. Its top never passes `kick_top` m over the feet, so it never hides anyone.
@export var kick_pool: int = 24
@export var kick_life: float = 0.55
@export var kick_grow_time: float = 0.18
@export var kick_start_scale: float = 0.3
@export var kick_radius: float = 0.11
@export var kick_opacity: float = 0.4
@export var kick_drift: float = 0.1
@export var kick_land: float = 1.5
@export var kick_range: float = 35.0
@export var kick_lift: float = 0.07
@export var kick_top: float = 0.3
## How much of each light (the sun) the kicked dust takes, whichever way it faces: 1 is all of it, so it stands lighter
## than the floor, which takes the sun at a slant (KickedDust.SHADER); the sky's ambient light it takes as the floor does.
@export var kick_lit: float = 1.0
## Contact shadows (FigureView, the browser game's CONTACT_SHADOWS): where the sun casts no shadows, a soft dark disc on
## the floor under every figure, `contact_radius` m across its radius standing and `contact_crouched_radius` fully
## crouched, `contact_darkness` at its middle, `contact_middle_shade` of that `contact_middle` of the way out, lifted
## `contact_lift` m off the floor; off the ground it stays where the feet last stood, gone `contact_fade_height` m up.
@export var contact_radius: float = 0.42
@export var contact_crouched_radius: float = 0.36
@export var contact_darkness: float = 0.42
@export var contact_middle_shade: float = 0.55
@export var contact_middle: float = 0.5
@export var contact_lift: float = 0.015
@export var contact_fade_height: float = 1.5
