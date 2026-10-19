class_name DevCheats
extends RefCounted
## The Dev settings that change play (the browser game's config/dev.ts devCheating), as the simulation takes them. A
## match played with any of them on is kept out of the records for the rest of that match (docs/DECISIONS.md › Content
## tags and dev content): `GameState.off_record`. Ghost and bottomless magazines are the player's own, written onto
## their character; the bots' controller reads `bots_hold_fire`; the play loop reads `game_speed`.

const SPEED_MIN := 0.25
const SPEED_MAX := 2.0

## Simulated time per real second (1: as normal); the simulation still steps a fixed 60 Hz tick.
var game_speed: float = 1.0
var bottomless: bool = false
var ghost: bool = false
var bots_hold_fire: bool = false
## A cheat that only changes what you see or follow (spectate any bot, bot intentions): no rule changes, but the
## match still stays out of the records.
var watching: bool = false
## Disable levelling: every item unlocked to carry, so the match gives no XP (the loadout reads it, not the rules).
var levelling_off: bool = false


## Any cheat on.
func any() -> bool:
	return game_speed != 1.0 or bottomless or ghost or bots_hold_fire or watching or levelling_off


## Puts `cheats` into `state` (a copy is kept): the player `player_id`'s ghost and bottomless magazines, the rest read
## from `state.cheats`; and a cheat on now marks the match off the record.
static func apply(state: GameState, cheats: DevCheats, player_id: int) -> void:
	var kept := state.cheats
	kept.game_speed = clampf(cheats.game_speed, SPEED_MIN, SPEED_MAX)
	kept.bottomless = cheats.bottomless
	kept.ghost = cheats.ghost
	kept.bots_hold_fire = cheats.bots_hold_fire
	kept.watching = cheats.watching
	kept.levelling_off = cheats.levelling_off
	for c in state.characters:
		var mine := c.id == player_id
		c.ghost = mine and kept.ghost
		c.armament.bottomless = mine and kept.bottomless
	if kept.any():
		state.off_record = true


## The Dev tab's End the round now: the live round's clock runs out (Round.run_clock_out) and the match stays out of the
## records. False when no round is live.
static func end_round(state: GameState) -> bool:
	if not Round.run_clock_out(state.round_state):
		return false
	state.off_record = true
	return true
