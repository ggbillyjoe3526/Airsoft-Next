class_name OvertimeConfig
extends Resource
## Elimination's overtime flag (the browser game's config/modes.ts OVERTIME, OT1): a round whose clock runs out with
## both teams in play puts a flag up at the map's spot, and the first team to touch it wins the round. Read by
## game/sim/overtime_flag.gd and round.gd.

## Seconds the flag stands untouched before the round is a draw, played again: long enough for either end to run to a
## spot near the middle and fight over it.
@export var time: float = 30.0
## A player in play within this distance of the flag's foot (m, flat) has a hand on it: a touch, no hold.
@export var reach: float = 1.0
## ... with its feet within this height of the foot (m): a hand from the floor above or below doesn't count.
@export var reach_height: float = 1.0
