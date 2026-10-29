Task: MH3 · Need a Mag on H and the wheel, the line and the toss on screen
Attempt: 1 of 4
Head: bb43217 (checks: worker's tools/check.sh on 9483ad3 + fix round 001a224 gdlint, MH3 GUT files, smoke; critic re-ran test_mag_hand_off_hud 23/23, test_mh3_qa 8/8)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. H rebindable, named: key_bindings.gd:20,54, project.godot mag_hand_off, en.po ACT_MAG_HAND_OFF; fifth item upper left: controls_config.gd:33-39;
   Toss a Mag: hud.gd:937 + hud_order_wheel.gd:155; same press: player_input.gd:229; dead on range/out: player_input.gd:231 (_wheel_allowed,
   play_session.gd:768). Radio click: sim_audio.gd:215; refusal in the wheel's middle: hud_mag_line.gd:113, hud_order_wheel.gd:150; from H on
   the line: hud_mag_line.gd:118. Line at 0.69, 2.5 s: hud_config.gd:108-111; underlined in team colour: hud_mag_line.gd:74,232; hidden under
   the wheel: hud.gd:940; glyph: hud_team_markers.gd:69. Toss: mag_toss_view.gd:12-14,95, pool made once :60-65, thrower's slot mesh :107;
   magToss/magCatch: sim_audio.gd:218,221. Setting: hud_prefs.gd:55,100; screen reader: hud_mag_line.gd:177; smoke: main.gd:618;
   player's 4 s gap: play_session.gd:457.
2. Contracts 1, 2, 8 kept: the line only reads state (MagShare.nearest_asker / can_toss_to between ticks), commands carry the press,
   prefs save through HudPrefs/SaveFile. SquadOrder.Kind.MAG appended and never reaches cmd.squad_order.
3. No per-frame/tick allocation: strings only on your own events or when (says, who, metres) changes (hud_mag_line.gd:226-230);
   toss view and markers use values and preset arrays; matches QA and performance.
4. test_mag_hand_off_hud.gd:530 fails without play_session.gd:457; :492 fails without the spin; test_mh3_qa.gd:115 pinned the QA bug.
Advisories (non-blocking):
- player_input.gd:45 `const MAG` is never read (H goes through wheel_keys); drop it.
- settings_hud_page.gd:7 (151 chars) and sim_audio.gd:15 (142) break the 120-column wrap of the doc comments.
- The performance verdict is on 9483ad3; the fix 001a224 (hud_mag_line.gd:197-203) adds at most one ray per asker nearer than
  the best, read here, no allocation. pipeline/out/performance.md must be committed with the records.
- QA's note stands: the in-air WAIT wording reads the pool after the step (hud_mag_line.gd:111-112); harmless.
Owner should test in the game:
- Run low, press H: radio double-click, "X is bringing you a mag", glyph by X's chevron, the arc and spin into your hands, catch sound.
- A bot asks you: "X needs a mag · 12 m", walk in until the underline shows, H tosses; is the underline noticeable?
- Hold Z: Need a Mag upper left with H, Toss a Mag when in reach; a refusal picked there shows in the middle only.
- The line over bright walls and while spectating; hidden while the wheel is open.
- Settings › HUD › Mag hand-off Off: no line or glyphs, H still works.
- The magToss/magCatch level against gunfire.
