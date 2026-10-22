class_name HudTeamMarkers
extends Control
## Teammate markers (concept `hud-feed.png`): a chevron in your team's colour over each teammate still in the field,
## seen through cover too (hollow while the level hides them), grey under a raised hand once they're out and walking
## off; gone once they reach the dead zone. Never over an enemy, never a name. One marker per character, made once;
## the line of sight is checked against the level every few frames per teammate, never all on one frame.

const SIZE := Vector2(38.0, 29.0)
const HAND := 22.0
const OUT_GREY := Color("c9d0db")

var _cfg: HudConfig = null
var _body: BodyConfig = null
var _query: WorldQuery = null
var _markers: Array[Control] = []
var _chevrons: Array[HudChevron] = []
var _hands: Array[HudHandGlyph] = []
var _hidden: PackedByteArray = PackedByteArray()
var _hit := RayHit.new()
var _frame: int = 0


func setup(cfg: HudConfig, body: BodyConfig, query: WorldQuery, count: int) -> void:
	name = "HudTeamMarkers"
	_cfg = cfg
	_body = body
	_query = query
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hidden.resize(count)
	for i in count:
		var m := VBoxContainer.new()
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		m.alignment = BoxContainer.ALIGNMENT_END
		m.add_theme_constant_override("separation", 2)
		m.visible = false
		var hand := HudHandGlyph.new(HAND, OUT_GREY)
		hand.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		m.add_child(hand)
		var chevron := HudChevron.new(SIZE, Color.WHITE)
		chevron.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		m.add_child(chevron)
		m.size = Vector2(SIZE.x, SIZE.y + HAND + 2.0)
		add_child(m)
		_markers.append(m)
		_chevrons.append(chevron)
		_hands.append(hand)


## Places the markers as `camera` sees them, for `you`'s team, `fraction` of the way from the last tick to this one;
## `watched` (whose eyes the camera is) gets none, and `show` false hides them all (the scoreboard is up).
func place(camera: Camera3D, characters: Array[Character], you: Character, watched: Character, colour: Color,
		fraction: float, show: bool) -> void:
	_frame += 1
	var eye := camera.global_position
	for i in _markers.size():
		var m := _markers[i]
		var c := characters[i] if i < characters.size() else null
		var shown := show and c != null and c.id != you.id and c.id != watched.id and c.team == you.team \
				and c.status != Character.Status.OUT
		var top := Vector3.ZERO
		if shown:
			var at := c.prev_position.lerp(c.position, fraction)
			top = at + Vector3.UP * (Character.eye_height(c.crouch_amount, _body) + _cfg.team_marker_lift)
			shown = not camera.is_position_behind(top)
		m.visible = shown
		if not shown:
			continue
		var out := not Elimination.is_in_play(c)
		var chevron := _chevrons[i]
		_hands[i].visible = out
		if (_frame + i) % maxi(1, _cfg.team_marker_check) == 0:
			_hidden[i] = 1 if _query.ray(eye, top, _hit) else 0
		chevron.colour = OUT_GREY if out else colour
		chevron.hollow = _hidden[i] == 1
		var p := camera.unproject_position(top)
		m.position = Vector2(p.x - m.size.x * 0.5, p.y - m.size.y)


## Whether character `id`'s marker shows, and hollow: for tests.
func is_shown(id: int) -> bool:
	return id < _markers.size() and _markers[id].visible


func is_hollow(id: int) -> bool:
	return is_shown(id) and _chevrons[id].hollow


func is_out(id: int) -> bool:
	return is_shown(id) and _hands[id].visible
