# DO1 · Depot's doors

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-31 | 1 | thread | pending | pending | – |

## Goal

The owner's doors for the new Depot (2026-10-31, with concept 3): "some rooms should have doors. By default some doors
should be open and some closed. Players can open or close doors for tactical gameplay however opening or closing a door
creates noise which can be heard by enemies." Second of four pull requests: DR1 the map (merged), DO1 doors, AB1 two
flags, DR2 the CC0 dress.

## Approach

- **Data.** `tools/depot/layout.py` already marked 15 hinged doors in its walls and huts ("dopen" / "dshut");
  `build_map.py` now writes them to `data/maps/depot.json` as `doors`: each its shut leaves' box (0.08 m thick, as
  tall as the wall, hung on the wall's +x or +z face across its 2 m gap), its `side` and whether it starts shut (8
  shut, 7 open). `MapData.doors` reads them; a bad one is left out with a warning.
- **The level.** `WorldQuery` lists the doors (`add_door`, `door_centers`, `door_halves`, `door_starts_shut`) and
  takes `set_door_shut`. `BoxWorld` adds each leaf as a wooden box it skips while open (`box_off`). `MapLevel` gives
  each leaf a static body of its own (a switch rebuilds one shape, not the wood body's), and `JoltQuery` switches its
  shape and names its body wood. So a shut door stops BBs, bombs, sight, hearing rays and movers on both, with no
  change to the nav grid, the bake or the minimap (the gap stays walkable).
- **The rules** (`Doors`, `DoorState`, `DoorConfig` in `sim_tuning.tres`). `PlayerCommand.use_door` toggles the door
  in reach (1.6 m level, 1 m up or down) nearest the view's line. A swing takes 0.4 s and no press. A door won't shut on
  a body. Each toggle is a `DOOR` event heard out to 20 m. A walk-off opens a shut door it walks into. Each match and
  each round starts with the doors as the map sets them. The leaf is solid from the moment it starts to shut until it
  starts to open.
- **Bots.** `BotBrain` presses Use when a shut door in reach lies within 57° of its walk (`Doors.shut_ahead`).
  `BotHearing` hears an enemy's door out to its reach through any walls (`_hear(..., muffled = false)`).
- **The player.** Open / shut door is on U (`use_door`, rebindable, `KeyBindings`). A line under the crosshair says
  "U to open the door" or "to shut" while one is in reach (`Hud.set_door_prompt`). The minimap and the sound cues
  take a door as a step out to its reach. `SimAudio` plays `door_open` or `door_shut` from the door, muffled by walls.
  The sounds are rendered by the new `tools/render_doors.gd`.
- **The view.** `DoorView` draws every door's two leaves in one MultiMesh (one draw), bottle green (`MapStyle`
  `door`), hinged at the jambs. They swing out to the door's side and fold flat against the wall's face when open. Only
  a door whose swing changed is moved.

## Defaults taken

- The owner's door defaults from the concept (2026-10-31): the noise carries about 20 m through walls and shows on the
  minimap; one door speed; doors reset each round; a shut door stops BBs.
- The key is U: every key round WASD is taken (E leans, F is Follow Me), and it can be rebound.
- Open leaves fold flat against the wall rather than standing out into the room, so an open door is no obstacle the
  nav grid doesn't know.
- Bots open doors and never shut them. A door opened or shut by someone already hit is heard by players but not by bots
  (as a hit player's prop knock is).
- The door's leaf is bottle green, off both team hues, so a door reads apart from the plywood.

## Checks

- Pending.
