# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## WL1 · Sloping ground: Woodland loads and plays (Dev)
when: build order step 26, first, after CI1 (plan: project files `plan/step26-woodland.md`)
tier: core
perf: required
touches: game/map/terrain_grid.gd, game/map/map_data.gd, game/map/map_level.gd, game/map/jolt_query.gd,
  game/map/greybox_faces.gd, game/nav/nav_grid_builder.gd, game/nav/README.md, game/config/map_style.gd,
  game/sim/ray_hit.gd, game/play/sim_audio.gd, game/config/effects_config.gd, game/config/ricochet_config.gd,
  game/ui/minimap_field.gd, tests/support/field_standard.gd, tests/support/field_measure.gd,
  tests/unit/test_terrain.gd, tests/unit/test_woodland_layout.gd, tests/unit/test_match_page.gd,
  tools/map_pictures.gd, assets/maps/woodland.jpg, docs/DECISIONS.md, docs/PLAYTEST.md
contract: Physics behind two interfaces (4); Data, not literals (6)
acceptance:
  1. MapData reads `terrain` into a TerrainGrid (minX, minZ, cell, cols, rows, heights row by row; `height_at` on
     each cell's two triangles split along its (x0, z0) to (x1, z1) diagonal, the browser's `map/terrain.ts`) and
     loads a map whose ground is terrain alone; a map with neither floor nor terrain is still refused. The browser's
     `terrain.test.ts` cases pass in `test_terrain.gd`.
  2. MapLevel draws the terrain's triangles and gives Jolt the same ones as a trimesh, one body per ground surface.
     At 1,000 seeded points a ray straight down meets the ground within 1 cm of `height_at`; a body walks up, down
     and across the Knoll's steepest face and stands still on it. Depot and Neon Heights build exactly as before.
  3. `RayHit.Surface` gains GRASS and LEAVES, appended. `ground` (base, underTrees, patches) gives each 0.5 m of
     terrain its surface for `surface_under` and BB rays: steps play its `step_<surface>_*` cue; BBs on grass and
     leaves puff and sound as earth and don't ricochet. MapStyle gains `tree`, `log` and `fence` (wood, saturation
     under 0.3 on linear RGB); field.teamColour passes.
  4. NavGridBuilder takes each cell's ground from the terrain (the browser's `nav/navGrid.ts`); bots walk every
     Woodland lane end to end. The record gives Woodland's grid build time, nodes and 100 cross-map `find_route`
     times beside Depot's (`game/nav/README.md`).
  5. Woodland leaves FieldStandard.NOT_YET and passes all fifteen field checks with only its 141 m sightline
     exception and no standard raised, or each failing check goes to the owner before the pull request is ready. The
     record lists its figures beside the plan's estimate (middle walks 56.6 and 61.2 m, flag walks 99.0 and 19.7 m).
  6. `test_woodland_layout.gd` ports the browser's `map/woodland.test.ts`: no slope steeper than a ramp, the east
     camp at most 2 m above the west, no boulder, six spawns and dead-zone spots an end, nobody within 8 m of a spawn
     sees the head or chest of anyone within 8 m of the other end's, three or more ways into the fort and no spot
     inside seeing more than two, a log within 2.5 m every 2 m along the last 20 m of each lane.
  7. Woodland (dev) plays a whole match from the Match page at today's team size and light; the minimap draws its
     ground; `assets/maps/woodland.jpg` is rendered by `tools/map_pictures.gd`. Pictures from West Hill and the Knoll
     are posted.
status: open
attempts: 0

## WL2 · 5v5 and 6v6: team sizes per map (Dev)
when: build order step 26, after WL1
tier: core
perf: required
touches: data/maps.md, game/map/map_catalog.gd, game/ui/match_rules_box.gd, game/ui/match_page.gd,
  game/ui/match_options.gd, game/ui/match_picks.gd, game/save/custom_rules.gd, game/config/round_config.gd,
  game/ai/bot_roster.gd, game/ai/bot_routes.gd, game/config/nav_config.gd, game/play/play_session.gd,
  game/ui/text/en.po, tests/unit/test_match_page.gd, tests/unit/test_team_sizes.gd, docs/PLAYTEST.md
contract: Data, not literals (6); Saves (8)
acceptance:
  1. `data/maps.md` gains Min, Standard and Max team size columns (the browser's `maps.ts` teamSize): Depot 1, 3, 3;
     Neon Heights 1, 4, 5; Woodland 5, 5, 6; the range 1, 1, 1. MapCatalog reads them; an unreadable cell keeps its
     built-in value and warns.
  2. The Team size row offers only the picked map's sizes. Picking a map sets its standard size; a saved custom size
     is kept where the map allows it (Depot 3v3 to Woodland 5v5 and back to 3v3, saved). Nothing offers 7v7. An old
     save loads unchanged.
  3. A 6v6 on Woodland spawns twelve players, each on a spawn of their own, and each walks off to a dead-zone spot
     of their own; every bot has a name and a kit.
  4. Route searches keep to a budget a tick (the browser's NAV.searchBudget, in NavConfig); a search over it waits
     for the next tick, and no bot waits more than 1 s for a route (tested at 6v6). The record gives frame time and
     draw calls at 5v5 and 6v6 on Woodland on Low and High, and the searches a tick.
status: open
attempts: 0

## WL3 · Night light and the Day / Night switch (Dev)
when: build order step 26, after WL1
tier: core
perf: required
touches: game/config/lighting_config.gd, game/config/play_tuning.tres, game/config/night_lighting.tres,
  game/play/field_lighting.gd, game/play/light_pools.gd, game/play/play_session.gd, game/play/skyline_view.gd,
  game/play/skyline_shapes.gd, game/config/skyline_config.gd, game/map/map_data.gd, game/map/baked_light.gd,
  game/map/map_level.gd, game/save/dev_settings.gd, game/ui/match_rules_box.gd, game/ui/match_page.gd,
  game/ui/text/en.po, tests/support/field_checks.gd, tests/support/field_standard.gd,
  tests/unit/test_night_light.gd, tests/unit/test_skyline.gd, tests/unit/test_baked_light.gd, docs/DECISIONS.md,
  docs/ART.md, docs/PLAYTEST.md
contract: Simulation and presentation (1); Data, not literals (6); Saves (8)
acceptance:
  1. A night LightingConfig beside the day one, from the browser's `LIGHTING_PRESETS.night` as first guesses: a cool
     moon 18° up, turned toward the map's `moonOver`; a dark sky with stars and the moon's disc on every preset; haze
     from 20 m; a dim fill; and the map's `lighting.overrides` (Woodland's brighter moon and exposure). Ambience
     plays its night set and figures their night glow.
  2. MapData reads `night`, `lighting.presets` and `lights`. A map plays its first preset unless the Match screen's
     Day / Night row (shown only for a map offering both) or Dev › Time of day (any map, either preset) picks the
     other; one night flag drives every night system (tested). field.night (the browser's `map.night`) is ported.
  3. Light pools: each light lights the ground within its radius; the nearest up to the preset's real light count
     (Low 0, Medium 2, High 4) are real lights and the rest drawn pools; fires flicker, still under Reduced motion.
     Fires are (255, 228, 160) and lanterns (255, 232, 180), at least 20° of hue from every team colour (tested).
  4. A bake's hash reads the sun it was baked under, not the playing preset's: Depot at night keeps its bake with no
     warning, drawn by its sky share alone. The skyline fades to the playing horizon and its hue test passes on the
     day and night horizons. Depot's mast lamps glow at night with no real light.
  5. `test_night_light.gd`: under the night preset, earth, wood, skin and both team colour sets on figures keep a
     set minimum brightness and contrast against the night ground (the record gives the figures), and the colour
     vision check passes at night.
  6. The record gives frame time on Low and High at night on Woodland and on Depot by Dev time of day. Pictures of
     Woodland's west camp, meadow and fort and Depot's masts at night are posted.
status: open
attempts: 0

## WL4 · Woodland's look in placeholders (Dev)
when: build order step 26, after WL1 (its night parts after WL3)
tier: core
perf: required
touches: game/play/woods_view.gd, game/config/woods_config.gd, game/map/map_data.gd, game/map/skyline_piece.gd,
  game/play/skyline_shapes.gd, game/config/skyline_config.gd, game/play/play_session.gd,
  game/save/graphics_apply.gd, data/graphics.md, tests/unit/test_woods_view.gd, tests/unit/test_skyline.gd,
  tools/map_pictures.gd, assets/maps/woodland.jpg, docs/ART.md
contract: Simulation and presentation (1); Data, not literals (6)
acceptance:
  1. Every tree gets a crown, a cone placeholder above head height, drawn instanced: no collider, no effect on
     sight, BBs or nav.
  2. The map's `dressing`: the `treeline` skyline kind (cones along its points, faded to the horizon, MS1's unseen
     pieces left out) and the hills; `forest` beyond the fence; grass tufts under 0.34 m from Medium; puddles as a
     darker, glossier ground that never hides a BB; moss on logs; leaf drifts and fallen twigs (`woods`); fireflies
     and motes at night, still under Reduced motion. Each part follows a Graphics row, off on Low where it costs.
  3. It is look only: field checks, the nav grid and a seeded match come out the same with it off (tested).
  4. The record gives triangles, draw calls and frame time per preset; pictures from the meadow by day and by night
     are posted, and `assets/maps/woodland.jpg` is rendered again.
status: open
attempts: 0

## WL5 · Bushes hide you and stop BBs (Dev)
when: build order step 26, after WL1
tier: core
perf: required
touches: game/map/map_data.gd, game/sim/foliage.gd, game/sim/leaves.gd, game/sim/bb_step.gd, game/sim/world_query.gd,
  game/sim/box_world.gd, game/map/jolt_query.gd, game/config/ballistics_config.gd, game/ai/bot_senses.gd,
  game/ai/bot_combat.gd, game/config/bot_skill.gd, game/config/bot_tuning.tres, game/play/bush_view.gd,
  game/play/puff_view.gd, game/play/sim_audio.gd, game/ui/hud.gd, game/ui/minimap_field.gd, game/ui/text/en.po,
  tests/unit/test_bushes.gd, docs/DECISIONS.md
contract: Physics behind two interfaces (4); Seeded randomness (5); Data, not literals (6)
acceptance:
  1. MapData reads `foliage` (upright ellipsoids); `WorldQuery.foliage` hands them to the simulation. No collider
     and no nav change: Woodland's grid and level rays are the same with and without them, and a body walks through
     one without slowing (tested).
  2. BBs (FO1, the browser's `sim/leaves.ts`): leaves count over the whole flight; 0.6 m stops a BB, the same depth
     bots can't see through (a test holds them equal); a thinner crossing keeps 0.35 of its speed and spin a metre
     and turns by up to 0.5 rad a metre from the seeded stream. A world without bushes flies BBs as before.
  3. Bots see through no more than 0.6 m of leaves and hold fire through more than 0.25 m; Easy fires through as
     much as a BB could cross. A 5v5 Woodland match keeps every sighting under that depth and finishes its rounds.
  4. A BB in leaves plays `impact_leaves` with a green puff and 4 to 6 leaves where the line back leaves the bush;
     through an edge, a quieter rustle and 1 or 2 leaves. "Leaves in the way · step clear to shoot" shows when your
     own BB stops within 2 m of you. Bushes are drawn as placeholder ellipsoids in one draw and marked on the minimap.
  5. The match guards pass; the record gives the BB step's time a tick with bushes in a 5v5 firefight.
status: open
attempts: 0

## WL6 · Bots by night (Dev)
when: build order step 26, after WL3
tier: core
perf: required
touches: game/ai/night_field.gd, game/ai/bot_senses.gd, game/ai/bot_world.gd, game/ai/bot_cover.gd,
  game/ai/round_planner.gd, game/config/bot_config.gd, game/config/bot_tuning.tres, game/play/play_session.gd,
  tests/unit/test_night_sight.gd, docs/DECISIONS.md
contract: Simulation and presentation (1); Data, not literals (6)
acceptance:
  1. A NightField is built once a match when the map plays at night, never by day: light pools by floor, the canopy
     grid (3 trunks within 4 m, 1 m cells) and roofs (the browser's `map/nightSight.ts`). Bots make someone out from
     40 m lit, 25 m in the open, 10 m under the canopy and 15 m indoors (NIGHT_SIGHT in a typed config). By day
     sight is unchanged (a seeded Depot match plays the same).
  2. Normal, Hard and Pro keep out of light pools when they hold or hunt; Easy stands where its lane says.
  3. A 5v5 night match on Woodland keeps every sighting inside the target's range, builds the canopy grid once and
     finishes its rounds (the browser's `woodlandNightMatch.test.ts`). The record gives the grid's build time and
     the night sight check's cost a bot.
status: open
attempts: 0

## WL7 · The weapon torch (Dev)
when: build order step 26, after WL6
tier: core
perf: required
touches: game/sim/torch.gd, game/sim/armament.gd, game/sim/character.gd, game/sim/player_command.gd,
  game/sim/sim_events.gd, game/sim/simulation.gd, game/ai/bot_torch.gd, game/ai/bot_senses.gd,
  game/ai/night_field.gd, game/config/bot_config.gd, game/loadout/, game/pool/pool.gd, game/ui/customise_view.gd,
  game/ui/part_options.gd, game/ui/part_page.gd, game/ui/key_binding_list.gd, game/config/controls_config.gd,
  game/config/part_stats.gd, game/input/, project.godot, game/play/torch_beams.gd, game/play/first_person_view.gd,
  game/play/figure_view.gd, game/play/sim_audio.gd, game/save/graphics_apply.gd, data/graphics.md,
  game/ui/text/en.po, tests/unit/test_torch.gd, docs/DECISIONS.md, docs/PLAYTEST.md
contract: Simulation and presentation (1); Commands (2); Data, not literals (6); Saves (8)
acceptance:
  1. Customise offers a Light slot with the Weapon Torch (`pool.md` › Lights, `stats.md` › Lights) on the replicas
     it fits, dev while Woodland is dev, saved with the loadout; by day it is not fitted.
  2. Weapon torch (T, rebindable) switches it through the command, with an event and `torchClick`. It goes out when
     holstered, on a replica without one, when hit and at each round start.
  3. Every bot carries one on a night field and switches it by what it is doing (the browser's `ai/botTorch.ts`,
     with its minimum hold): no strobing, out when hit, off at round start. On Depot by day a kit with a torch plays
     exactly as one without.
  4. Bots see anyone inside a lit beam's spill within its reach from the lit range (40 m), and anyone with a lit
     torch pointed within 60° of them from as far.
  5. Your own torch is a real spot from the rail on Medium and up (one of the preset's real lights; shadows on High
     and Ultra) and a haze on Low; everyone else's is a cone, a lens glare and a lit spot, three instanced draws for
     the match. Pictures by your torch and of another's beam are posted.
  6. The record gives frame time on Low and High in a 5v5 night firefight with every torch on.
status: open
attempts: 0

## WL8 · Glowing BBs (Dev)
when: build order step 26, after WL3
tier: ui
perf: required
touches: game/loadout/loadout.gd, game/loadout/saved_loadouts.gd, game/loadout/bot_kits.gd,
  game/ui/customise_view.gd, game/ui/part_options.gd, game/play/bb_view.gd, game/config/effects_config.gd,
  game/ui/text/en.po, tests/unit/test_glow_bbs.gd, docs/PLAYTEST.md
contract: Simulation and presentation (1); Saves (8)
acceptance:
  1. Customise, beside BB weight: Glowing BBs, At Night (the default), Always or Off, per replica and saved; an old
     save reads At Night. Bots load At Night.
  2. A glowing BB is drawn green (157, 255, 122) with a green streak (92, 255, 74), never under 0.0045 rad across,
     its streak 0.05 s long, on every preset, with no halo; white BBs draw as before.
  3. It is presentation only: a seeded match plays the same with every choice (tested).
  4. Pictures by day (Always) and at night are posted.
status: open
attempts: 0

## WL9 · The practice range set in Depot, and practice on any map (Dev)
when: build order step 26, after WL1 (Woodland's at night after WL7)
tier: core
perf: required
touches: data/maps/range.json, data/maps/depot.json, game/map/practice_spots.gd, game/config/range_config.gd,
  game/ui/match_options.gd, game/ui/match_page.gd, game/play/practice_spot.gd, game/play/play_session.gd,
  game/sim/range_targets.gd, game/sim/range_challenge.gd, game/save/run_record.gd, game/ui/pause_menu.gd,
  game/ui/text/en.po, tests/unit/test_practice_spots.gd, tests/unit/test_match_page.gd, docs/PLAYTEST.md
contract: Data, not literals (6); Saves (8)
acceptance:
  1. Practice is offered on every field (dev fields under Dev content): no bots, no score, you start at end 0's
     first spawn.
  2. Targets come from the map's data alone (the browser's `practiceSpots.ts`, `practiceLayout.ts` and
     `PRACTICE_SPOTS`): lane points facing back down their lane, the other end's spawns, points along long legs,
     each on the floor, none near your start or crowding another, crouched behind low cover, steel, movers and
     swingers where they fit. A test runs it on Depot, Neon Heights and Woodland.
  3. The timed challenge's START plate stands ahead of your start where it fits; each map keeps its own best, and a
     run with a play-changing Dev setting is never a best.
  4. Practice on Woodland plays at night with your torch fitted. Pictures on Depot and Woodland are posted.
  5. The practice range is set in Depot (owner, 2026-10-24): its design and layout stay exactly as they are (lanes,
     plate distances, figures, movers and swingers, the timed challenge), but it is dressed as part of the Depot site
     with Depot's props, materials, light, sky and skyline instead of its own, so the Blender models serve both.
     Practice, Loadout from practice, the readout and the challenge's best work as before. A picture is posted.
status: open
attempts: 0

## WL10 · Woodland's match guards, balance and performance (Dev)
when: build order step 26, last
tier: core
perf: required
touches: tests/guards/test_match_guards.gd, tests/guards/test_flag_guards.gd, tests/balance/balance_run.gd,
  tests/support/match_runner.gd, tools/match_guards.sh, .github/workflows/ci.yml, docs/KNOWN_ISSUES.md,
  docs/PLAYTEST.md, docs/DECISIONS.md
contract: none
acceptance:
  1. The match guards play Woodland Elimination and Attack / Defend at 5v5 at night, on 16 seeds at Normal and the
     levels' seeds at Easy, Hard and Pro: rounds settle; nobody is stuck, falls or is hit by a teammate. Should the
     guards' CI job pass its time limit, Woodland gets a job of its own.
  2. The balance report covers Woodland's modes and levels. A figure outside its band (Normal 45 to 55 %, Pro 40 to
     60 %) goes to the owner beside the browser's figures (M88, FO1, its WL2), never into a looser band.
  3. The record gives Woodland's frame time, draw calls and triangles at 5v5 and 6v6 on every preset, against Low's
     60 FPS target; each gap is a KNOWN_ISSUES row.
  4. PLAYTEST › Woodland lists what to try (both camps, the fort, the ravine, bushes, the torch on and off, glowing
     BBs, 6v6). The owner makes Woodland public when he is happy.
status: open
attempts: 0

## AD1 · Adaptive difficulty (Dev)
when: build order step 27, with the other deferred features (owner, 2026-10-24)
tier: core
perf: optional
touches: game/ai/, game/config/, game/save/dev_settings.gd, game/ui/settings_screen.gd, game/play/play_session.gd,
  game/ui/xp_card.gd, game/progress/, tests/
contract: Data, not literals (6); Saves (8)
acceptance:
  1. A Dev switch makes the other team's skill a rating that blends the levels' numbers (the browser game's
     adaptiveDifficulty.ts): up a little after a round or match you win, down after one you lose, within its limits;
     the on/off habits come from the nearest level and stay fixed through a match. It never changes a level's own
     numbers (DECISIONS 2026-10-06).
  2. Your teammates never adapt; an adaptive match gives no XP and stays out of the records.
  3. The rating is saved and the end-of-match card says where the next match starts.
status: open
attempts: 0
