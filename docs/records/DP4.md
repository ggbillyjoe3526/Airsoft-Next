# DP4 · Noisy props and loud ground

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-24 | 1 | Opus 5.5 (worker) | CHECKS | – | – |

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

FIGURES

## Files outside `touches`

`game/map/map_level.gd` (four lines: the blocks' kinds into the query), `game/play/play_session.gd` (two lines: the
knock's puff), `game/config/sim_tuning.tres` (the new config written in, for `test_saved_configs`),
`game/config/effects_config.gd` and `sound_config.gd` (the puff's size, the knock's level and reach),
`tests/support/match_runner.gd` and `tests/guards/test_match_guards.gd` (the knocks and rings counted),
`docs/ARCHITECTURE.md` (Contracts 4 names the boxes), `docs/KNOWN_ISSUES.md` and the `game/sim/`, `game/ai/`,
`game/play/` and `game/config/` READMEs.

## For the owner to check

`docs/PLAYTEST.md` › Depot › Noisy props, and Rings and loud ground: each prop's sound and puff, once a second at
most; walking, crouching, glancing and holding quiet; a ring turning an idle bot; steps on the gravel and the dock's
steel ramps louder and heard further.

## Checks

CHECKSDETAIL

## Known issues left

- Noisy props, rings and loud ground are NP1's first guesses, to tune in play (`docs/KNOWN_ISSUES.md`, Bots).
