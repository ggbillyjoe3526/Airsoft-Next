# OV3 · The overtime flag on screen and in sound

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-26 | 1 | worker | see Gate | – | – |

## Goal

Draw and sound Elimination's overtime flag (OV1's rules, OV2's bots) as the concept `concepts/step27/overtime-flag.png`
and the browser game's OT1 show it: the flag rising at the map's spot, chequered off-white and dark on a short pole
with its 1 m reach ring, the toucher's colour once touched; three short whistle blasts and OVERTIME · TOUCH THE FLAG;
the score bar's and the scoreboard's OT; the marker with a chequered glyph and the minimap's glyph; FLAG TOUCHED; the
screen reader's lines. Plan: project files `plan/step27-deferred.md` › The overtime flag.

## Approach

- `OvertimeFlagView` (`game/play/overtime_flag_view.gd`, new): built once a match by `PlaySession` in Elimination on
  a map with a spot (not practice), hidden until `RoundState.overtime_flag.up`. A short pole and weighted base and the
  cloth sit under one node scaled up out of the ground over 0.8 s, eased out (at once under Reduced motion:
  `rises`, set in `PlaySession._apply_motion`); the ring and its dark edge lie flat from the start. `refresh` reads
  the flag and `toucher_of(rs)` (the round's winner once it ended `OVERTIME_FLAG`, the flag still up through the
  pause) and changes the cloth's light checks and the ring only when the toucher or contested state changes; `face`
  turns the cloth to the view each frame. No collider. Its two materials go to the prewarm.
- `FlagView`'s mesh helpers are public statics (`cylinder`, `ring_mesh`, `ring_edge_mesh`, `cloth_mesh`, `flat`) so
  both flags share them; `flag_cloth.gdshader` gains a chequer mode (`chequer`, `checks`, `dark`; `team_colour` is the
  light checks' colour). `FlagViewConfig` gains the overtime flag's look (pole 2.3 m, cloth 0.96 × 0.64 m in 6 × 4
  checks, off-white (238, 234, 224), dark (38, 40, 44), the off-white ring, 0.8 s rise from 2 %).
- HUD: `HudStyle.overtime_clock(rs, max)` is the one rule for "OT" (Attack / Defend's rope overtime or the flag's time
  left), read by `Hud.update` and `HudScoreboard`; the OVERTIME event shows the banner for `HudConfig.overtime_banner_time`
  (2.4 s); `HudStyle.flag_round_won` / `flag_round_sub` / `ended_by_flag` give FLAG TOUCHED and the team's line;
  `Hud._round_over` adds the flag's played time to the round's table. `Hud.use_overtime_flag` puts the chequered glyph
  (`HudFlagGlyph.chequered`) on Attack / Defend's marker plate and anchors it `HudConfig.overtime_marker_height` (2.9 m)
  over the foot; `PlaySession` places it while the flag stands in a live round. `HudMinimap` draws the chequered flag
  (`View.set_pole(at, true)`) at the spot while it stands in a live round.
- `Announcer`: "Overtime · Touch the flag" on the OVERTIME event (polite) and "… · Flag touched · Alpha take the round
  · …" on a round won there. Strings `HUD_OVERTIME`, `HUD_TOUCH_FLAG`, `HUD_FLAG_TOUCHED` in `en.po`.
- Sound: `SoundConfig.overtime_blasts` (3) and `overtime_gap` (1.5 blast-lengths; the browser's overtimeWhistle),
  `WhistleQueue.overtime`, and `SimAudio` queues them on the OVERTIME event on the whistle's one voice.
- Tests: `test_overtime_flag_play.gd` (18).

## Risks

- The cloth turning to the view is a readability call, not physics: walking round it, it turns with you.
- The touched colour is read from `RoundState.reason` and `winner`, which carry the last round's result into the next
  live round; `toucher_of` only reads them once the round is over and the flag still up, and a test pins that.
- The flag adds 5 draw calls while up (below); nothing while down.

## Defaults taken

- **FLAG TOUCHED sits where Attack / Defend's FLAG RAISED sits** ("WON / ROUND 7 · FLAG TOUCHED · ALPHA TAKE THE
  ROUND"), the stamp still WON / LOST from your side: the concept's inset puts FLAG TOUCHED as the title, but every
  round's banner here is the stamp first, and the screen reader reads the same line.
- **The cloth turns to face the view:** seen along its length (the first picture, from the Depot approach) it read as a
  bare pole; the browser's flag stood on Attack / Defend's fixed pole.
- **The light checks take the team colour and the dark checks stay dark** once touched, as the browser tinted its white
  checks; the concept's inset shows the same.
- **Dark is the browser's (38, 40, 44),** not the concept's bluer (34, 38, 46), which sits 4° from Alpha's hue at a
  saturation of 0.26, just under the 0.3 the team-hue test reads as a team's; the browser's is 0.13. The off-white is
  0.27 at 42° (27° from Beta's hue) and the contested yellow, Attack / Defend's, 29° from it.
- **A short pole of 2.3 m with the cloth's top 6 cm under its top,** as the concept's render; the marker anchors 2.9 m
  up (Attack / Defend's 3.7 m over a 3.4 m pole, scaled).
- **The ring is off-white, yellow while both teams are at it, then the toucher's,** as the browser's ring and
  Attack / Defend's contested yellow.
- **No mix dip under the overtime blasts:** the round start's short blasts don't dip either; only the long ones do.
- **No separate minimap glyph or marker class:** the pole's drawing and Attack / Defend's plate take a chequered mode,
  as the task's touches name, so the pinning and placing rules stay one.
- **The marker and minimap show the flag only while the round is live,** as the pole's; the flag itself stands through
  the pause in the toucher's colour.

## Measurements

Draw calls, objects and primitives in a frame (Compatibility under xvfb, 1920 × 1080, Depot from 12 m, the default
preset), the flag up and then hidden on the same paused frame:

| Flag | Draw calls | Objects | Primitives |
|---|---|---|---|
| Up | 173 | 658 | 43,643 |
| Hidden | 168 | 653 | 42,659 |

The flag costs 5 draw calls (pole, base, cloth, ring, edge) and about 980 triangles while up, nothing while down (it is
hidden, and `refresh` returns at once). The rest of that frame's 168 is the field and HUD as before (the 150-call
ceiling is the owner's High-preset line from a baseline still to be measured; DECISIONS › Performance budgets). A
frame with it down allocates nothing (`test_overtime_flag_play.gd`, 600 refreshes, OBJECT_COUNT unchanged); the
whistle queue keeps its fixed size (5). Frame time with it up on the Low preset needs the owner's hardware (PLAYTEST ›
The overtime flag on screen and in sound).

## Pictures

Engine renders of a real `PlaySession` on Depot (Compatibility), the clock run out so the simulation put the flag up
(round and score set to 7 and 3 – 3 as the concept):

- `/mnt/project-files/screenshots/step27/ov3-flag-up.png`: the flag up 1 s after the buzzer, the banner, OT 0:29, the
  FLAG · 12 m marker with the chequered glyph, the minimap's glyph, a teammate's call (OV2).
- `/mnt/project-files/screenshots/step27/ov3-flag-touched.png`: a teammate's touch: the cloth and ring in Alpha's blue,
  WON / ROUND 7 · FLAG TOUCHED · ALPHA TAKE THE ROUND, the score 4 – 3.

## Verified

- `test_overtime_flag_play.gd` 18: hidden until up, the 0.8 s rise and Reduced motion, facing the view, colours idle,
  contested and touched, `toucher_of`, the team-hue test on every colour set by day and night, no collider, nothing
  allocated with it down; in a match: built once in Elimination, none in Attack / Defend, the clock run out giving the
  banner for 2.4 s, the flag shown, OT 0:25 on the bar and the board; the marker's words and pinning, the minimap's
  glyph live only; FLAG TOUCHED and the played time, a draw as before; the toucher's colour in the pause; the screen
  reader's lines; the whistle pattern and SimAudio on the Interface bus.
- The touched suites pass: `test_flag_play`, `test_hud_minimap`, `test_scoreboard`, `test_whistle_queue`,
  `test_announcer`, `test_hud_style`, `test_round_result`, `test_overtime_flag`, `test_ov1_qa`, `test_fg1_qa` and the
  QA suites that read the HUD.
- `python3 tools/wiki.py check` and `tools/changelog.sh check` pass.
- Not verified: how it looks and sounds in play and its frame time on the Low preset (PLAYTEST › The overtime flag on
  screen and in sound).

## Gate

Pending.
