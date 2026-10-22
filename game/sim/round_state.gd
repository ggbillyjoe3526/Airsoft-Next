class_name RoundState
extends RefCounted
## The match's round flow as plain data (the browser game's sim/round.ts RoundState: Elimination and Attack / Defend).
## Round writes it; the HUD reads it.

## LIVE: playing; OVER: the pause between rounds; MATCH_OVER: a team has won the match (until a new match starts).
enum Phase { LIVE, OVER, MATCH_OVER }
## ELIMINATION: a round is won by putting the other team out. ATTACK_DEFEND: also by raising the flag on the defenders'
## pole, and the time-out goes to the defenders.
enum Mode { ELIMINATION, ATTACK_DEFEND }

## The match's mode and, for Attack / Defend, the foot of its pole (map data) and the team attacking in the first half
## (it follows your team pick). Set before Round.start_match.
var mode: Mode = Mode.ELIMINATION
var pole: Vector3 = Vector3.ZERO
var first_attackers: int = 0

var phase: Phase = Phase.LIVE
## The round being played, from 1. A drawn round is played again under the same number (browser audit SIM-19).
var number: int = 1
## Rounds drawn so far this match (each replayed, so not counted in `number`).
var draws: int = 0
## Seconds left in the live round.
var clock: float = 0.0
## Seconds left before the next round starts, while OVER.
var timer: float = 0.0
## The last finished round's winning team, or -1 for a draw or none yet; and why it ended (GameEvent.RoundEnd).
var winner: int = -1
var reason: GameEvent.RoundEnd = GameEvent.RoundEnd.ELIMINATED
## Rounds won per team (0 Alpha, 1 Beta).
var score: PackedInt32Array = PackedInt32Array([0, 0])
## The team that won the match, or -1.
var match_winner: int = -1
## Attack / Defend: the team attacking this round (-1 in Elimination), the pole, and the overtime played so far (s; time
## ran out while the attackers worked the rope).
var attackers: int = -1
var flag: FlagState = FlagState.new()
var overtime: float = 0.0


func is_live() -> bool:
	return phase == Phase.LIVE


## The last finished round was a draw (both teams out at once, or the clock ran out): it is played again.
func drawn() -> bool:
	return winner != 0 and winner != 1
