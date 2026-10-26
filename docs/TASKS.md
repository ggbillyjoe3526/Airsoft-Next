# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## OV3 · The overtime flag on screen and in sound (Dev)
when: build order step 27, after OV1
tier: ui
perf: required
touches: game/play/overtime_flag_view.gd, game/play/flag_view.gd, game/play/flag_cloth.gdshader,
  game/config/flag_view_config.gd, game/play/play_session.gd, game/play/whistle_queue.gd, game/play/sim_audio.gd,
  game/config/sound_config.gd, game/ui/hud.gd, game/ui/hud_score.gd, game/ui/hud_flag_marker.gd,
  game/ui/hud_flag_glyph.gd, game/ui/hud_minimap.gd, game/ui/hud_round_result.gd, game/ui/hud_style.gd,
  game/ui/hud_scoreboard.gd, game/ui/announcer.gd, game/config/hud_config.gd, game/config/play_tuning.tres,
  game/ui/text/en.po, tests/unit/, tests/support/field_checks.gd, docs/wiki/Modes.md,
  docs/wiki/HUD-and-Minimap.md, docs/PLAYTEST.md
contract: Simulation and presentation (1); Data, not literals (6)
acceptance:
  1. As `concepts/step27/overtime-flag.png`: the flag rises from the ground in 0.8 s at the spot (none under Reduced
     motion), a chequered off-white (238, 234, 224) and dark cloth on a short pole with a 1 m reach ring round its foot;
     once touched, cloth and ring take the toucher's team colour. Scenery only: no collider, BBs pass through. The
     cloth and ring pass the team-colour hue test until touched.
  2. Three short whistle blasts and the banner OVERTIME · TOUCH THE FLAG for 2.4 s; the score bar's clock reads OT and
     the flag's time left; the scoreboard's heading counts it as Attack / Defend's does.
  3. The marker over the flag is Attack / Defend's plate with the chequered glyph ("FLAG · 12 M"), seen through cover,
     pinned under the minimap when off screen; the minimap shows the glyph at the spot.
  4. A round won at the flag ends with FLAG TOUCHED and the team's line; untouched, DRAW as today. Screen reader
     messages read the overtime and its result.
  5. Built once a match and hidden until the flag goes up; a frame with it down allocates nothing. Pictures of the flag
     up and touched on Depot are posted.
status: open
attempts: 0

## PN1 · Pings: the mark, and how bot teammates take it (Dev)
when: build order step 27, after OV3
tier: core
perf: required
touches: project.godot, game/input/key_bindings.gd, game/input/player_input.gd, game/input/README.md,
  game/sim/player_command.gd, game/sim/simulation.gd, game/sim/game_event.gd, game/config/ping_config.gd,
  game/config/sim_tuning.gd, game/config/sim_tuning.tres, game/ai/pings.gd, game/ai/bot.gd, game/ai/bot_brain.gd,
  game/ai/bot_hearing.gd, game/ai/bot_world.gd, game/ai/bot_controller.gd, game/ai/callouts.gd,
  game/config/bot_config.gd, game/config/bot_tuning.tres, game/ai/README.md, game/ui/text/en.po,
  tests/unit/test_pings.gd, tests/unit/test_key_bindings.gd, docs/wiki/Squad-Orders.md, docs/wiki/Controls.md
contract: Commands (2); Events (3); Data, not literals (6); Headless (9)
acceptance:
  1. `ping` on the middle mouse button in the input map and KeyBindings, rebindable, named "Squad: ping a spot"; the
     defaults test still agrees with `project.godot`. A press fills the next tick's `PlayerCommand.ping` once; at most
     one a character each 0.25 s. Dead on the range and while you are out.
  2. The simulation turns it into a PING event: where the view's ray (recoil and all) meets the field within 120 m,
     or nothing for the sky. It changes no state.
  3. `BotController` resolves it (the browser's `ai/pings.ts`): an enemy within 2.5° of chest or head (0.5 m up close),
     nearer than what lies behind and seen by `BotSenses.visible_part` is a contact; else the spot is the nearest
     walkable floor within 3 m, looked for 0.4 m back toward the pinger. One ping each, kept 8 s, cleared each round,
     in a reused ping book the HUD reads.
  4. Bot teammates take it as a noise heard exactly there, kept 20 s (BotConfig's ping memory); a contact also counts as
     a threat; a bot in a fight, in cover or with a target in view ignores it. One teammate answers: the nearest that
     sets off says Going to your ping, else the nearest that took it says Watching your ping (CO1's rows).
  5. A teammate's Contact call marks the enemy for you as a contact ping by callouts.md's Marks (chance, the team's
     gap), on the callouts' stream, so marks change neither the lines nor play. The browser's `pings.test.ts` and
     `matchSessionPings.test.ts` cases pass in GUT; a tick with pings allocates nothing.
status: open
attempts: 0

## PN2 · Ping markers, the minimap and the pip (Dev)
when: build order step 27, after PN1
tier: ui
perf: optional
touches: game/ui/hud_ping_marker.gd, game/ui/hud.gd, game/ui/hud_minimap.gd, game/config/hud_config.gd,
  game/config/minimap_config.gd, game/config/play_tuning.tres, game/play/play_session.gd, game/play/sim_audio.gd,
  game/config/sound_config.gd, tools/render_whistle.gd, assets/audio/cues/, game/save/hud_prefs.gd,
  game/save/settings.gd, game/ui/settings_hud_page.gd, game/ui/text/en.po, tests/unit/, docs/wiki/HUD-and-Minimap.md,
  docs/wiki/Settings.md, docs/PLAYTEST.md
contract: Simulation and presentation (1); Saves (8)
acceptance:
  1. As `concepts/step27/ping.png`: a spot is a ring in your team's colour 0.3 m over the floor with "PING · 9 M"; a
     contact is a diamond in the other team's colour over the head where they were seen, "CONTACT · 13 M", never
     following them. They pop in over 0.35 s (none under Reduced motion), stay whole 7 s and fade over the last second.
  2. A marker off screen is pinned inside the screen's edge as the flag marker is, under the minimap on the left; hidden
     while you spectate, with the scoreboard up and in menus. HUD size and opacity apply.
  3. The minimap shows the same ring or diamond, on its rim when off the panel.
  4. Your ping plays a soft pip (the browser's recipe, 1700 Hz for 0.08 s, rendered to a cue as the whistles were) in
     your ear; the teammate's answer is its call with its radio click (CO2).
  5. Settings › HUD › Ping markers, On by default and saved: Off hides the markers on screen and on the minimap only;
     pings and answers go on. Markers are made once a session; a frame with none allocates nothing.
status: open
attempts: 0

## MH1 · The magazine hand-off's rules (Dev)
when: build order step 27, after PN2
tier: core
perf: required
touches: game/sim/mag_share.gd, game/config/mag_share_config.gd, game/config/sim_tuning.gd,
  game/config/sim_tuning.tres, game/sim/player_command.gd, game/sim/simulation.gd, game/sim/game_event.gd,
  game/sim/game_state.gd, game/sim/armament.gd, game/sim/character.gd, game/sim/round.gd, game/config/replica_config.gd,
  game/sim/README.md, tests/unit/test_mag_share.gd, docs/KNOWN_ISSUES.md
contract: Commands (2); Events (3); Data, not literals (6)
acceptance:
  1. `PlayerCommand.mag_hand_off` (one press) does what fits now (the browser's `sim/magShare.ts` and
     `magHandoff.ts`): toss to the nearest teammate whose ask to you stands and is in reach, else ask if you are low,
     else refuse with its reason. Low is less than one full spare of the replica in hand; the same rule for every
     character.
  2. An ask goes to the nearest teammate in play within 30 m with a magazine to spare that fits (the replica's class
     in `stats.md`), keeping one full spare of the replica it fights with; it stands 15 s unless a magazine lands
     first. A player asks again 4 s after an ask ends, a bot 20 s after.
  3. A toss needs a clear line within 6 m, eye to chest; it flies 0.3 s plus 0.05 s a metre and lands on the catcher's
     chest wherever they are. Its BBs leave the thrower's spare, only what the catcher's emptiest spare of the replica
     tossed for has room for, and go into it on landing; a catcher out of play or a decided round loses it. At most 6
     fly at once, in a pool made once.
  4. Events MAG_ASK, MAG_TOSS, MAG_CATCH, MAG_LOST and MAG_REFUSED (the reason: nobody near, not low, no spare fits,
     wait, already coming, too far, not now) are appended. Out, or between rounds, a press is refused as not now.
  5. The browser's `magShare.test.ts` and `magShareSim.test.ts` cases pass in GUT; no BB is made or lost but a lost
     toss's (tested); a tick with tosses in the air allocates nothing.
status: open
attempts: 0

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
  5. Settings › HUD › Mag hand-off, On by default and saved: Off hides the line and glyphs only. Screen reader messages
     read the line's notices. The smoke test asks for a mag with no script errors.
status: open
attempts: 0
