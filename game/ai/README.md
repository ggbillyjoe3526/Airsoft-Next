# game/ai

The bots: plain data and static functions, no `Node` (docs/ARCHITECTURE.md › Contracts 1). A bot is just another
controller: each tick it writes the same `PlayerCommand` the player's input fills, and the simulation plays it by the
same rules. Rewritten from the browser game's `legacy/browser/src/ai/` (Elimination and Attack / Defend). Tuning is `BotConfig`
and its `BotSkill` (`game/config/bot_tuning.tres`).

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

In Attack / Defend (`BotFlag`) the attackers walk their lanes just past the middle, then make for the pole: the nearest
raises the flag, crouched at the rope, while the others guard it from crouch cover near by. The defenders hold their
lane's first or second point, go after only what they see or hear near the pole, and the two nearest pull the flag down
once it is off the bottom. Two defenders at one point stand side by side, or, playing as a team (Pro), in a crossfire
on the lane's next point.

Each team plays at its level (`BotConfig.skill_for`: Easy, Normal, Hard, Pro). Pro is careful, not twitchier: holding,
it aims at the corners someone would step out of (`BotAngles`) and answers someone appearing there sooner; near the
enemy it walks and slices corners, leaning past a near one; it watches where someone ducked out before going after them,
and with a threat in mind tops up only from cover. It plays as a team: it goes to trade a teammate it heard call a hit,
tells its teammates where it heard someone, moves along a lane in pairs (one waits while its partner moves) and pushes
late when its team is behind.

A teammate in play can order its bot teammates (`SquadOrders`, M22): the order travels as the giver's command, the
simulation turns it into an event, and the controller's `SquadOrderBook` hands it out. An ordered bot still fights
whoever it sees; the order replaces only where it goes between fights (before the pole, noises and the lane), it is
never picked for the pole, nobody waits for it and its personality stands aside. Follow me keeps each a spot behind the
giver's heading (pairs either side, rows back, on the giver's side of walls and level), at the giver's pace, a pace
faster or slower to close on it and sprinting when far behind, covering the giver's back once there. Hold here sends
them to the spot the giver looks at, side by side across their view, looking their way. Regroup sprints them back, each
turning to Follow me once close. The order in force given again cancels it (from the order wheel it stays), Team plan
ends it, and it ends when its giver is out and at each round start. Back on the plan, in Elimination the bot hunts from
where it stands; in Attack / Defend it takes up its post.

Every bot has a name and personality from `data/bots.md` (`BotsFile`), drawn on the match's seed (`BotRoster`): a
rusher pushes in and never waits, an anchor holds its lane short of the middle until late and aims from cover, a flanker
takes a lane of its own and flanks more, a careful bot walks and clears corners. A personality changes how a bot plays
at its level, never how well (`BotPersonality`).

| File | What |
|---|---|
| `bot_controller.gd` | `BotController`: owns the bots; before each step one route search, then each bot's command; after it, hearing and the round's plan |
| `bot_world.gd` | `BotWorld`: what every bot thinks with (tuning, rays, nav grid, lanes, cover, everyone, the plan, the time, each team's hunt memory) |
| `bot.gd` | `Bot`: one bot's own state (mode, contacts, aim, route, lane, cover, timers) and its seeded stream |
| `bot_brain.gd` | The tick: look, pick a mode (advance, fight, cover, search, flag, order), move, aim, fire, reload |
| `bot_senses.gd`, `bot_hearing.gd` | Sight (view cone, walls, bodies, which part shows) and hearing (gunfire, feet, hit calls, near misses; walls judged by `SoundPath`) |
| `bot_aim.gd`, `bot_combat.gd` | Turning, aim error that settles, lead; bursts, line-of-fire checks, reloads |
| `bot_holster.gd` | Holstering on a long, calm sprint through its own half, drawing again on a threat |
| `bot_angles.gd` | Held angles: the corners and doorways in view where someone would step out, from the level's walls alone |
| `bot_cover.gd` | Crouch cover and lean spots at tall corners that hide a bot from a threat |
| `bot_movement.gd`, `bot_routes.gd` | Lanes, holds, hunting, searching, strafing, keeping apart; following nav routes |
| `round_planner.gd` | Each round's team plans and lanes (a flanker's own, an anchor's short one, attackers to the middle, defenders their first points), and hunt spots from the team's memory |
| `bot_flag.gd` | Attack / Defend: each bot's side, which attacker raises the flag and which defenders pull it down, when a bot wants the pole |
| `squad_orders.gd`, `squad_order_book.gd` | Squad orders: carrying each out (Follow me's spots and pace, Hold here's spot and each holder's place, Regroup); the orders in force, handed out and ended |
| `bot_roster.gd`, `bot_personality.gd` | Each bot's name and personality for a match; a personality laid over the level's skill, and its habits |

Nothing allocates per tick once warm. Route searches (`NavGrid.find_route`) are queued, one a tick, shared with walk-off
routes.

## Not yet

No callouts and no magazine sharing (docs/KNOWN_ISSUES.md).
