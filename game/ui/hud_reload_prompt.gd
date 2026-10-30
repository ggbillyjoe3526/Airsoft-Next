class_name HudReloadPrompt
extends PanelContainer
## The reload prompt under the crosshair (RL2): the Reload key's cap as bound now and RELOAD on a small plate, while
## reloads are manual (Settings › Controls › Reload) and the replica in hand waits for one (Armament.reload_due) in a
## live round, with you in play. The key's name is read each time the prompt comes up (so a rebind shows) and on
## `refresh_key`; nothing else is made after it is built.

## The words' size, the key cap's padding (px) and the gap between the cap and RELOAD (px).
const SIZE := GameTheme.SMALL_SIZE
const KEY_PAD := Vector2i(6, 1)
const KEY_GAP := 8
## The plate's padding (px).
const PAD := Vector2i(10, 4)

var _key_text: Label = null


func _init() -> void:
	name = "ReloadPrompt"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_theme_stylebox_override("panel", HudStyle.panel_box(HudStyle.BACKING_AIM, PAD.x, PAD.y))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", KEY_GAP)
	add_child(row)
	var chip := MenuParts.key_chip(KeyNames.of_action(PlayerInput.RELOAD), SIZE, GameTheme.TEXT, KEY_PAD)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_key_text = chip.get_child(0) as Label
	row.add_child(chip)
	var words := HudStyle.label(row, SIZE, 800, GameTheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT, HudStyle.SPACING_AIM)
	words.text = tr("HUD_RELOAD")
	visible = false


## Shows the prompt while `due`; coming up, it reads the Reload key as bound now.
func show_when(due: bool) -> void:
	if due and not visible:
		refresh_key()
	visible = due


## The Reload key as bound now (the settings, opened from the pause menu, may have changed it).
func refresh_key() -> void:
	_key_text.text = KeyNames.of_action(PlayerInput.RELOAD)


## The key cap's words, for tests.
func key_text() -> String:
	return _key_text.text
