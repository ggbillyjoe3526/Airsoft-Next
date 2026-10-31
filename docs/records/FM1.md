# FM1 · The full-screen map and Go there

**Review:** REVIEW_LINE

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-31 | 1 | worker | ✓ (see Verified); QA QA_VERDICT, performance PERF_VERDICT | CRITIC_VERDICT | – |

## Goal

Two of the owner's ideas for 0.1 Dev 2 (2026-10-31): "players can press a button to see a view of the map. This is
essentially a full screen mini map", and "a ping to instruct team mates where to go (even if no enemies are spotted
there)". His third idea, vehicles for a big outdoor map, is for later (`docs/IDEAS.md`).

## What changed

- **The full-screen map** (`HudFieldMap`, `game/ui/hud_field_map.gd`), held on M ("Map (hold)"):
  - the minimap's own drawing of the field (`HudMinimap.textures`, made once a match), whole and north up, fitted in a
    square as big as the screen allows, over a dimmed screen, with "DEPOT · ROUND 2" over it;
  - what the minimap shows and nothing more (`HudMinimap.fill`, now shared by both): you, your teammates, the pole or
    the overtime flag, Hold here's or Go there's spot, your team's pings, and the other team only where your side
    heard them; on the storey you stand on;
  - the named areas' words, one for each name over its biggest box (`HudFieldMap.areas_of`);
  - it works for any map: nothing in it knows Depot, and Depot and Woodland are both tested.
- **Its pointer** (`MapPointer`, `game/input/map_pointer.gd`): while M is held the mouse moves it instead of the view
  (`ControlsConfig.map_gain`), feet still move and fire needs a fresh pull after, as with the order wheel. A click is a
  Go there to that point of the field, the ping's key a ping there (`PlayerCommand.ping_on_map`, `ping_target`). Out of
  play, the map shows with no pointer. The map and the wheel never open together; none on the range; it hides under
  the pause menu, the scoreboard and the match summary.
- **Go there** (`SquadOrder.Kind.MOVE`): mouse button 4 ("Squad: go there"), the order wheel's new Go There (lower
  right, six items now), or a click on the map. It travels as a ping (`PlayerCommand.ping_move`; a PING event with
  value2 1, value 2 for one on the map), and the bots' controller hands it out as an order
  (`SquadOrderBook.give_move`): every teammate in play goes, side by side across the way there, to the floor spot
  (`Pings.move_spot`, `Pings.map_spot`: the nearest walkable within `PingConfig.map_snap`), and once all are there it
  turns to Hold here (`SquadOrderBook.move_arrivals`), looking on the way they went. The same spot again keeps it;
  at the sky it says "Nowhere there to go" (`SquadOrders.Notice.NOWHERE`). Its marker is Hold here's, reading "GO ·
  30 M" while they are on their way.

## Decisions

- The map's rules and Go there's: `docs/DECISIONS.md` › Menus, HUD, settings and accessibility (FM1).
- **Held, not toggled,** like the scoreboard; a toggle can come with a setting if play asks for it.
- **Go there is an order, not a book ping.** It turns to Hold here once they arrive, so the wheel, X and the marker
  keep working as they did; the radio click confirms it, not the ping pip.
- **No enemy is ever pinged on the map:** a ping there marks the floor only, as the map shows only what was heard.
- **Mouse 4 by default:** every key near WASD is taken. The wheel and the map need no extra key.

## Verified

VERIFIED

## Known issues left

- None.
