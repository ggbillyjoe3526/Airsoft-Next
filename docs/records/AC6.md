# AC6 · Screen reader messages for hits and rounds

**Review:** critic pending · qa pending · performance pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | pending | |

## Decisions

- **The owner approved the step 21 pictures and the plan's defaults (2026-10-23):** Godot's built-in screen reader
  support (AccessKit) only, messages On, read politely with your hit and the match result assertive (plan question 7,
  `settings-accessibility.png`'s "Reads hit calls, your hit and round results when a screen reader is running"); a
  built-in voice reading aloud without a screen reader went to IDEAS. Menus for screen readers wait for a Beta polish
  pass (question 8): a KNOWN_ISSUES row.
- **What Godot 4.7.2 offers, checked on the pinned binary headless:** `Control.accessibility_live` takes
  `AccessibilityServer.LIVE_OFF / LIVE_POLITE / LIVE_ASSERTIVE` (the plan named DisplayServer's; in 4.7.2 assigning
  `DisplayServer.LIVE_*` is a parse error). Headless, `DisplayServer.accessibility_screen_reader_active()` answers -1,
  `AccessibilityServer.is_supported()` false and `DisplayServer.has_feature(FEATURE_ACCESSIBILITY_SCREEN_READER)`
  false; `accessibility_support` is 0 and the driver `accesskit`. `tts_speak` exists but `audio/general/text_to_speech`
  is off. So GUT checks the words, the join and the label's properties; the speech is the owner's check below.
- **A hit feed line names who called the hit, then whose BB it was** ("Rook called HIT · You"), as the task's
  example. Names are the feed's own (`HudFeed.name_of`, shared): a bot's name, else its team's, "You" for the player.
- **Your own hit replaces its feed line** ("You're hit · Rook", assertive), so it is not read twice. A hit with no
  shooter (actor -1) says nothing, as the feed shows nothing.
- **The lines follow the banners, in sentence case:** the round's start is its banner and the line under it ("Round 3",
  "Round 2 · Attack · Take the flag", "Round 5 · Half time · ends swapped"); a round's end is the stamp, the banner's
  line and the score, your team first ("Won · Round 3 · Alpha take the round · Alpha 2 – 1 Beta"); the match's end
  the stamp and the summary's line ("Won · The match · Alpha 5 – 3 Beta"), without the map and bots tail. Sentence
  case, not the banners' capitals, which some readers spell out. The practice range announces no rounds.
- **The join window runs 0.3 s from a message's first line** (`Announcer.JOIN_WINDOW`), not from the last, so a long
  burst still goes out at 0.3 s; joined lines are parted by ". " so the reader pauses. One assertive line makes the
  message assertive: the last round's end and the match's end, which come in one tick, are one assertive message.
- **The label is cleared when a message starts gathering,** so a message the same as the last (your hit in two rounds
  by the same bot) still reaches the reader as a change, with no invisible characters. It is shown at `modulate` alpha
  0 (the renderer skips a fully transparent item; a hidden one would likely leave the accessibility tree), takes no
  mouse or focus, and has auto translation off (its words are already translated). The clock is the HUD's frame delta.
- **`accessibility_support = 0` is written into `project.godot`** under `[accessibility]`, in Godot's section order,
  though it is the default: the editor may drop default values when it saves the file, so a test checks the line is
  there and the effective value is 0.
- **The tab:** `SettingsAccessPage.LATER` is now empty; the AC2 QA check of a greyed row greys Screen reader messages
  by hand to keep testing the lock, and checks every built section takes input.
- **Settings reach a match at once** through `PlaySession._apply_hud` (`Hud.set_read_out`), with the gauge patterns and
  sound cues: a one-line change outside touches.

## What the owner checks on his PC

- **NVDA on Windows** (and Narrator if handy), a match with Screen reader messages On and the mouse captured: each hit
  call is read once ("Rook called HIT · Alpha"), your own hit at once ("You're hit · Rook"), each round's start
  ("Round 3") and end with the score, and the match's result at once; two hits close together come as one message.
  Note whether anything is read twice or not at all (the plan's risk: whether a live region speaks from a game window
  with the mouse captured, and whether a Label at opacity 0 stays in the accessibility tree).
- **Orca on Linux** (GNOME): the same match, the same checks.
- **Off:** Settings › Accessibility › Screen reader messages Off from the pause menu: nothing more is read; On again:
  the next hit is read.
- **No screen reader running:** the frame rate the same as before (AccessKit stays off under Auto).
- If a live region never speaks, the fallback is `DisplayServer.tts_speak` behind the same switch (plan question 7,
  now in IDEAS).

## Verified here

- `tests/unit/test_announcer.gd` (17 tests): each event's line (feed lines both ways and with a nameless bot, your hit,
  no shooter, round start in Elimination and Attack / Defend with half time, round end won, lost, drawn, by the flag
  raised and by time, the score from Beta's side, the match's end), the feed and the announcer naming alike, the
  practice range silent; the join window (a line at 0.2 s joins, out at 0.3 s from the first, a later line its own
  message, one assertive line making the whole message assertive); off sending nothing, dropping a gathering message
  and keeping nothing added; the label shown at opacity 0, polite, its text after the window, cleared while the next
  gathers, assertive for your hit and polite again after, LIVE_OFF with no text when off; the switch reaching a match
  at once; `project.godot`'s line and the effective value.
- `test_ac2_qa` and `test_settings_screen` pass with the row live.
- Performance: strings are built only on hit and round events, never per frame; each frame only a float moves while a
  message gathers (task `perf: skip`).
- `tools/check.sh`: gdlint, changelog notes, unit tests (2282 passing), the smoke test and the licence notices pass.

## Files outside touches

- `game/play/play_session.gd` (`_apply_hud` calls `Hud.set_read_out`).
- Tests: `tests/unit/test_ac2_qa.gd`, `tests/unit/test_settings_screen.gd` (the row is live).
- Docs: `docs/PLAYTEST.md` (the screen reader check, without squad orders), `docs/IDEAS.md` (the built-in voice),
  `docs/KNOWN_ISSUES.md` (squad orders and menus not read).

## Known issues left

- A screen reader hears only the hit feed, your hit and the rounds' turns: squad orders and the menus' custom-drawn
  controls wait for a Beta polish pass (KNOWN_ISSUES row).
