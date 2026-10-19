# MN2 · The Match screen, the loading screen and the seed on pause

**Review:** 1 attempt · critic Accept 8/8 (Sonnet) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Sonnet (worker) | pass, 705 tests after the rebase | 8/8 Accept | – |

## Decisions

- **Owner, 2026-10-19: the team cards read only ALPHA and BETA** (no armband line). **Woodland is listed while Dev
  content is on, as a DEV card greyed with LATER**, because its map is refused until step 27. Any listed map is greyed
  the same way from `MapData.problems` (read with `MatchOptions.map_problems`), not by name; maps that can play come
  first, the greyed ones last.
- **The Match page is drawn from plain rules** (`MatchOptions`: modes, chips, kicker, summary) so tests read them
  without a screen. Cards are one `MenuCard` (a `Button` with content inside), tags one `MenuTag` (LATER grey, DEV
  violet, the concept's `.later` and `.dev`).
- **Modes per map are data**: `MatchOptions.KIND_MODES` (a field hosts Elimination, the range its practice mode); a
  mode is pickable when built and hosted by the picked map. Attack / Defend and Practice Range are greyed LATER.
- **Chips come from `RoundConfig` and `HitConfig`**: "3 v 3", "First to 5", "Rounds 2:30" (the round time as m:ss),
  "Ends swap after 4", and "Ricochets Don't count" (or "Count") from `ricochets_count`.
- **`PlaySession.player_team`** (Alpha 0, Beta 1) replaces `PLAYER_TEAM` and `OPPONENT_TEAM`; `opponent_team()` is the
  other. Your teammates take your team, the bots the other. The HUD reads team names by event, the spectate code reads
  `player.team`, figures take their colour from `c.team`, the bots take `PLAYER_ID`: none assumed Alpha. A test plays
  Beta (character 0 is team 1, at Beta's end) and watches a Beta teammate when out.
- **Picks are kept for the session, not in Settings**: Settings holds options (sensitivity, volumes, Dev switches) and
  has no natural place for a match's picks. `MatchPicks`, a plain object `main.gd` keeps, so the picks survive the
  menus being freed.
- **No menu nodes live during a match** (the MN1 performance review): PLAY frees the title and the menus (and an open
  settings screen) and `_end_play` builds them again, as the Settings screen is. The loading screen is freed once the
  match runs.
- **The build is four steps over frames** (`PlaySession.staged`): the map, the level (greybox, colliders, light), the
  teams (simulation, nav grid, characters) and the views (views, sound, HUD, bots, start). `progressed(done, total,
  step_key)` drives the bar; each step is one frame, so the bar draws between them. The match runs from the frame after
  the last step; `started` follows that frame's update, so the first picture drawn once the screen goes is the match. A
  refused map emits `started` at once so the screen goes and the refusal shows. Not staged (tests, tools) the four run in
  `_ready`, as before. The loading screen sits on canvas layer 100, above the match's interface.
- **The bar's step names**: Loading the map, Building the field, Placing the teams, Building the views, then Starting
  the match; the percentage is steps done over steps (0, 25, 50, 75, 100).
- **The pause menu is the concept's flat panel**: PAUSED, "Depot · Elimination · Round 3", RESUME (flat yellow, as
  `pause.png`, not the slanted `MainButton`), SETTINGS, QUIT MATCH, and "Match seed" with the match's seed at the foot.
  The seed is `GameState.match_seed` (the 32-bit one the simulation uses). The end-round Dev hook is unchanged.
- **Map pictures**: `tools/map_pictures.gd` frames each loadable field's block box from 58 degrees up, at a corner,
  32 degree field of view, a little closer than fits (the card's 420x400 window crops the far corners, as the
  concept's did), 700x400, JPEG 0.85, default import (lossy JPG, as the title's backdrop). With two rows of cards
  (three maps) the pictures are 250 px tall so both rows fit the page.
- **Words** are keys in `en.po` (`MENU_*`, `MODE_*`, `RULE_*`, `BOT_*`, `LOAD_*`, `PAUSE_*`); `BOOT_MAP` is gone.

## Known issues left

Each has a row in `docs/KNOWN_ISSUES.md`.

- The picks are kept for the session only; the bots' levels, Attack / Defend, the practice range and Woodland are LATER.
- The map pictures have no figures and are soft when drawn full screen on the loading screen; Woodland has none.
- Looked at in Xvfb screenshots at 1080p only: a real display, 4K and the mouse are unchecked.
