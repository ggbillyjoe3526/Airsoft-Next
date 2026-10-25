# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

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
