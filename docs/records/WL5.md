# WL5 · Bushes hide you and stop BBs

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | worker | 3,074 of 3,074 | – | – |

## Goal

Woodland's 70 bushes (the browser's FO1, M33e) join the simulation: no collider and no nav change, people walk through
them, 0.6 m of leaves over a BB's flight stops it and hides you from bots, a thinner crossing slows a BB and throws it
off its line from the match's stream, bots hold fire through more than 0.25 m (Easy through what a BB crosses), and a
BB in leaves rustles, puffs green and knocks leaves out. Bushes are drawn in one draw and marked on the minimap. A world
without bushes plays exactly as before. Woodland stays Dev-only; its layout is unchanged.

## Approach

- `Foliage` (`game/sim/foliage.gd`, new): the browser's map/foliage.ts. Bushes as parallel packed lists (foot, radius,
  height); `depth` (the leaves a line crosses, with a limit), `first_leaves` (a BB's tick), `leaf_surface` (where the
  line back leaves the bush), `leaf_floor`. Each bush is filed in a 4 m grid square by its middle, the query box widened
  by the widest radius, so a BB's 1.5 m tick looks at a few squares, not 70 bushes; a long sight line that covers more
  squares than there are bushes takes them all in one pass. Built once on the first query; nothing allocated after.
- `Leaves` (`game/sim/leaves.gd`, new): sim/leaves.ts's `deflectInLeaves`.
- `BBStep`: the browser's leaves step. `BB.leaf` counts leaves over the flight (reset by `BBPool.spawn`). A stop in
  leaves is a `BB_IMPACT` with `value` `BBStep.IN_LEAVES`, `value2` LEAVES, `direction` its unit path (never fast
  enough to ring a prop) and `reach` the leaves crossed; out of an edge, the new `GameEvent.Kind.BB_LEAVES` (appended
  last). A path that meets a wall still among leaves is slowed before it lands; one that ends among them is slowed and
  turned and flies on.
- `WorldQuery.foliage` (an empty `Foliage` by default); `BoxWorld.add_bush`; `MapData.foliage` read from the map's
  `foliage` list (a malformed bush left out with a warning); `MapLevel` hands the map's to its `JoltQuery`.
- Data: `BallisticsConfig` leaf_stop_depth 0.6, leaf_kept_per_metre 0.35, leaf_scatter_per_metre 0.5;
  `BotConfig.foliage_see_through` 0.6 and `foliage_fire_through` 0.25; `BotSkill.fires_into_leaves` (Easy, in
  `bot_tuning.tres`).
- Bots: `BotSenses` sees through no more than foliage_see_through beyond close_awareness (`visible_part`,
  `sees_spot`, `leaves_clear`); `BotCombat.leaves_in_line` holds fire in `_line_of_fire_blocked`.
- Presentation: `BushView` (`game/play/bush_view.gd`, new), one MultiMesh of a 12-side, 6-ring sphere stretched to
  each bush in a seeded pick of `WoodsConfig`'s bush greens, built by `PlaySession` after the woods and prewarmed.
  `PuffView` gains its own leaves pool (one more MultiMesh, the puffs' material) with `leaves_stop` (a green puff and
  4 to 6 leaves where the line back leaves the bush) and `leaves_brush` (1 or 2); they fall to the bush's foot and fade.
  `SimAudio` plays `impact_leaves` for a stop (impact gain) and an edge (`SoundConfig.leaf_brush_gain`, half).
  `Hud`'s "Leaves in the way · step clear to shoot" (`HUD_LEAVES_IN_THE_WAY`) under the vault prompt when your own BB
  stops in leaves within `HudConfig.leaves_notice_near` (2 m) of your eyes, for 1.4 s. `MinimapField` draws each bush
  as a disc in `MinimapConfig.bush_colour`.
- Tests: `tests/unit/test_bushes.gd` (37). `MatchRunner.each_tick` lets a test watch every tick of a whole match.

## Risks

- Every BB a tick asks the bushes: measured below at about 40 µs a tick on average in a 5v5 firefight.
- Files outside the task's `touches`, each a small addition the task needs: `game/sim/bb.gd` and `bb_pool.gd`
  (`BB.leaf`), `game/sim/game_event.gd` (`BB_LEAVES`), `game/map/map_level.gd` (hands the bushes over),
  `game/play/play_session.gd` (builds BushView, routes the leaves events), `game/config/bot_config.gd`,
  `effects_config.gd`, `hud_config.gd`, `minimap_config.gd`, `sound_config.gd` and `woods_config.gd` (the data rows),
  `tests/support/match_runner.gd` (`each_tick`).

## Defaults taken

- **The leaves' line back is the BB's own path (−its unit direction), reaching back as far as the leaves it crossed,**
  not the line to its shooter: it is the side it went in even after a bounce (the browser's KI2), needs no lookup of
  the shooter, and a BB fired from inside a bush still shows where it stopped (the line back ends inside).
- **Two thin crossings add up** (`BB.leaf` over the flight), as FO1 ruled; a ricochet keeps its count.
- **Leaves met at a wall in the same tick slow the BB before it lands but don't turn it** (the browser's KI1).
- **A grid of 4 m squares** for the bushes: about two of Woodland's bushes across and under three ticks of a fast BB,
  so a tick's path looks at one to four squares. Not tuned further: the bushes' share of the BB step is small (below).
- **The edge's rustle is the stop's cue at half its gain** (0.45, the browser's `leafBrush`), counted in the same
  impact limit.
- **The puff is pale green (#d6eba8 at 0.9), twice a BB puff's size,** and the leaves yellow-green (hue 69 to 92°,
  7 cm long): the browser's darker green vanished against a bush in the pictures. Every bush, leaf and mark colour is
  over 20° from every team hue (tested on linear RGB, the default and every colour-vision set).
- **Bushes are drawn on every preset, lit, casting shadows, in one draw;** low spheres until the art pass (step 32).
- **The minimap's bushes are drawn over every block,** as a muted green disc #4f6e44: the trunks under them are a
  pixel or two.
- **The notice reads your eyes' distance to the stop,** 2 m (the browser's `leavesNoticeNear`), under the vault prompt.
- **Pro's held angles don't read bushes yet** (`BotAngles` is outside the task; KNOWN_ISSUES).

## Measurements

### The BB step a tick in a 5v5 firefight (acceptance 5)

Headless, the 4-core container. A whole 5v5 Woodland bot match at Normal; every tick the match's BBs in flight are
copied into two pools of their own and stepped by `BBStep.step` (cease-fire, so nobody is knocked out), once with
Woodland's 70 bushes and once with none, timed with `Time.get_ticks_usec`. Ticks with a BB in flight:

| Seed | Ticks, BBs a tick (mean, max) | With bushes: mean, p99, max | Without: mean, p99, max | 20+ BBs: with, without (mean) | Leaves events |
|---|---|---|---|---|---|
| 3 | 5,363, 9.6, 32 | 541, 1,215, 4,598 µs | 500, 1,107, 2,579 µs | 890, 827 µs (474 ticks) | 24 |
| 7 | 6,757, 8.0, 32 | 509, 1,157, 3,470 µs | 471, 1,058, 2,940 µs | 928, 850 µs (345 ticks) | 41 |

The bushes add about 40 µs a tick (8 %), about 4 µs a BB; the rest is the level's rays and the bodies. The maxima are
single ticks.

### Sightings (acceptance 3)

`test_bushes.gd`, Woodland 5v5, first to 2, seed 3: 3 rounds in 171 s of play, 24 hits; 4,718 sightings sampled every
sixth tick (each bot against each enemy in view range), 26 of them through some leaves, the deepest 0.579 m (limit
0.6). The test takes about 25 s.

### Gate

`tools/check.sh` on the 4-core container: every gate passed, 3,074 tests of 3,074, in 16 min 11 s. Unit part 1
(now with `test_bushes.gd`) 356 s, part 2 519 s: both under the 600 s where CI1 moves the boundary, so it stays.
`tools/match_guards.sh`: 7 of 7 in 25 min 12 s (the shipped maps, which have no bushes: they play as before).

## Verified

- Headless: `test_bushes.gd` covers every acceptance: the leaves a line crosses and the index against a bush-by-bush
  reference over 2,000 seeded lines; a BB stopped 0.6 m in, one through a 0.36 m edge slowed to 0.35^0.36 of its twin's
  speed and turned within 0.5 rad a metre, two edges adding up, a wall met among leaves, a bush off the path changing
  nothing (positions and the stream); no object made a tick; a body walking through a bush as through open ground;
  Woodland's nav grid, its rays through every bush and the ground under each the same with and without bushes;
  bots seeing through 0.55 m and not 0.65 m, nobody hidden within close awareness, Normal and Pro holding fire through
  0.3 m, Easy firing through 0.5 m and not 0.7 m; the 5v5 match; one draw of 70 ellipsoids; the colours; the puff and
  leaf counts and the leaves coming to rest; the minimap's marks; the notice; the rustle and the quieter edge.
- Pictures (Xvfb, Compatibility, 1600 x 900, High), in the project files' `screenshots/step26/`:
  `wl5-bushes-day.png` and `wl5-bushes-night.png` (the east pines), `wl5-leaves-puff.png` (a stop 0.07 s on, held
  still for the picture), `wl5-hud-notice-minimap.png` and `wl5-minimap.png` (the notice, and the bushes as green
  discs on the minimap).

## Advisories left

- The leaves' turn draws from the match stream (`state.rng`), as ricochets do, so on a map with bushes later spread
  draws shift; the same seed still plays the same match and a bushless world draws nothing (QA). A stream of its own
  would keep spread independent of bushes.
- Overlapping bushes count twice (`Foliage.depth` sums them); sight and the BB stop agree, so the 0.6 m rule holds
  (QA).
- `Hud._leaves_left` isn't cleared at a round start; a notice can linger under 1.4 s into the next round (QA,
  harmless).
- Woodland isn't in the match guards while it is Dev-only; QA ran 5v5 seeds by hand (Normal 1-6, Easy/Hard/Pro 3
  each): no round held up or on time.
- BushView casts sun shadows across the whole map in one unculled draw a cascade (performance; Low has no sun shadows,
  so check Medium and up on the owner's PC).
- `Foliage.leaf_floor` walks every bush once a leaf event; grid it if bushes pass a few hundred (performance).

## For the owner to test

- On Woodland (Dev), shoot into a bush someone is crouched behind: deep in, nothing gets through; through an edge, BBs
  go wide. Does the puff read on a sunlit bush?
- Stand in a bush and fire: the notice should come up, and bots should not see you from 3 m out.
- Easy bots should pepper bushes you hide in; Normal and up should wait.
