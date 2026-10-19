class_name BotIntentView
extends Node3D
## The Dev settings' Bot intentions: a small label over each bot in play saying what it is doing (advancing, fighting,
## in cover, searching), read from the bots' controller each frame. Built only while it is on; a label's text is set
## only when its bot's mode changes.

## Over the eyes (m), as the browser game's DEV_BOT_INTENT; the label's font size, and its size per pixel at a metre
## (it keeps one size on screen at any distance, about 25 px tall).
const ABOVE_EYES := 0.55
const FONT_SIZE := 32
const PIXEL := 0.001
const MODE_KEYS: Array[StringName] = [&"DEV_INTENT_ADVANCE", &"DEV_INTENT_FIGHT", &"DEV_INTENT_COVER",
		&"DEV_INTENT_SEARCH"]

var _bots: BotController = null
var _body: BodyConfig = null
var _labels: Array[Label3D] = []
var _ids: PackedInt32Array = PackedInt32Array()
var _shown: PackedInt32Array = PackedInt32Array()


func setup(state: GameState, bots: BotController, body: BodyConfig, player_id: int) -> void:
	name = "BotIntentView"
	_bots = bots
	_body = body
	for c in state.characters:
		if c.id == player_id or bots.mode_of(c.id) < 0:
			continue
		var l := Label3D.new()
		l.font_size = FONT_SIZE
		l.pixel_size = PIXEL
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.fixed_size = true
		l.no_depth_test = true
		l.outline_size = FONT_SIZE / 6
		add_child(l)
		_labels.append(l)
		_ids.append(c.id)
		_shown.append(-1)


func update(state: GameState, fraction: float) -> void:
	for i in _labels.size():
		var c := state.character(_ids[i])
		var l := _labels[i]
		l.visible = c != null and Elimination.is_in_play(c)
		if not l.visible:
			continue
		var mode := _bots.mode_of(c.id)
		if mode != _shown[i] and mode >= 0 and mode < MODE_KEYS.size():
			_shown[i] = mode
			l.text = tr(MODE_KEYS[mode])
		var feet := c.prev_position.lerp(c.position, fraction)
		var eye := Character.eye_height(lerpf(c.prev_crouch_amount, c.crouch_amount, fraction), _body)
		l.position = feet + Vector3(0.0, eye + ABOVE_EYES, 0.0)
