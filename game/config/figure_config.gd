class_name FigureConfig
extends Resource
## The rigged figures as drawn (step 23; the browser game's config/figureRig.ts and config/look.ts): which files, which
## head a human wears, where the levels of detail change, the team paint and who is drawn as a robot. Read by
## FigureModels, FigureBody and FigureMix. Presentation only: none of it moves a hit, a sight line or a roll.

## Where the figures live: `<models_dir><kind>.glb` and its sidecar `<models_dir><kind>.json`, one pair a kind, in the
## kinds' order (FigureMix.HUMAN, FigureMix.ROBOT).
@export var models_dir: String = "res://assets/models/characters/"
@export var kinds: PackedStringArray = PackedStringArray(["human", "robot"])
## The human's heads in the browser game's order: figure `id` wears heads[id % heads.size()] (the owner's RM9 ruling).
## A kind with none of these (the robot) keeps the head it has.
@export var heads: PackedStringArray = PackedStringArray(["Head_HighCut", "Head_Cap", "Head_Boonie", "Head_FullCut"])
## A part's coarser levels are separate meshes named `<part><lod_suffix><level>` (Body_LOD1, Body_LOD2).
@export var lod_suffix: String = "_LOD"
## Distances (m) beyond which a figure draws its LOD1 and its LOD2 meshes: on Mesh detail High and Ultra, and on Low
## and Medium (Medium is Low since the browser's BD1), each line crossed only `lod_margin` past it so a figure standing
## on one doesn't flicker.
@export var lod_high: Vector2 = Vector2(12.0, 28.0)
@export var lod_low: Vector2 = Vector2(6.0, 16.0)
@export var lod_margin: float = 0.5
## The level the shadow twin is made from: one cheap shadow a figure at every range (BD1).
@export var shadow_level: int = 2
## Materials whose name starts with this (any case) are painted in the team's colour (Team, TeamColour, TeamPaint,
## TeamGlow); every other material stays as modelled.
@export var team_material_prefix: String = "team"
## The files face +Z, the figures -Z: the model is turned this far about +Y (radians).
@export var model_yaw: float = PI
## The clip a figure stands in until it is animated (FI2).
@export var idle_clip: StringName = &"Idle"
## The bones the figure code reads, each looked up by name (the two files order them differently).
@export var bones: PackedStringArray = PackedStringArray(["Hips", "Spine", "Chest", "Head", "Grip_R", "Hand_L"])
## Robots (Settings › Looks › Robots, Mixed by default as the browser's) are picked from the match seed XOR this salt so
## no gameplay stream moves (the browser's ROBOT_SEED_SALT).
@export var robot_salt: int = 0x5f3759df


## The two lines (m) for the Mesh detail drawn.
func lod_lines(detail: GraphicsQuality.MeshDetail) -> Vector2:
	if detail == GraphicsQuality.MeshDetail.HIGH or detail == GraphicsQuality.MeshDetail.ULTRA:
		return lod_high
	return lod_low
