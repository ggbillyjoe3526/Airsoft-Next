# DV2 · The Dev tab and dev content

**Review:** 1 attempt · critic Accept 7/8 (Opus) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Opus 5.5 (build thread) | ✓ | 7/8 Accept | – (the map README row and KNOWN_ISSUES rows, the critic's check 8; QA added 14 tests) |

## Decisions

- **The Dev tab shows while the Dev settings box under the tabs is ticked** (the browser's hidden Dev group and its
  box). Its switches are saved whether the box is on or off and apply only while it is on: `Settings.active_dev()` is
  the tab's values then, else the defaults. Settings file version stays 1; older files read the new keys as defaults.
- **Entries are the block's list** with the browser's help lines (`legacy/browser/src/config/dev.ts`): Game speed
  (25 % to 200 % in 25 % steps), Dev content, Bottomless magazines, Ghost, Bots hold fire, Spectate any bot, Bot
  intentions, Retro pixels, End the round now, Reset the save. Not ported: Disable levelling and the XP actions (no
  levelling yet), Bots run low on BBs (no magazine hand-off yet), Adaptive difficulty, Time of day and Tone mapping
  (their systems aren't built), Debug info and BB paths (they are F3 and F4 here).
- **Cheats act through the simulation:** `DevCheats` on `GameState`; ghost (`Character.ghost`, `BBStep` skips the
  body) and bottomless magazines (`Armament.bottomless`) are the player's only, as in the browser; Bots hold fire is
  the bots' controller clearing its fire presses; End the round now is `Round.run_clock_out`, so the round ends as on
  time and its draw is replayed as any time-out is.
- **Game speed keeps the fixed tick:** `TickPacer` runs whole 60 Hz ticks, fewer or more per physics tick, and works
  out the drawing fraction between them, so a seed still replays and a slowed game still moves smoothly. Engine
  `time_scale` was ruled out: it shrinks each step's delta (measured: 1/240 s at 0.25) rather than the step count.
  Sounds keep their pitch.
- **The record mark** is `GameState.off_record`: set at a match's start by dev content or any cheat, and by any cheat
  turned on during it; it stays until the next match. Nothing reads it yet (records and XP come later).
- **Spectate any bot** and **Bot intentions** count as cheats (the browser's), though they change no rule. Spectating,
  you stand still, your keys are read and dropped (no press kept for later), each trigger pull moves to the next bot in
  play on either team, and your replica is hidden (it showed in a bot's view before: `ReplicaView.update` re-showed
  it). Intention labels keep one size on screen (about 25 px) and show through walls.
- **Retro pixels** is a full-screen shader under the HUD: 4 px blocks, 6 shades a channel, 4×4 ordered dither (the
  browser's defaults; its sliders came later in the browser's Looks group).
- **Maps are tagged in `data/maps.md`** (`MapCatalog`): Id, Name, Kind (`field` or `range`), Tag (`public` or `dev`),
  Blurb. Depot and the range are public; Woodland and Neon Heights dev. A map with no row counts as dev. The title
  screen gains a Map choice (public fields, plus dev ones with Dev content on) until step 8's menus replace it; the
  smoke test stays on Depot. Neon Heights loads and plays (tested); Woodland loads but has no vault links yet (BV1).
- **Reset the save** deletes the settings file and its backups and resets every setting at once, after a
  confirmation; there is no undo (the browser's Save group with Undo isn't built). In a match the game doesn't reload.

## Known issues left

Each has a row in `docs/KNOWN_ISSUES.md`.

- `off_record` is set but unread until records and XP exist.
- Retro pixels is fixed at the browser's defaults (no pixel size or colour sliders).
- Bottomless magazines switched on with the magazine already empty still dry-clicks until a reload (as the browser).
- Bot intention labels overlap when bots stand close.
