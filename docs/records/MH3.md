# MH3 · Need a Mag on H and the wheel, the line and the toss on screen (Dev)

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified | – | – |

## Goal

The player's side of the magazine hand-off (the browser game's src/magHandoff.ts and ui/magPrompt.ts, MG1) on MH1's
rules and MH2's bots: Need a Mag on H and as the order wheel's fifth item, the radio click for an ask taken, the line
under the crosshair, the glyph by a teammate's chevron, the magazine in the air with its sounds, and Settings › HUD ›
Mag hand-off. Concepts: `concepts/step27/wheel-need-a-mag.png`, `concepts/step27/mag-hand-off.png`.

## Approach

- **Input** (`player_input.gd`, `key_bindings.gd`, `project.godot`): a new action `mag_hand_off` on H, listed after
  ping (rebindable, "SQUAD: NEED A MAG"). `SquadOrder.Kind.MAG` names the wheel's item; `_latch_order` turns MAG into a
  mag latch, never a squad order, only while the wheel may open (`_wheel_allowed`: not on the range, you in play).
  `fill_order` sets `cmd.mag_hand_off` once (OR, so a bot playing you keeps its own press) and keeps `mag_from_wheel`
  for where a refusal shows.
- **The wheel** (`controls_config.gd`, `play_tuning.tres`'s one label line, `hud_order_wheel.gd`): five items, Need a
  Mag at 288° (upper left) with H; `set_mag_toss` swaps its name to Toss a Mag (both names made at opening); `tell`
  shows a hand-off refusal in the middle the way an order's notice shows (notices are now text, not the enum).
- **The line** (`hud_mag_line.gd`, new; a Label on a navy plate at 69 % of the height): once a tick it reads the
  player's MAG_* events (tossed, caught, lost, refused: a 2.5 s notice, to the screen reader as well) and the state:
  the nearest teammate asking you with nothing in the air to them ("Rook needs a mag · 12 m", underlined in your
  team's colour when `MagShare.can_toss_to`), else the teammate your ask stands with or whose toss is in the air
  ("Brick is bringing you a mag"). It fills `marks` (by character id) for the chevrons. A string is made only when what
  the plate says changes; hidden while the wheel is open, under the scoreboard and the summary, and with the setting
  off.
- **Glyph** (`hud_team_marker.gd`, `hud_team_markers.gd`): a small leaning magazine right of the chevron, its corners
  fit once, redrawn only when it changes; `place` takes the marks.
- **The toss** (`mag_toss_view.gd`, new; `figure_models.gd`'s `magazine_mesh`): a pool of `mag_tosses.size()` (6)
  MeshInstance3Ds made once a match, each showing its slot's thrower's replica's own `Magazine` mesh (read once a
  replica), from the hand to the catcher's chest as they are now, arc 0.1 m a metre up to 0.6 m, 2.5 turns a second.
- **Sound** (`sim_audio.gd`): MAG_ASK of yours plays `radio_ack` in your ear; MAG_TOSS `magToss` from the thrower,
  MAG_CATCH `magCatch` from the catcher (the cues were already rendered).
- **Setting** (`hud_prefs.gd`, `settings_hud_page.gd`): `mag_hand_off`, on, saved under "hud"; a file from before
  loads on. Off hides the line and the glyphs only.
- **Match** (`play_session.gd`): `player.mag.player = true` (MH1's QA: your ask gap is 4 s), the line and the toss
  view built for a match (not the range), the HUD told `mag_from_wheel`, `mag_presses` counted for the smoke test.
- Strings in `en.po`; `announcer.gd`'s header names the notices.

## Outside `touches`

- `game/main.gd`: the smoke test's steps press H and pick Need a Mag on the wheel, and it fails without a press of
  yours answered (`mag_presses`): criterion 5's "the smoke test asks for a mag".
- `docs/wiki/Bots.md` (one sentence linking Need a Mag), `docs/KNOWN_ISSUES.md`, `game/play/README.md`: docs.

## Defaults taken

- **Dead while you are out means no press at all,** not a NOT_NOW notice (criterion 1); between rounds you are in
  play, so "Mags wait for the next round" still shows there.
- **"Brick is bringing you a mag" shows from the moment your ask stands with Brick** (the sim names the giver at the
  ask; MH2 sends it when free): the browser waited for the bot's job. A KNOWN_ISSUES row says so.
- **No "Low on BBs · H to ask" hint:** the browser's hint named a key, which the criterion forbids; the line stays empty
  until something happens.
- **The ask taken is MAG_ASK of yours** (the radio click); a refusal, a toss or a catch plays no click.
- **A refusal from the wheel also goes to the screen reader;** only the wheel shows it.
- **The toss's look numbers (0.1 m a metre, 0.6 m, 2.5 turns) are the view's named constants,** as other views keep
  theirs; the flight time is the simulation's (MagShareConfig).
- **The magazine in the air wears its model's own material,** not the thrower's paint (one mesh shared per replica,
  no material per toss); KNOWN_ISSUES.
- **Line style:** Inter 700 at 17 px on the side panels' navy (0.82) with 16 × 7 px padding and a 3 px underline;
  glyph 8 × 17 px, 5 px right of the chevron, leaning 0.2 rad (HudConfig).

## Measurements

Headless on the cloud container, while `tools/check.sh` ran beside it (so on the high side), 12 characters:
- `HudMagLine.on_tick` with five teammates asking you (the nearest's reach checked, one ray): 27 µs a tick; with
  nothing standing 10 µs (0.06 % of a tick).
- `MagTossView.update` with all six magazines in the air: 21 µs a frame, no object made.
- A standing line and its glyphs for 120 ticks make no object (`test_mag_hand_off_hud`). Strings are made only for the
  player's own notices and when the line's words change, never for the bots' MAG_* events.

## Pictures

Engine renders of a real `PlaySession` on Depot (Compatibility, Xvfb, 1920 × 1080), bots idle, the hand-off driven
through the commands:
- `/mnt/project-files/screenshots/step27/mh3-wheel-need-a-mag.png`: the wheel, Need a Mag upper left with H, lit.
- `/mnt/project-files/screenshots/step27/mh3-wheel-toss-a-mag.png`: the same item reading TOSS A MAG in reach; the line
  hidden under the open wheel.
- `/mnt/project-files/screenshots/step27/mh3-line-asking.png`: "Oak needs a mag · 12 m", the glyph by Oak's chevron.
- `/mnt/project-files/screenshots/step27/mh3-line-in-reach.png`: "Oak needs a mag · 4 m", underlined in blue.
- `/mnt/project-files/screenshots/step27/mh3-chevron-glyph.png`: the chevron and its magazine (2× crop).
- `/mnt/project-files/screenshots/step27/mh3-toss-yours.png`: your magazine on its way to Oak, "Mag to Oak".
- `/mnt/project-files/screenshots/step27/mh3-asked.png`, `mh3-toss-in-the-air.png`, `mh3-caught.png`: your ask
  ("Cricket is bringing you a mag"), Cricket's magazine in the air over the arc, and "+1 mag from Cricket · 60 BBs".

## Verified

- `test_mag_hand_off_hud.gd` 22 pass: H rebindable and named, once a press, dead on the range and while out; the
  wheel's fifth item upper left does what H does (Hover and Click) and never gives an order; a bot playing you keeps
  its press; the wheel draws NEED A MAG with H and TOSS A MAG in reach; a refusal from the wheel in its middle, from H
  on the line; the radio click for an ask taken only, the catch sound; the line's words (12 m, 4 m underlined in your
  team's colour, never a key, "Mag to Rook", bringing, caught with and without the BBs, every refusal), 2.5 s notices,
  hidden under the wheel and with the setting off; the glyph for an asker and a bringer, hidden with the setting off;
  no object made by a standing line; screen reader messages; the setting's default, old file and save; the arc, cap,
  landing and spin; the pool of six, the thrower's own magazine mesh, hidden once landed; a match marks you as the
  player and your ask's gap is 4 s.
- Updated for the fifth item: `test_order_wheel_input.gd` (Team Plan now lower left), `test_so4_orders_hud.gd`.
- gdlint clean; `tools/smoke_test.sh` passes (`[smoke] ok … orders=3 mags=2`, zero script errors).
- `tools/check.sh`: see Gate.
- Not verified: how it feels (the arc's readability, the line over bright walls, the catch sound's level) on the
  owner's display and Forward+; PLAYTEST › Squad orders and minimap lists what to try.

## Gate

`tools/check.sh` (worker's run): pending.
