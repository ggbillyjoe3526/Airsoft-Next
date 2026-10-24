# DP4 · Noisy props and loud ground

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | Opus 5.5 (worker) | pass, 2,905 of 2,905; match guards pass (Follow me measure by lead ruling) | – | – |

## What was built

- `NoiseConfig` (`game/config/noise_config.gd`, new, `SimTuning.noise`, written into `sim_tuning.tres`; criterion 1):
  the browser's `config/noise.ts` as it was. Steel (skip, container, van) knocks 20 m and rings 12 m, clank (generator,
  IBC) 17 m and 10 m, rattle (rack, stall, vending machine) 16 m, glass (phone booth) 15 m, plastic (toilet, arcade
  cabinet) 14 m, wood (crate, wrapped pallet, Woodland's fence) 13 m; 3 m/s into the face, 2 mm of the move lost, the
  face within 0.08 m of the body's side and that way (cosine 0.5), not underfoot (0.05 m), from 0.9 m up; one quiet
  time of 1.2 s a prop; a ring needs 15 m/s and lands within 0.06 m of a face. Every other kind is silent. Ground carry:
  gravel and metal 1.35, the rest 1.
- `WorldQuery` (`game/sim/world_query.gd`) lists what each of the level's boxes is (`block_kinds`, centres, halves,
  surfaces; `add_block`), filled once by `MapLevel.build` from its blocks (ramps left out) and by `BoxWorld.add_prop` in
  tests, so every match the level builds (play, the guards, the balance report) has its props with no other change.
- `PropNoise` (`game/sim/prop_noise.gd`, new), made with each `Simulation`: the noisy props in parallel packed arrays.
  `knock` runs after each in-play character's Movement step (not a vault) on `Character.wanted_move` and `made_move`
  (new, written by `Movement.step`): the browser's `stepPropBump`, with cheap per-axis rejects first. `ring` runs after
  `BBStep` over the tick's BB impacts on the level (a BB_IMPACT now carries the BB's velocity as it landed in
  `direction`), on the ringing props only. Quiet times are `GameState.prop_quiet`; a quiet time further off than 1.2 s
  (an earlier match's clock) no longer holds. No randomness. New events `PROP_KNOCK` and `PROP_RING` (actor, the block
  index as target, the Sound as value, a knock's surface as value2, `reach` in m).
- Loud ground (criterion 3): `Footsteps` puts `NoiseConfig.carry(surface)` on run, sprint and landing steps as the
  event's new `carry` (a rattle keeps 1), the surface read from `WorldQuery.surface_under` as before; walking and
  crouching stay silent.
- `BotHearing` (criterion 2): a knock is heard as a step on whoever made it, from the prop out to its reach, walls
  muffling it (SoundPath, as any sound), shared by team-play bots; a ring is faint: heard where it rang, only by a bot
  with nobody in sight and nothing seen or heard within `hearing_contact_time`, never shared. Steps reach × carry.
- `SimAudio` (criterion 4): a knock plays `prop_<sound>` from the prop at 0.85 (pitch ± 0.08, level ± 1.5 dB) out to
  26 m, muffled from the prop's point; a ring plays as the BB's impact (no extra sound); steps on loud ground play
  × carry louder and further. `PuffView.knock`: a puff of the prop's surface dust at 4 times a BB's
  (`EffectsConfig.knock_puff_scale`), dispatched by PlaySession.
- `SoundCues` and `MinimapHearing` (criterion 2): an enemy's knock shows as a step out to the knock's reach; a step's
  reach × its carry.
- `tests/unit/test_noisy_props.gd` (18 tests, about 1.5 s): the table and silent kinds, the cues exist, Depot's level
  lists its noisy props and no wall; a run into a crate knocks once from its face (a 2.5 s push held), a sprint into the
  skip 20 m, a walk, a crouch or a wall silent, a 30° glance silent and 60° knocking, one quiet time across knockers,
  standing on a crate, the same knock on two runs; a ring on steel and none on wood, from a spent BB or a body, rings
  and knocks sharing the quiet time, a BB fired at the skip ringing once; run and landing steps on gravel carrying
  1.35, walking silent, concrete 1; bots hearing a knock to the prop's reach, a ring only when idle and not shared, a
  sprint on gravel 1.35 times as far; nothing allocated once warm with knocks and rings every second.
- The match guards print knocks and rings (`MatchRunner.MatchTally.knocks`, `rings`; measured, never asserted).

## Defaults taken

- The whole browser table, not only Depot's kinds: Neon Heights (van, stall, vending, booth, cabinet) and Woodland
  (fence) knock as they did in the browser ("NP1 as it was"); the glass cue exists in `assets/audio/cues/`.
- Reaches are per sound (steel, clank …) rather than per kind: every kind of one sound had the same reaches.
- A rattling magazine's step keeps carry 1: criterion 3 names run, sprint and landing steps.
- Standing on a container, skip or generator is metal underfoot, so steps there carry 1.35 too (steel plate).
- The knock puff is 4 times a BB's (NP1's record), on the puffs' own life (0.35 s).
- Sound cues and the minimap take each step's carry too, so they agree with the audio (the browser's "one answer").

## Figures

**Knocks and rings a round on Depot** (the match guards' seeds, `MatchTally.knocks` and `rings`): Elimination at
Normal 54 knocks and 973 rings over 124 rounds on 16 seeds, 0.44 and 7.8 a round; Easy 0.77 and 9.6, Hard 0.47 and
4.2, Pro 0.63 and 3.3 (8 seeds each). Neon Heights at Normal 0.52 and 1.3 a round. The browser measured about 2
knocks and 6 rings a round on Depot (NP1); Godot's bots run into props less often.

**Balance against main** (`tools/balance.sh`, Normal on 32 seeds, Easy, Hard and Pro on 16, both modes, every map;
`98fbeb2` against main `0cccc38`, 2026-10-24): both 114 figures, 0 outside their band and 0 outside within noise on
either; near an edge 16 on DP4, 11 on main. No figure moved two combined standard errors (82 compared, the largest
1.8: Depot Easy's west end 47.0 → 35.5 % ±4.4 and the Hard flankers' share of hits 27.5 → 32.6 %). Depot Normal: the
west end 54.0 → 53.5 %, Alpha 49.8 → 54.3 %, the attackers 57.3 → 57.4 %. Reports in the project files,
`pipeline/runs/DP4/attempt-1/` (`balance-report.md`, `balance-report-main.md`, `balance-vs-main.txt`).

**Cost** (headless, a loaded 4-core cloud container): in a 5v5 Depot match at Normal (2 seeds, 240 s each) the knock
check costs 7.5 µs a tick on average beside a 405 µs sim step (1.9 %), the ring check 1.4 µs; worst single ticks of
1.1 and 2.1 ms are scheduling outliers (the check's own worst case is below). Worst case, every character blocked at a
sprint against a prop's face every tick on Depot's 51 noisy props: 79 µs a tick for 10 characters, 161 for 20, 379 for
40; running free 0.85 µs a character. A ring is about 5 µs an impact, over the 26 props that ring. Nothing is
allocated per tick once warm (`test_knocks_and_rings_allocate_nothing_once_warm`, Object count over 240 ticks of
knocks and rings).

## Files outside `touches`

`game/map/map_level.gd` (four lines: the blocks' kinds into the query), `game/play/play_session.gd` (two lines: the
knock's puff), `game/config/sim_tuning.tres` (the new config written in, for `test_saved_configs`),
`game/config/effects_config.gd` and `sound_config.gd` (the puff's size, the knock's level and reach),
`tests/support/match_runner.gd` and `tests/guards/test_match_guards.gd` (the knocks and rings counted; Follow me's
chasing measure),
`docs/ARCHITECTURE.md` (Contracts 4 names the boxes), `docs/KNOWN_ISSUES.md` and the `game/sim/`, `game/ai/`,
`game/play/` and `game/config/` READMEs.

## For the owner to check

`docs/PLAYTEST.md` › Depot › Noisy props, and Rings and loud ground: each prop's sound and puff, once a second at
most; walking, crouching, glancing and holding quiet; a ring turning an idle bot; steps on the gravel and the dock's
steel ramps louder and heard further.

## Checks

`tools/check.sh` (2026-10-24, after the Follow me ruling): every gate passes (gdlint, changelog notes, unit tests
2,905 of 2,905 in 830.5 s, the smoke test, licence notices); on 98fbeb2 2,894 of 2,894 in 904.7 s; `test_noisy_props` 18/18 rerun on the final code with `test_simulation`,
`test_footsteps` and `test_saved_configs`.

The match guards (`tools/match_guards.sh test_match_guards`, `test_flag_guards`): both files pass, 5 of 5 and 2 of 2
(Elimination at every level on Depot and Neon Heights, Attack / Defend, Follow me's 4 seeds: seed 3 7.99 m).

**Follow me on Depot seed 3: a measure changed by the lead's ruling, not the owner's (the owner can overrule it).**
On 98fbeb2 the guard failed seed 3: a follower 10.75 m behind the leader against the 8 m cap (`catch_up`); main
measured 7.36 m on that seed. Traced: the follower leaves Follow me for cover, comes back, and is judged 3 s later
(`FOLLOW_REJOIN`) while the leader sprints at 6.3 m/s, the followers' top speed too, so the gap can't close; DP4 only
reshuffles the match (the bots now hear knocks and rings). The lead ruled to change the guard's measure, not the
follow logic: in play the leader is the player, bots must not outrun the player's sprint, and a leader that waits
would be a guard artifact. Now beyond `catch_up` a follower is **chasing**, not left behind, when over the last 0.5 s
(`MatchRunner.CHASE_TICKS`) it covered ground at 80 % or more of its sprint speed (`CHASE_PACE`, straight-line, so a
corner's slow-down or a route round cover still counts) and the gap grew by 0.25 m at most (`CHASE_SLACK`); chasing
ticks don't count toward `follow_worst`. An instantaneous form (speed 90 % and heading within 60°) was tried first and
still failed seed 3 on a corner's slow-down (5.56 m/s for three ticks) and on the follow spot's 40° offset. Stuck,
standing, lost or slower followers still fail: `tests/unit/test_follow_measure.gd` (3 tests, 0.35 s) holds a
follower sprinting after a sprinting leader passing, and stuck, wrong-way, sideways, circling and running ones
failing. The near share and standing checks are unchanged. Re-measured over all 16 seeds (the guard keeps 4): worst
4.48 to 8.00 m (seed 3 7.99 m with 41 ticks chasing, seed 8 8.00 m with 7, 0 on the rest), near 97.1 to 100 %,
standing 1.29 % of 58,131 ticks. DECISIONS › Bots and balance; the KNOWN_ISSUES row is now "can wait".

## Known issues left

- Noisy props, rings and loud ground are NP1's first guesses, to tune in play (`docs/KNOWN_ISSUES.md`, Bots).
