class_name SquadConfig
extends Resource
## Squad orders for bot teammates (the browser game's config/squad.ts SQUAD_ORDERS, M22): where Hold here puts them.
## Part of BotConfig (bot_tuning.tres).

## Hold here: the spot the giver looks at, up to this far (m); nothing that close: each holds where it stands.
@export var hold_range: float = 40.0
## Held spots stop this far short of the wall the giver looks at (m).
@export var hold_wall_gap: float = 0.6
## Teammates holding a spot stand this far apart, across the giver's line of sight (m).
@export var hold_spacing: float = 1.4
## Close enough to the held spot to stop (m).
@export var hold_arrive: float = 0.7
## Hold here again, looking at least this far from the held spot (m), moves it; nearer cancels the order.
@export var hold_move: float = 3.0
