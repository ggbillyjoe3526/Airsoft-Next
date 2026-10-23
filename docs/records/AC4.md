# AC4 · Sound cues round the crosshair

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | 8/8 accept | |

## Decisions

- **The owner approved the step 21 pictures and the plan's defaults (2026-10-23):** sound cues are off by default,
  red, 100 %; steps show to 22 m, shots and hit calls to 60 m; shown through walls as far as the sound is heard; fed
  by the same events as the minimap's hearing (plan question 4, `hud-sound-cues.png`, `settings-accessibility.png`).
- **The reaches are the sounds' own** (`SoundConfig.step_reach` and `max_distance`, the numbers the tab's key shows),
  not MinimapConfig's (equal today), so a cue never tells more than your ears. A shot's reach is times its replica's
  `heard_scale`; `MinimapHearing.heard_scale` is now public and shared rather than copied.
- **One feed, not a second listener:** PlaySession's `_after_tick` hands the tick to SoundCues right after
  MinimapHearing, with the same ears (`spectated()`), only while the cues are on. Switching them off hides the ring
  and takes every marker down, so switching on again starts clean.
- **"Yours" is the listener's:** watching a teammate once you are out, their sounds are the ones left out. Teammates'
  shots and hit calls show; their steps and vaults don't. Steps of a player already out (walking off) make no cue, as
  on the minimap. A hit call shows at the caller's feet.
  New ears clear the markers (QA): the view moving to another player, as a side change does, so a marker made while
  that player was a teammate doesn't stay up as their own sound.
- **A full pool makes room:** one marker per player and kind; with all ten up, the one heard longest ago makes way,
  so the newest sound always shows. A burst renews and moves one marker.
- **Opacity is by the distance when heard** (1 beside you to 0.35 at the reach), times the fade over the last 0.6 s
  of its 1.4 s; timed by the simulation's ticks (60 Hz), as the minimap's patches.
- **The ring's line shows only while a marker does**, as strong as the strongest marker: the picture shows it with
  markers up, and a ring always round the crosshair would be clutter while nothing is heard.
- **The markers are the concept's shapes** (its `cueRing`, px at 1080p, Size scaling markers and their edges, never
  the ring); each dark edge is drawn outside its fill, as the SVG's stroke under the fill, so a faint marker doesn't
  darken. The HIT tag's word is the hit feed's (`HUD_HIT_TAG`) in Inter 800, dark on a light colour
  (`HudStyle.ink_on`), drawn at its own size rather than scaled up.
- **The ring sits over the teammate markers and under the rest** of the HUD (the order wheel and banners draw over
  it); it hides with the match summary and with the HUD while skipping a round.
- **The tab's sample is drawn, not a picture:** a flat field colour behind the crosshair, the ring and three markers
  (a step behind left, a fainter shot right, a hit call ahead), following the picked colour and size; the key's icons
  follow the colour. The key's help line is at the key's own size (15 px), as the picture.
- **AccessibilityConfig is made in PlaySession** (`AccessibilityConfig.new()`, as AC1 planned, like DisplayConfig),
  not added to PlayTuning.

## What the owner checks on his PC

- Settings › Accessibility against `settings-accessibility.png`: Sound cues live (no LATER), the sample and the key's
  icons; change the colour and size and watch the sample follow.
- A match with Sound cues on: a bot's steps behind you show two dots on the ring, shots an arrowhead (fainter further
  off, half as far with a silencer), hit calls a HIT tag; turn and the ring turns with you; nothing for your own
  sounds or your teammates' steps; a new round clears the ring. Switch it off from the pause menu: the ring goes at
  once. Whether 150 px reads well at 1080p and 4K, and the sizes at 60 % and 200 %.
- The HIT tag's word is dark on light cue colours (yellow, white) where the concept drew it white: check it reads.

## Verified here

- `tests/unit/test_sound_cues.gd` (12 tests): each kind's reach (just within and beyond), a silenced shot's half
  reach, height not counting, a vault as a step; your own sounds, your hit and teammates' steps make none, a
  teammate's shot and hit call do, an enemy walking off doesn't, watching a teammate their steps are theirs; a burst
  is one marker, moved and renewed, a step of the same player another; life, fade and opacity by distance (1, 0.675,
  0.35); the pool of ten never grows and the oldest makes way; a new round, a new match and another side's ears clear
  them; the bearing of a sound behind and to the left (-3π/4), turned left and turned round, on the ring 150 px out;
  the picked colour and size reach the markers, not the ring; 300 busy ticks and ten turning frames with every
  marker up allocate nothing (object count not growing), a redraw a frame while up and none once nothing is; in a
  session off by default and not fed, on shows the ring, styles it and feeds it, off hides it, clears it and stops
  feeding; the tab's row live with the sample and the key's three icons following colour and size.
- `test_settings_screen`, `test_minimap_hearing`, `test_gauge_pattern`, `test_what_got_you`, `test_hud_minimap` pass.
- DebugPerf counts: `--smoke --perf` headless, cues off and forced on (a local change, not committed; ten
  `[cues] live=` lines confirmed the feed): `nodes_max=1043 orphans_max=794` both, `new_nodes/s=0` through the match.
- Xvfb screenshots at 1080p (Compatibility): the ring with a step behind left, a far shot right and a hit call ahead
  in red at 100 %, and white at 200 %, and the tab's sample and key match the pictures.
- `tools/check.sh`: gdlint, changelog notes, unit tests (2234 passing), the smoke test and the licence notices pass.

## Files outside touches

- `game/play/minimap_hearing.gd` (`_heard_scale` made public as `heard_scale`, for SoundCues).
- `tests/unit/test_ac2_qa.gd` (the greyed-row check moved from Sound cues, now live, to Reduced motion; it also
  checks the cue size slider takes the mouse and focus again).

## Known issues left

- None new.

## Advisories left (critic, QA, performance)

- `HudSoundCues._draw` works out each marker's bearing and opacity twice (once to place it, once to draw it); at ten
  markers at most, only while one is up, it isn't worth the change now.
- The HIT tag draws its word with `draw_string` each frame while a hit call shows; the font cache covers the shaping.
- The HIT word takes `HudStyle.ink_on` (dark on a light cue colour) where the concept drew it white, for readability;
  on the owner's list to confirm.
- Markers hold while the game is paused, since their life runs on simulation time.
- A sound at the listener's own spot has a bearing of ±π (drawn behind); only a hit call at your feet could land
  there.
