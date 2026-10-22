class_name MinimapConfig
extends Resource
## The minimap (the browser game's MINIMAP in config/minimap.ts, M23): top left while you play, the field round the
## character the view is through, your teammates always, and the other team only as patches where each was last heard
## (DECISIONS 2026-10-04). Pixel sizes are at 1080p before the HUD's scale. Part of play_tuning.tres.

## The panel's side (px, square: the field fills it), and the room under it for its caption ("Depot · Round 2"), gap
## included (px).
@export var size: float = 200.0
@export var caption_room: float = 32.0
## How far apart (px) the screen-edge markers pinned past the panel sit (BP5: a flag and a hold marker landed on top of
## each other): down its side, and across its top (a label's width).
@export var pin_step_down: float = 48.0
@export var pin_step_across: float = 96.0
## Metres from the panel's middle to its edge (its corners reach a little further).
@export var view_radius: float = 20.0
## Pixels per metre of the field drawing made once per match (the panel shows 40 m across 200 px, 5 px/m, so
## it stays sharp at twice that), and the longest side (px) one drawing may have: a field too big for it is drawn at a
## lower scale.
@export var layer_scale: float = 10.0
@export var max_layer_side: int = 2048

@export_group("Hearing")
## The furthest (m) a sound of each kind places an enemy: a footstep or vault as far as steps play (22 m), a shot as far
## as shots play (60 m) times the replica's heard_scale (a silencer halves it).
@export var step_reach: float = 22.0
@export var shot_reach: float = 60.0
## How long (s) a heard enemy's patch stays, fading out over the last patch_fade of them. One patch per enemy: the last
## thing they were heard doing.
@export var patch_life: float = 5.0
@export var patch_fade: float = 2.0
## How far off a patch can sit from where they really were: this share of the distance to them (footsteps place less
## well than shots), at least blur_min and at most blur_max (m).
@export var step_blur_share: float = 0.22
@export var shot_blur_share: float = 0.12
@export var blur_min: float = 1.5
@export var blur_max: float = 7.0
## A patch's radius is its blur plus this (m), so the enemy is always inside it.
@export var patch_pad: float = 1.0
## An enemy heard beyond the panel's edge shows as a patch this big (px) on the rim, towards them.
@export var rim_patch: float = 5.0

@export_group("Field drawing")
## Blocks whose top is at most this high (m) above the floor they stand on draw as low cover, taller ones as walls; a
## floor's top within floor_contact (m) of a block's bottom is the floor it stands on.
@export var low_cover_top: float = 1.3
@export var floor_contact: float = 0.05
## Floors whose top is above this (m) draw as raised ground (docks, platforms).
@export var raised_floor: float = 0.3
## On a map built in storeys (M34c): feet at most storey_pick (m) below a storey's floor already count as on it (the
## top of a stair), and a storey's drawing leaves out every block starting more than storey_cut (m) above its floor (the
## storeys over it: a body's height, so the storey's own walls and cover all show).
@export var storey_pick: float = 0.5
@export var storey_cut: float = 1.8
## The drawing's colours: ground, raised floor, ramp, low cover and tall walls; the shade laid over everything below
## the storey drawn (so the street through a stairwell reads as below you); you, and a teammate who is out. The navy
## panel under the drawing is the HUD's.
@export var ground_colour: Color = Color(Color("485058"), 0.92)
@export var raised_colour: Color = Color(Color("60686e"), 0.95)
@export var ramp_colour: Color = Color(Color("50585e"), 0.95)
@export var low_colour: Color = Color(Color("969ca0"), 0.95)
@export var tall_colour: Color = Color(Color("d6dadc"), 0.98)
@export var below_storey_colour: Color = Color(Color("080a0e"), 0.55)
@export var you_colour: Color = Color("ffffff")
@export var out_colour: Color = Color(Color("aaaaaa"), 0.8)
## The rim drawn just outside a raised floor wherever the floor beyond it is lower (none where a ramp meets it), and how
## wide (m): the browser drew Depot's dock only a shade lighter than the yard, so under a heard patch the two read alike
## (its KNOWN_ISSUES); the dark rim keeps the dock's outline plain through a patch.
@export var drop_colour: Color = Color(Color("16191e"), 0.95)
@export var drop_edge: float = 0.3
