# game/ai

The bots: plain data and static functions, no `Node` (docs/ARCHITECTURE.md › Contracts 1). A bot is just another
controller: each tick it writes the same `PlayerCommand` the player's input fills, and the simulation plays it by the
same rules. Rewritten from the browser game's `legacy/browser/src/ai/` (Elimination's part). Tuning is `BotConfig` and
its `BotSkill` (`game/config/bot_tuning.tres`).

## What a bot knows

Only what it could: who it sees (a 120° view, 40 m, through no wall, BB or body of someone already out), anyone within
2.5 m, and what it hears (gunfire, running and sprinting feet, landings, vaults, a hit called; walls muffle it; a heard
spot is a guess off by a little). Walking and moving crouched are silent. It never reads a position it hasn't
perceived. It reacts after a reaction time per new contact, its aim error settles over a second and wanders, and it
fires in bursts only on aim, never with a teammate (or someone out) in the line of fire, a miss's flight past the target
included. Hit calls are the simulation's: a bot that is hit calls it like anyone.

## How it plays

Each round the `RoundPlanner` gives each team a plan (split over the map's lanes, a pair on one, or all stacked) and
each bot a lane to walk from its end, holding at its points and keeping with its team; past the lane it hunts the
sectors its team checked longest ago. In sight of an enemy it fights (strafing), or first gets behind close crouch cover
and peeks over it, or round a tall corner by leaning. Shot at, reloading or empty, it takes cover. With the enemy gone
it searches where it was last seen or heard, sometimes flanking.

| File | What |
|---|---|
| `bot_controller.gd` | `BotController`: owns the bots; before each step one route search, then each bot's command; after it, hearing and the round's plan |
| `bot_world.gd` | `BotWorld`: what every bot thinks with (tuning, rays, nav grid, lanes, cover, everyone, the plan, the time, each team's hunt memory) |
| `bot.gd` | `Bot`: one bot's own state (mode, contacts, aim, route, lane, cover, timers) and its seeded stream |
| `bot_brain.gd` | The tick: look, pick a mode (advance, fight, cover, search), move, aim, fire, reload |
| `bot_senses.gd`, `bot_hearing.gd` | Sight (view cone, walls, bodies, which part shows) and hearing (gunfire, feet, hit calls, near misses) |
| `bot_aim.gd`, `bot_combat.gd` | Turning, aim error that settles, lead; bursts, line-of-fire checks, reloads |
| `bot_holster.gd` | Holstering on a long, calm sprint through its own half, drawing again on a threat |
| `bot_cover.gd` | Crouch cover and lean spots at tall corners that hide a bot from a threat |
| `bot_movement.gd`, `bot_routes.gd` | Lanes, holds, hunting, searching, strafing, keeping apart; following nav routes |
| `round_planner.gd` | Each round's team plans and lanes, and hunt spots from the team's memory |

Nothing allocates per tick once warm. Route searches (`NavGrid.find_route`) are queued, one a tick, shared with walk-off
routes.

## Not yet

One skill (Normal), no names or personalities, no callouts or squad orders, no trades or magazine sharing, bots don't
vault (docs/KNOWN_ISSUES.md).
