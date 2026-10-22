# SP3 · The referee's whistle and each field's ambience as data

**Review:** critic Accept 8/8 · qa Pass · performance skipped (perf: skip)

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (QA's null-set advisory fixed by the build thread) | pass | 8/8 accept | |

## Decisions

- **The whistle is the browser's exactly:** a pure 2900 Hz sine with a 28 Hz warble of 4 %, 20 ms in and 50 ms out,
  short 0.14 s and long 0.8 s, three variants each a third of a warble cycle apart. `tools/render_whistle.gd` renders
  it headless from `SoundConfig` at full scale (played at gain 0.25); a test checks the files are byte-identical to a
  fresh render, so changed numbers without a re-render fail. Recorded in `docs/ASSETS.md` › Made by the project.
- **Blasts:** two short at round start 1.6 s apart, one long at round over, three more at match over 1.3 s apart (the
  match-over run spans 3.92 s, the browser's). `round_start_blast(i)` and `match_over_blast(i)` give start times.
- **Ambience as data:** `AmbienceConfig` (in `play_tuning.tres` via `SoundConfig.ambiences`) holds the browser's
  `AMBIENCES` for yard, woods and city, day and night (no birds at night). `set_for` falls back to the yard for an id
  with no set or a null one (QA). Three small Resource scripts (`AmbienceSet`, `AmbienceBed`, `AmbienceCall`) sit in
  `game/config/`, since a saved `.tres` needs one script per nested type: a planning miss in the touches list, not a
  defect. A call's seed is `rng_seed` (`seed` shadows a built-in).
- **Maps:** `MapData.ambience`; none means yard, an unknown or non-text value warns and plays the yard. Depot and the
  range are yard, Woodland woods, Neon Heights city.

## Known issues left

- `SoundConfig.ambience` and `ambience_gain` duplicate the yard bed until SP4 retires them; `test_ambience_config`
  checks they agree and must be updated then.
- A known id missing from the config falls back to the yard silently; the shipped data is guarded by a test.
- **For SP4:** call `set_for` once a match (its last fallback allocates), with `DEFAULT_ID` when there is no map; loop
  only over `round_start_blasts` and `match_over_blasts` (the helpers don't clamp); `match_over_blast(i)` counts from the
  round-over blast's start; whistles play on Interface at `linear_to_db(whistle_gain)` and aren't in `peaks.json`.
- Owner tests by ear once SP4 plays them: the round-start and match-over whistles bright and playful, not shrill; the
  woods and city beds no louder than Depot's yard, the city hum not droning.
