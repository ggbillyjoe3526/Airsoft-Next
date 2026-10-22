# RG3 · The range drawn, heard and played

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (a performance advisory and a critic advisory fixed by the build thread) | pass | 8/8 accept | |

## Decisions

- **Practice is `PlaySession.practice`**, set before the session enters the tree, as `map_id`: the map's targets, mode
  Practice, the course the map's id, so Practice on a map (roadmap step 26) needs no new switch. You alone, no bots,
  no round clock, a breeze, no XP or match records; the views are the session's children and go with it.
- **Practice plays its own copy of the tuning** (`practice_tuning`): a team of one and ricochets never counting, so your
  own bounced BB only ticks you; Custom rules are ignored there.
- **The challenge's best is saved on its TIME cue**, `Records.add_challenge_run` then `save_if_dirty`, only when the
  session counts, so tests and the smoke test never touch the player's records. The challenge starts off;
  `set_challenge(on)` is there for RG4's pause-menu switch.
- **What you see is what a BB hits:** a figure is drawn from its hit volume's feet to the top of the body with a head
  disc at the hit volume's head; plates and posts use the sim's sizes. A plate swings back on its hanger when hit; a
  figure falls over the fall time and rises over the sim's rise time; movers and swingers are interpolated.
- **Lit targets are `ff4d0a` at glow 1.2 and the floor lines safety yellow**, not the browser's colours: in the
  screenshots its orange washed out to the plywood's tan and its off-white lines vanished on the pale concrete.
- **Sounds:** steel rings (heard to 80 m) and figures knock from the hit; your own target hit plays the hit-marker tock
  (no HUD hit marker, as the browser). Countdown, Go and Time use the shot timer's beep at three pitches; Time's low
  beep stands in for a whistle. Practice skips the round-start beep.
- **The smoke test opens the range** with a small pilot that shoots the nearest plate, and fails if none rings. Frame
  time headless: the range's tick and draw about 0.8 ms against Depot's 1.2 ms.
- A still target's tilt is written only when it changes (performance advisory).

## Known issues left

- For RG4: the HUD still shows the match bar and round banner in practice; `RangeView` draws its lines and boards
  whenever practice is on, so Practice on a map must gate it on the map's targets; `play_session.gd` is about 900
  lines, so new practice code should go in its own part. A plate's swing runs on render time, not the Dev game speed.
- Performance for the owner's hardware: the range adds about 130 meshes (twice Depot's), with shadows; the line and
  board materials aren't prewarmed (only worth adding if the first frame hitches).
- Owner to test: a 60 to 74 m plate's ring and swing; figure falls and pop-ups crisp, not floaty; the lit glow in sun
  and shade; the three beeps told apart without looking; boards readable from the line; your own close ricochet only
  ticks you.
