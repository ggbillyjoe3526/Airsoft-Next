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
## The legs' clips (FI2): standing still, the gait clips by the way each steps (x to the figure's right, y ahead; placed
## at the pace the sidecar gives it: walk 2.3, run 4.2, sprint 6.3 m/s), crouched still and walking, the jump, the
## vault, the hit call and the walk-off.
@export var idle_clip: StringName = &"Idle"
@export var gait_clips: PackedStringArray = PackedStringArray(["Walk_F", "Run_F", "Run_B", "Run_L", "Run_R", "Sprint"])
@export var gait_ways: PackedVector2Array = PackedVector2Array([Vector2(0.0, 1.0), Vector2(0.0, 1.0),
		Vector2(0.0, -1.0), Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0)])
@export var crouch_idle_clip: StringName = &"CrouchIdle"
@export var crouch_walk_clip: StringName = &"CrouchWalk"
@export var jump_clip: StringName = &"Jump"
@export var vault_clip: StringName = &"Vault"
@export var call_clip: StringName = &"HitCall"
@export var walk_off_clip: StringName = &"WalkOff"
## The leg whose swing keeps step with the hit volume's left leg: the line from `swing_hip` to `swing_ankle`, measured
## at `swing_samples` points of each stepping clip at load; the sample furthest forward meets Hitbox's forward peak.
@export var swing_hip: StringName = &"Thigh_L"
@export var swing_ankle: StringName = &"Foot_L"
@export var swing_samples: int = 60
## A crouched step goes backwards (the crouched walk, made walking ahead, played in reverse) when its backward part is
## more than `back_share` of its speed and the crouch more than `back_crouched` of the way down (the browser's
## FIGURE_RIG.backStep).
@export var back_share: float = 0.1
@export var back_crouched: float = 0.5
## The Jump clip's span (s) played over the time in the air: the take-off skipped, the landing the clip's.
@export var jump_from: float = 0.25
@export var jump_to: float = 0.55
## The Vault clip's share played over the rise onto the top; the rest across it (the browser's FIGURE_RIG.vault.top).
@export var vault_top: float = 0.4
## How fast each blend settles (s to about two thirds of the way, 1 - 1/e): standing and moving, the step's way, the
## hit call and the walk-off, a jump, a vault (the browser's FIGURE_RIG.blend).
@export var settle_move: float = 0.12
@export var settle_direction: float = 0.1
@export var settle_mode: float = 0.12
@export var settle_jump: float = 0.06
@export var settle_vault: float = 0.03
## The head's top above the Head bone, along it (m), and the highest a fully crouched head's top is drawn (m; crouch
## cover is 1.2 m, DECISIONS 2026-09-30). Between standing and crouched the line runs from the standing hit top.
@export var head_top: float = 0.24
## The bones FigureBend moves: the pelvis it lowers, the first of the upper chain it leans, the head it measures.
@export var hips_bone: StringName = &"Hips"
@export var lean_bone: StringName = &"Spine"
@export var head_bone: StringName = &"Head"
@export var crouch_top_max: float = 1.15
## The hit flinch (FI5; the browser game's CHARACTERS.flinch): on a hit the upper body jolts the way the BB flew,
## `flinch_lean` radians about the hip pivot (FigureBend; the capsules' upper body), in over `flinch_rise` seconds and
## eased back over `flinch_time`, while the hand goes up for the call.
@export var flinch_lean: float = 0.32
@export var flinch_rise: float = 0.05
@export var flinch_time: float = 0.4
## Beyond the far line (LOD2) a figure's legs are posed every `far_stride`-th frame with the time gathered (0: held
## still out there); a hidden figure's not at all.
@export var far_stride: int = 4
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
