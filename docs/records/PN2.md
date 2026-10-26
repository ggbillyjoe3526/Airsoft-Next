# PN2 · Ping markers, the minimap and the pip

**Review:** pending (critic, QA, performance)

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-26 | 1 | worker | see Verified | – | – |

## Goal

PN1's ping book on screen and in sound (concept `step27/ping.png`; the browser game's ui/pingMarkers.ts and
AUDIO.pingPip, PG1): a spot's ring in your team's colour, a contact's diamond in the other team's, each with its word and
distance; pinned under the minimap when off screen; the same on the minimap; a soft pip for your own ping; Settings ›
HUD › Ping markers.

## Approach

- **`HudPingMarker`** (`game/ui/hud_ping_marker.gd`, new): one marker. Over the field a 30 px ring or diamond (an inner
  `Glyph`, redrawn only when its look changes) with "PING · 9 M" / "CONTACT · 13 M" under it (white, the vault
  prompt's dark edge); pinned, a navy plate with a rule in the marker's colour, a chevron, a small glyph and the words,
  as the flag marker's pinned plate. `set_age` pops it in (`pop_scale`, eased out from 0.4) and fades it (`shade`).
  Words are rebuilt only when the kind, colour or metres change.
- **`HudPingMarkers`** (`game/ui/hud_ping_markers.gd`, new; outside `touches`, the set's own file as
  `hud_team_markers.gd` is): one marker per character of your team (you included), made once in `Hud.setup_field`,
  refilled from `Pings.of` each frame. Anchors: a spot's floor spot + `ping_spot_height`; a contact's `point` (the
  enemy's chest when seen) + `ping_contact_lift`, so over the head and fixed where they were seen. Behind you or off a
  side, pinned: left stack from `Hud.pin_point()` (under the minimap and What got you), else the right stack; a left
  plate that would pass the feed's top goes right, its arrow still pointing left (the flag marker's rule).
- **`Hud.place_pings`** fills a reused `Stack` after the flag's and Hold here's markers (under their pinned plates on
  the same side) and hides all when not shown: `show` false (you watch someone else), Ping markers off, the
  scoreboard or the summary up. `hide_pings` on the pause menu opening. The layer sits under the minimap (as the flag
  marker). HUD size (`hud_size`) and panel opacity (`HudStyle.restyle`) reach it as the other markers.
- **Minimap:** `HudMinimap.add_pings` after `follow` adds the watched character's team's pings to the `View`
  (preallocated arrays, `capacity` long): a ring in the team colour or a diamond in the other team's, both on the ink
  outline, faded with the marker, pinned to the rim `mark_pad` in when off the panel. Sizes in `MinimapConfig`.
- **The pip:** `SoundConfig.ping_pip_*` (1700 Hz, 0.08 s, gain 0.13: the browser's numbers); `tools/render_whistle.gd`
  renders `assets/audio/cues/ping_pip_1.wav` (plain sine, the whistle's 20 ms attack and 50 ms release, as the
  browser's `beep`); the whistle files re-render byte for byte the same. `SimAudio.on_ping` plays it in your ear on
  the Interface bus when the book's `placed` serial moved and your own ping's time changed (not a mark). The
  teammate's answer is PN1's callout with CO2's radio click, unchanged.
- **Setting:** `HudPrefs.ping_markers` (saved as `ping_markers`, a file without it loads On), a check row on the HUD
  tab under Callouts with its note; `en.po` keys `HUD_PING_MARKER`, `HUD_CONTACT_MARKER`, `SETTINGS_PING_MARKERS(_NOTE)`.
- **PlaySession:** passes `_bots.pings` to the minimap, places the pings after `_show_orders` (through your own eyes
  only), hides them on pause, and hands the book to `SimAudio.on_ping` each tick.

## Risks

- The pinned stack assumes the flag and Hold plates are placed first in the frame (they are, in `_process`).
- Markers over the field don't avoid each other (KNOWN_ISSUES row).

## Defaults taken

- A spot's ring sits over the ping's floor `spot`, not the `point` the view met: the criterion says over the floor, and
  a ping on a wall then marks the floor in front of it, where teammates go.
- A contact's diamond is 0.8 m over the enemy's chest when seen (`point`): over a standing head (about 2.06 m) and
  still over a crouched one; the chest moves with crouch, the feet don't.
- Distance is horizontal, rounded, as the flag and Hold markers read theirs.
- The pop is a scale from 40 % eased out (the overtime flag's rise easing); Reduced motion is `MotionScale.hud_pulse`
  0 (the HUD's motion share), not a new share in `data/accessibility.md`.
- Life and fade run on match time (`state.time`), so a pause holds them, as the browser's "s of play".
- Pinned plates stack 8 px apart (`ping_stack_gap`), not the minimap's 48 px pin step: the plates are 36 px tall and
  several can be up.
- The pinned plate's rule and chevron take the marker's colour (blue ring, orange diamond) rather than the flag's yellow.
- The minimap shows the watched character's team's pings (as its dots): your team's unless the Dev setting spectates
  an enemy. The on-screen markers are yours only and hide while you spectate.
- One pip variant: an interface cue has no pitch or level spread, so variants would sound the same.

## Measurements

- `Hud.place_pings`, headless, 10 characters: 5.5 µs a frame with no ping up, 24 µs with 5 up (mixed field and pinned).
- No object or node made over 100 frames with none up, and no object with two up (one pinned); markers made once
  (`test_markers_are_made_once_one_per_teammate`).

## Pictures

Engine renders of a real `PlaySession` on Depot (Compatibility, Xvfb, 1920 × 1080), your spot 9 m out and a teammate's
Contact mark on an enemy brought 13 m out:

- `/mnt/project-files/screenshots/step27/pn2-field.png`: the whole frame, ring, diamond and minimap.
- `/mnt/project-files/screenshots/step27/pn2-spot-ring.png`: the ring with "PING · 9 M" (2× crop).
- `/mnt/project-files/screenshots/step27/pn2-contact-diamond.png`: the diamond with "CONTACT · 13 M" (2× crop).
- `/mnt/project-files/screenshots/step27/pn2-minimap.png`: the minimap's ring and diamond ahead of your arrow (2× crop).
- `/mnt/project-files/screenshots/step27/pn2-offscreen.png`: turned away, both pinned under the minimap with chevrons.

## Verified

- `tests/unit/test_ping_markers.gd` 21 pass: ring and diamond, colours, words, anchors, never following, pop / 7 s /
  fade, Reduced motion, pinned left / right / behind and under a pinned flag, hidden spectating / scoreboard / pause /
  Off, other team's never, HUD size and opacity, the minimap's (and Off), the rim, the pip once for your own ping only,
  the pip file matching SoundConfig, the setting (default, saved, old file, the tab's row), made once, no allocation,
  freed with the HUD, and a real match showing it on screen, on the minimap and piping.
- Touched files' tests (19 files, 274 tests) pass: callouts feed and QA, minimap, HUD prefs and size, MM4, SO4,
  settings, whistle, pings, footsteps, sound mix, flag play, overtime flag play, What got you, AC1/AC5/AC6.
- `tools/check.sh` (2026-10-26): gdlint, changelog notes, wiki, unit parts 2 and 3, smoke test and licence notices
  pass; part 1 failed only `test_assets.gd`'s cue count (394, now 395 with the pip), fixed and that file rerun green
  (3442 of 3443 passing before the fix).
- gdlint clean on every changed file; the pictures above, looked at.
- Not verified: how the pip sounds on speakers or headphones, and the pop's feel at real frame rates (PLAYTEST ›
  Ping markers).
