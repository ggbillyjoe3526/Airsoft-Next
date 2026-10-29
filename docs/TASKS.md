# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## MH2 · Bots ask for magazines and bring them (Dev)
when: build order step 27, after MH1
tier: core
perf: required
touches: game/ai/bot_mag_share.gd, game/ai/bot.gd, game/ai/bot_brain.gd, game/ai/bot_movement.gd,
  game/ai/bot_controller.gd, game/ai/callouts.gd, game/ai/README.md, game/config/bot_config.gd,
  game/config/bot_tuning.tres, game/play/bot_intent_view.gd, game/sim/dev_cheats.gd, game/save/dev_settings.gd,
  game/ui/settings_screen.gd, game/ui/text/en.po, tests/unit/test_bot_mag_share.gd, tests/guards/test_match_guards.gd,
  docs/KNOWN_ISSUES.md, docs/wiki/Bots.md
contract: Commands (2); Data, not literals (6)
acceptance:
  1. A bot that is low presses the hand-off through its command (the browser's `ai/magShare.ts`); a bot asked sets
     off: it sprints while over 8 m away, walks on to within 3 m, and presses once the catcher is in reach and in sight.
     Fights and cover come first, then bringing one, then a squad order, then waiting for one. Asked by you, it walks to
     within 3 m and waits for your toss.
  2. Bots ask only for their primary's magazine and give an unused pistol's freely; the same at every level.
  3. Need a mag, Mag coming and Thanks for the mag are called through CO1's director (Thanks only after a catch with
     BBs in it); Bot intentions shows the hand-off.
  4. Settings › Dev › Bots run low on BBs (off): 8 s into each round, one bot a team in turn is put on its last
     magazine. With it on, a bot put low on Depot, Woodland and Neon Heights gets a magazine within 10 s on the guard
     seeds (the record gives the times and the givers' walks).
  5. The browser's `magShare.test.ts` (ai) and `magShareRules.test.ts` cases pass in GUT; the match guards still pass;
     KNOWN_ISSUES' callouts, pings and magazine sharing row goes.
status: open
attempts: 0

## MH3 · Need a Mag on H and the wheel, the line and the toss on screen (Dev)
when: build order step 27, after MH2
tier: ui
perf: required
touches: project.godot, game/input/key_bindings.gd, game/input/player_input.gd, game/sim/squad_order.gd,
  game/config/controls_config.gd, game/config/play_tuning.tres, game/ui/hud_order_wheel.gd, game/ui/hud_mag_line.gd,
  game/ui/hud.gd, game/ui/hud_team_markers.gd, game/ui/hud_team_marker.gd, game/play/mag_toss_view.gd,
  game/play/figures/figure_models.gd, game/play/play_session.gd, game/play/sim_audio.gd, game/config/sound_config.gd,
  game/config/hud_config.gd, game/save/hud_prefs.gd, game/save/settings.gd, game/ui/settings_hud_page.gd,
  game/ui/announcer.gd, game/ui/text/en.po, tests/unit/, docs/wiki/Squad-Orders.md, docs/wiki/Controls.md,
  docs/wiki/HUD-and-Minimap.md, docs/wiki/Settings.md, docs/PLAYTEST.md
contract: Simulation and presentation (1); Commands (2); Saves (8)
acceptance:
  1. `mag_hand_off` on H, rebindable, named "Squad: need a mag"; the order wheel's fifth item Need a Mag, upper left
     with its key (`concepts/step27/wheel-need-a-mag.png`), reading Toss a Mag while a teammate asking you is in reach.
     Picked on the wheel it does what H does. Dead on the range and while you are out.
  2. An ask taken plays the radio double-click; a refusal from the wheel shows in its middle as order notices do, from
     H on the hand-off line.
  3. The hand-off line under the crosshair (69 % of the height), as `concepts/step27/mag-hand-off.png`: who needs a mag
     and how far (underlined in your team's colour once in reach), whose is coming, what you caught, and why not, 2.5 s
     for a notice; never a key or a control. Hidden while the order wheel is open. A magazine glyph by the chevron of a
     teammate asking you or bringing you one.
  4. The tossed magazine is the thrower's replica's own magazine mesh, arcing 0.1 m a metre of toss up to 0.6 m and
     spinning 2.5 turns a second to the catcher's chest, in a pool of 6 made once; `magToss` from the thrower and
     `magCatch` from the catcher.
  5. The match sets the player's `Character.mag.player`, so the player's ask gap is 4 s, not a bot's 20 s (MH1 QA).
  6. Settings › HUD › Mag hand-off, On by default and saved: Off hides the line and glyphs only. Screen reader messages
     read the line's notices. The smoke test asks for a mag with no script errors.
status: open
attempts: 0
