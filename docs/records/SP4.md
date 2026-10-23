# SP4 · Kit rustle, landing thuds, whistles and ambience calls

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | 7/8 accept (check 8: the bed doc and its KNOWN_ISSUES row, fixed in the records push) | |

## Decisions

- **Kit rustle** (`FoleyTracker`, plain class from the browser's foley.ts): reads each character's crouch and lean
  against last tick; leaning back upright and anyone out of play make none. Played by SimAudio on Footsteps: yours
  plain at `own_foley_gain` (0.45), others' within `foley_reach` (9 m), at most 3 per 0.15 s, muffled through walls.
  No event, so bots never hear it.
- **Landing thuds:** a landing's event carries its speed (`direction` straight down, its length the speed). Level and
  pitch ramp from `land_min_speed` to `hard_land_speed` (8 m/s, a 1.6 m drop): `land_hard_gain` 1.41 (+3 dB, plan
  question 4), `land_hard_pitch` 0.85; at or above it a `foley_crouch` rustle joins (the knees giving). Yours at
  `own_land_gain` 0.3, just over your steps (0.25). Bots hear landings as before.
- **Whistle** (`WhistleQueue`, one Interface voice made at setup): two short blasts start a round in place of the beep,
  a long one ends it, more end the match; the range's Time is the long blast, its countdown and Go keep their beeps. A
  new round stops the voice and clears the queue.
- **Ambience:** one bed set per match from the map (`DEFAULT_ID` with none), looping on Ambience. `AmbientCalls` times
  each call kind on its own gaps, seeded from the call's `rng_seed`, the match's seed and number, reseeded on a
  rematch; calls play positionally on Ambience at `Priority.CALL`, reach `max(max_distance, distance + 1 m)`. The
  night set waits for step 26. `ambience`, `ambience_gain` and `time_pitch` are retired from SoundConfig.
- **One unpanned copy per bed:** Godot's plain player has no pan, and two unpanned copies would cancel a tonal loop's
  odd harmonics; the yard plays at today's level. A panned pair needs its own buses (KNOWN_ISSUES).
- **Simulation clock** for the whistle and calls: deterministic and pauses with the game; the game-speed cheat
  stretches their gaps, and skipping plays calls 6x as often, like everything else.
- **New classes** rather than growing SimAudio further (`whistle_queue.gd`); `PlaySession` passes the footsteps tuning
  to `SimAudio.setup` for the softest landing speed.

## Measured (performance, headless)

- SimAudio per tick: Depot 3v3 22-24 → 46-50 µs, 6v6 37 → 65 µs; FoleyTracker about 0.9 µs a character. No
  allocation per tick or play; nodes, orphans and static memory flat across leaves and rematches; setup +4 ms once.
- Shots and own sounds never dropped at 3v3 to 6v6; rustle and calls cannot steal a shot or own voice.

## Known issues left

- Beds are mono and centred, `width` and `copy_offset` unused: KNOWN_ISSUES row.
- Lean jitter at a wall can rustle often; your own rustle has no rate limit: KNOWN_ISSUES row (playtest).
- A plain hop (5.4 m/s) now lands about 1.6 dB louder at pitch 0.93, since the ramp starts at `land_min_speed`; the
  owner's ear decides.
- sim_audio.gd is 509 lines; a later sound task moves the beds and whistle into their own node.
- Owner listens for: the round-start whistle (clear over gunfire, not shrill) and the match end; a hop versus a drop
  off the dock; leaning at a wall corner while jiggling the mouse; your own rustle on repeated crouch-peeks; Depot's
  birds, crow and dog and Neon Heights' traffic, chimes, pigeons and horn (rare enough, from around you, beds not too
  narrow); the range's Time as the long blast.
