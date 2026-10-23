# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## AD1 · Adaptive difficulty (Dev)
when: build order step 31, after the late features (owner, 2026-10-22)
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

## SP4 · Kit rustle, landing thuds, whistles and ambience calls
tier: core
perf: required
touches: game/play/foley_tracker.gd, game/play/ambient_calls.gd, game/play/sim_audio.gd, game/play/README.md,
  game/sim/footsteps.gd, game/sim/game_event.gd, game/config/sound_config.gd, game/config/play_tuning.tres,
  game/config/README.md, tests/unit/test_foley_tracker.gd, tests/unit/test_ambient_calls.gd,
  tests/unit/test_footsteps.gd
contract: Simulation and presentation (1); Events (3); Data, not literals (6); Headless (9)
acceptance:
  1. FoleyTracker (plain, the browser's foley.ts): a crouch, a stand, or a lean away from upright starting plays
     foley_crouch, _stand or _lean once per movement, read from the state's crouch and lean and their previous values
     for anyone in play; leaning back is quiet. Others' within 9 m, at most 3 per 0.15 s, muffled as SP2; yours at
     the own_foley level. Presentation only: bots don't hear it. Per-character records made once per match.
  2. Landing thuds: FOOTSTEP LAND carries the touchdown speed (GameEvent documents where). The landing's level and
     pitch follow it from land_min_speed (today's sound) to hard_land_speed (× land_hard_gain, pitch × land_hard_pitch),
     with a rustle under a hard one; your own landing at own_land_gain. Bots hear landings as today (Footsteps tests
     pass, plus the speed).
  3. The whistle (SP3's files and pattern) on the Interface bus: two short blasts start a round (in place of the
     beep), one long ends it, three more end the match; the challenge's Time is the long blast (its count and Go beeps
     stay). A new round's whistle cuts the last short. Blasts wait in a fixed queue: no timer or node made per play.
  4. The map's ambience (SP3): its day beds through the Ambience bus, and its calls, each kind on its own seeded gaps
     at a random bearing and its distance round the listener, at its height, positional, at the pool's lowest
     priority; the same seed gives the same calls. The night set waits for step 26's flag. ambience_gain and
     SoundConfig.ambience retired.
  5. GUT tests: rustle once per movement and none on leaning back; the call schedule by seed and its distances; the
     landing level by speed. A tick allocates nothing; the smoke test plays its match with no script errors.
status: open
attempts: 0
