# SP2 · Muffling through walls

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus (QA's NaN fix and two performance fast paths by the build thread) | pass | 8/8 accept | |

## Decisions

- **One rule for bots and the player:** `SoundPath.blocked_share` (static, in `game/sim`, through `WorldQuery`) is
  the browser's soundPath; BotHearing uses it in place of its own copy, and bot tests pass unchanged.
- **Presentation:** `SoundOcclusion` (RefCounted, held by SimAudio) gives each sound another character makes a share
  from the listener's eyes: open, half (low cover) or full (a wall), played on SP1's EffectsHalf/Full or
  PowerHalf/Full buses at the browser's level for that share. A silenced shot takes the more muffled corner and both
  levels. A BB impact casts one ray that stops `surface_gap` short of its surface. Your own sounds and interface cues
  are never muffled; once you're out, the listener is the teammate you watch.
- **Budget:** a character's share is reused for `refresh_ticks` (6); a tick casts at most `ray_budget` (24) rays; a
  sound over budget uses its character's last share and an impact plays open. Measured in real matches: 0.12-0.33 rays
  a tick on average, worst 7, about 7-8 µs a ray (figures in `game/play/README.md`).
- **A bus muffled to silence** gives level 1.0, not a NaN (QA).
- **Fast paths** (performance): an open play works out no bus or level, and a tick with the same cast walks no
  character records.

## Known issues left

- Thin walls (0.15 m or less) under the impact gap play BB impacts open: KNOWN_ISSUES row.
- Dead characters still cost rays when they make a sound; the 6-tick cache can lag a step out of cover by up to 0.1 s.
- The ray counters and two `Time.get_ticks_usec` calls a cast ship as dev counters only tests read; print them on the
  `--perf` line or drop them.
- `bus_for` rounds the share at 0.5 rather than deriving the half bus from `SoundMix.HALF_SHARE`; `_play` takes ten
  positional parameters (an options struct or `_play_from` would read better).
- With the defaults, `max_distance` and `occlusion_reach` are both 60 m, so the far ramp never runs in play.
- SimAudio script time is up about 5-8 µs a tick (0.04 % of a tick); in a synthetic 12-shooter full-auto fight the
  ray budget is reached and SimAudio takes about 0.5 ms a tick.
- Owner tests by ear: an enemy firing or walking behind a wall on Depot sounds dull and lower but can be placed; low
  barrier half muffled; a silenced shot behind a wall (about −12 dB) still heard; stepping out of cover opens within a
  beat with no click; watching a teammate once out, muffling follows them and the hit tick and whistles stay clear.
