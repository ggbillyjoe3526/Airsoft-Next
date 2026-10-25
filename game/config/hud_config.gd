class_name HudConfig
extends Resource
## The heads-up display's sizes and timings. Read by Hud; colours are GameTheme's palette and TeamConfig's teams (HudStyle).

## The magazine count warns at or below this share of a full magazine.
@export var low_mag_share: float = 0.25
## The magazine boxes (px): each one's width and height, its outline, the space between the outline and the fill, the
## gap between spares and the gap after the loaded magazine (the concept's `.mags`: 11 by 18, 6 apart).
@export var gauge_width: float = 11.0
@export var gauge_height: float = 18.0
@export var gauge_line: float = 1.5
@export var gauge_inset: float = 0.0
@export var gauge_gap: float = 6.0
@export var gauge_loaded_gap: float = 10.0
## The hit marker on your hit: its strokes' length and width (px, before the player's size) and how long it shows (s).
@export var marker_size: float = 12.0
@export var marker_width: float = 3.0
@export var marker_time: float = 0.35
## The hop-up readout shows this long (s) after the last turn of the dial; a BB counts as flat while it stays within
## hop_band (m) of the aim line, followed at most hop_range (m).
@export var hop_show_time: float = 1.8
## "Space to vault" under the crosshair while a Jump press would vault, kept up this long after (s), this far below the
## centre (px).
@export var vault_prompt_hold: float = 0.15
@export var vault_prompt_drop: float = 56.0
## "Leaves in the way · step clear to shoot" under the vault prompt when a bush's leaves stop your own BB within
## leaves_notice_near (m) of your eyes (WL5, FO1): you're in or right behind one, which hides you but stops your shots.
## Up this long (s).
@export var leaves_notice_near: float = 2.0
@export var leaves_notice_time: float = 1.4
@export var hop_band: float = 0.15
@export var hop_range: float = 60.0
## A ricochet that ticks you (when ricochets don't count) says so this long (s).
@export var ricochet_time: float = 1.5
## A round's banner shows this long (s).
@export var banner_time: float = 2.5
## Attack / Defend (concepts `hud-attack.png`, `hud-defend.png`; the gauge's notches are the rope's ratchet steps): the
## marker over the pole, this high over its foot (m), hidden within this distance (m) and kept this far inside the
## screen's edges (px); and the warning that the other team's flag is going up, pulsing this many times a second.
@export var flag_marker_height: float = 3.7
@export var flag_marker_hide_within: float = 5.0
@export var flag_marker_edge: float = 36.0
@export var flag_warning_pulse: float = 1.6
## The hit feed (concept `hud-feed.png`; the browser game's HIT_FEED): at most feed_lines lines, each up feed_line_time
## (s, simulation time, so a pause holds it), fading over its last feed_fade_time; kept feed_margin from the screen's
## corner (px: x from the side, y from the top or the bottom), feed_gap (px) between lines. A feed in the bottom left
## keeps feed_card_gap (px) clear under What got you (and under a flag plate pinned there), showing fewer lines to do it.
@export var feed_lines: int = 6
@export var feed_line_time: float = 6.0
@export var feed_fade_time: float = 1.0
@export var feed_margin: Vector2 = Vector2(32.0, 26.0)
@export var feed_gap: float = 6.0
@export var feed_card_gap: float = 18.0
## Teammate markers: a chevron this far over a teammate's eye (m), hollow while cover hides them; checked against the
## level every team_marker_check frames for each teammate.
@export var team_marker_lift: float = 0.55
@export var team_marker_check: int = 4
## The round's table (concept `round-result.png`): table_delay (s of simulation time) after a round ends it slides table_slide_px up into
## place over table_slide (s) and stays until the next round; after the match's last round it holds table_hold (s) more
## unless a click closes it sooner.
@export var table_delay: float = 2.0
@export var table_hold: float = 4.0
@export var table_slide: float = 0.25
@export var table_slide_px: float = 24.0
## The scoreboard: when only the match's numbers moved (each BB fired moves them), it refills at most this often (s of
## simulation time); a new round, the clock's second or someone going out refills it at once.
@export var board_refill_gap: float = 0.25
## Squad orders (concepts `step17-orders/`). The order wheel round the crosshair: its ring runs from wheel_inner to
## wheel_outer (px from the middle) with wheel_gap between slices, each slice's words wheel_label_radius out, and the
## pointer drawn no further than wheel_pointer_reach; a notice in its middle shows order_notice_time (s), and an order
## picked on the wheel (which shuts as it is picked) waits up to order_notice_wait (s) for its answer's notice.
@export var wheel_inner: float = 120.0
@export var wheel_outer: float = 340.0
@export var wheel_gap: float = 3.0
@export var wheel_label_radius: float = 232.0
@export var wheel_pointer_reach: float = 300.0
@export var order_notice_time: float = 2.0
@export var order_notice_wait: float = 0.5
## Hold here's marker: this high over the held spots' middle (m), kept this far inside the screen's edge (px) and this
## far (px) clear of the flag marker when both are pinned; and the ring on the floor round the spot, this far out (m).
@export var hold_marker_height: float = 1.2
@export var hold_marker_edge: float = 36.0
@export var hold_marker_gap: float = 16.0
@export var hold_ring_radius: float = 1.2
## The minimap's corner: kept minimap_margin from the screen's top left (px; the feed's margin on the other side).
@export var minimap_margin: Vector2 = Vector2(32.0, 26.0)
