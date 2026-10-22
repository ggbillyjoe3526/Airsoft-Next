class_name RangeViewConfig
extends Resource
## The practice range as drawn (the browser game's RANGE_VISUALS in config/range.ts, M21 and M93): the steel plates, the
## plywood figures and the moving targets' gear in greybox, the timed challenge's lit glow and START plate, and the
## floor lines and wall boards marking the distances. Read by RangeTargetsView and RangeView. Sizes the simulation tests
## BBs against (a plate's radius, its post, a swinger's frame, a figure's hit volume) are RangeConfig's and HitConfig's;
## these only say how they look.

## Steel plates, painted white as at most ranges so they read at 60 m: colour, metal and roughness, the disc's
## thickness (m) and sides. Posts, hangers and the moving targets' gear in a dark grey.
@export var steel_colour: Color = Color("e6e1d3")
@export var steel_metallic: float = 0.15
@export var steel_roughness: float = 0.55
@export var plate_thickness: float = 0.025
@export var plate_segments: int = 24
@export var post_colour: Color = Color("4b5157")
@export var post_roughness: float = 0.7
## A plate that's hit swings back on its hanger and settles: the swing's size (rad), its wobble (rad/s) and how fast it
## dies away (1/s). It is still again once the swing is below swing_still of its size.
@export var swing_angle: float = 0.35
@export var swing_rate: float = 16.0
@export var swing_damping: float = 5.0
@export var swing_still: float = 0.01
## Plywood figures: colour, roughness, the board's thickness and width (m). The board runs from the hit volume's feet
## to its body's top, the head a disc of the hit volume's head size, so what you see is what a BB hits.
@export var figure_colour: Color = Color("b89466")
@export var figure_roughness: float = 0.9
@export var figure_thickness: float = 0.03
@export var figure_width: float = 0.42
## A figure that's hit falls back on its hinge over fall_time (s) to down_angle (rad, a little short of flat, as on a
## hinged stand), and stands up again over RangeConfig.rise_time at the end of its time down.
@export var fall_time: float = 0.18
@export var down_angle: float = 1.45
## The timed challenge's lit targets: painted this colour and glowing, so a lit plate or figure stands out from the rest
## at any distance. Redder and brighter than the browser game's (ff7a1a, 0.6): under the sun and AgX tone mapping its
## orange washed out to the plywood's tan.
@export var lit_colour: Color = Color("ff4d0a")
@export var lit_glow: float = 1.2
@export var lit_roughness: float = 0.6
## Moving targets' gear (m): a mover's two rails (rail wide and high, rail_gauge apart, a stop block of stop_size's
## width and height at each end) and its trolley (trolley_size: width along the track, depth); a pop-up's motor box
## (popup_box) popup_gap beside its hinge; a swinger's arm (arm thick).
@export var rail: float = 0.04
@export var rail_gauge: float = 0.3
@export var stop_size: Vector2 = Vector2(0.08, 0.1)
@export var trolley_size: Vector2 = Vector2(0.5, 0.42)
@export var popup_box: Vector3 = Vector3(0.2, 0.16, 0.24)
@export var popup_gap: float = 0.03
@export var arm: float = 0.035
## The START plate: safety orange with the word in white, so it reads from the line; the word's height as a share of
## the plate's diameter, and how far (m) it stands proud of the paint.
@export var start_paint: Color = Color("f07a22")
@export var start_ink: Color = Color.WHITE
@export var start_roughness: float = 0.6
@export var start_text_share: float = 0.26
@export var start_text_lift: float = 0.002
## Painted lines across the floor at each marked distance (RangeConfig.distances): colour, depth along the range (m) and
## height over the floor (m). Safety yellow, not the browser game's off-white: the greybox floor is pale concrete, which
## white paint vanishes on.
@export var line_colour: Color = Color("e0b52e")
@export var line_depth: float = 0.12
@export var line_lift: float = 0.004
## The boards on both walls saying how far: size (m), the board's middle over the floor (m), how far its edge stands off
## the wall (m), and how far it is turned from the wall towards the firing line (rad) so it reads from there; the
## board's colour and the figures', their height as a share of the board's and how far (m) they stand proud of it.
@export var sign_size: Vector2 = Vector2(1.2, 0.6)
@export var sign_lift: float = 1.6
@export var sign_wall_gap: float = 0.1
@export var sign_turn: float = 0.35
@export var sign_thickness: float = 0.03
@export var sign_colour: Color = Color("e8e4d8")
@export var sign_ink: Color = Color("22262a")
@export var sign_text_share: float = 0.6
@export var sign_text_lift: float = 0.002
## The floor lines' and boards' paint: matt.
@export var mark_roughness: float = 0.9
## Painted words (the boards' distances, START) are drawn at this font size, then scaled to their height.
@export var text_font_size: int = 96
