# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## AC4 · Sound cues round the crosshair
tier: ui
perf: required
touches: game/play/sound_cues.gd, game/play/play_session.gd, game/play/README.md, game/ui/hud_sound_cues.gd,
  game/ui/hud.gd, game/ui/settings_access_page.gd, tests/unit/test_sound_cues.gd
contract: Simulation and presentation (1); Events (3); Data, not literals (6)
acceptance:
  1. SoundCues (plain RefCounted, fed each tick's events after the step, through the watched character's ears like
     MinimapHearing): FOOTSTEP and VAULT of the other team within step_reach, SHOT of anyone but you within
     max_distance × the replica's heard_scale, CHARACTER_HIT (the hit call) within max_distance; none for your own
     sounds or teammates' steps; one pooled marker per player and kind (AccessibilityConfig's 10), life 1.4 s, fade
     0.6 s, opacity 1 beside you to 0.35 at the edge. Walls are not checked (a muffled sound is still heard).
  2. HudSoundCues draws them on a ring (150 px at 1080p) at their bearing relative to the view, turning as you turn:
     two dots, an arrowhead, a HIT tag (hud-sound-cues.png), in the picked colour and size; off hides it and stops
     feeding. A new round clears them.
  3. GUT: reach and heard_scale; own and teammates' steps ignored; a burst is one marker; fade times; the pool never
     grows; bearing for a sound behind and to the left. A tick and a frame allocate nothing.
  4. The tab's Sound cues rows lose LATER.
status: open
attempts: 0

## AC5 · HUD size and reduced motion
tier: ui
perf: skip
touches: game/ui/hud.gd, game/ui/hud_preview.gd, game/ui/settings_hud_page.gd, game/ui/settings_access_page.gd,
  game/play/motion_scale.gd, game/play/first_person_view.gd, game/play/replica_view.gd, game/play/wind_dust.gd,
  game/play/play_session.gd, game/ui/text/en.po, tests/unit/test_hud_size.gd, tests/unit/test_motion_scale.gd
contract: Simulation and presentation (1); Data, not literals (6); Headless (9)
acceptance:
  1. Settings › HUD gains HUD size (80–150 %, step 5 %) as settings-hud-size.png; the preview follows it. In play
     every HUD part but the crosshair, hit marker and sound cue ring scales by it about its anchor (the HUD root's
     size is the viewport over the scale, so anchors and edges hold); applied at once, also from the pause menu.
  2. MotionScale.of(reduced) gives the motion table's shares; Reduced motion On, or System with the display asking
     for it: sway 0, kick and reload cant × 0.5, lean roll and vault dip and tip × 0.25, no wind dust, the flag
     warning steady; the recoil climb unchanged. Applied at once.
  3. GUT: the HUD's parts' rects at 0.8 and 1.5 stay on screen at 1280×720 and 1920×1080; the camera roll at a full
     lean and the replica's offset after a shot under both settings; the climb equal in both.
  4. The tab's Reduced motion row loses LATER.
status: open
attempts: 0

## AC6 · Screen reader messages for hits and rounds
tier: ui
perf: skip
touches: game/ui/announcer.gd, game/ui/hud_announce.gd, game/ui/hud.gd, game/ui/hud_feed.gd,
  game/ui/settings_access_page.gd, game/ui/text/en.po, project.godot, docs/ARCHITECTURE.md,
  tests/unit/test_announcer.gd
contract: Events (3); Headless (9)
acceptance:
  1. Announcer (plain RefCounted) turns events into lines with the HUD's own words: each hit feed line ("Beta 2
     called HIT · Alpha 3", "You" for the player), your own hit ("You're hit · Beta 2"), round start ("Round 3"),
     round over (winner, reason and score), match over. Lines inside 0.3 s are joined into one message.
  2. HudAnnounce is a Label kept in the accessibility tree but not drawn, accessibility_live POLITE (your hit and the
     match result ASSERTIVE); with Screen reader messages off it is LIVE_OFF and gets no text.
  3. project.godot states accessibility/general/accessibility_support = 0 (Auto: AccessKit runs only while a screen
     reader does, so it costs nothing otherwise); ARCHITECTURE notes it.
  4. GUT: each event's line; the join window; off sends nothing; the label's live mode.
  5. The tab's Screen reader messages row loses LATER; the record lists the owner's NVDA and Orca checks.
status: open
attempts: 0

## AD1 · Adaptive difficulty (Dev)
when: build order step 31, after the late features (owner, 2026-10-22)
tier: core
perf: optional
touches: game/ai/, game/config/, game/save/dev_settings.gd, game/ui/settings_screen.gd, game/play/play_session.gd,
  game/ui/xp_card.gd, game/progress/, tests/
contract: Data, not literals (6); Saves (8)
acceptance:
  1. A Dev switch makes the other team's skill a rating that blends the levels' numbers (the browser game's
     adaptiveDifficulty.ts): up a little after a round or match you win, down after one you lose, within its limits;
     the on/off habits come from the nearest level and stay fixed through a match. It never changes a level's own
     numbers (DECISIONS 2026-10-06).
  2. Your teammates never adapt; an adaptive match gives no XP and stays out of the records.
  3. The rating is saved and the end-of-match card says where the next match starts.
status: open
attempts: 0
