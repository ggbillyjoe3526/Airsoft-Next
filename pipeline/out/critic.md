Task: FB6 · Back to the Match page, your team on the left, the sight even at any game speed (fix)
Attempt: 1 of 4
Head: 8aae085 (gates green on 01ed47f; 8aae085 adds only QA's test_fb6_qa.gd probes and qa.md, 22/22 run by QA)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✗
Score: 7/8 → Accept (QA Pass after fix round 1; performance Pass on ed36aab, the fix round touched only aim_follow.gd's snap)
Evidence:
1. A: main.gd:450 `_show_menus()` on every leave (Play focused, picks kept). B: hud.gd:189 passes player.team; hud_score.gd:55-58
   place each team's block, pips, score and tag at `_end_of(side)`, :203-204 colours by team; Tab, round table, summary already
   yours first (pinned). C: aim_follow.gd:21-33 drawn raise at the sim's own raise speed over sim time; play_session.gd:1013-1018
   feeds the camera (first_person_view.gd:110), the replica (replica_view.gd:157,162) and the glass (:236); recoil over sim time :92.
2. No contract in ARCHITECTURE › Contracts covers HudScore, the views, Aiming or the leave path.
3. aim_follow.gd:21-33 floats only; play_session.gd:1013-1018 no new objects; hud_score `_block_x` built once in setup.
4. test_fb6.gd:185 asserts an equal step and a narrower FOV every frame at 25-200 %: the old view holds 3 frames in 4 at 25 %
   (the control at :175 proves it); :28 and :68 fail on main (record). QA's respawn pair (test_fb6_qa.gd:357, :370) pins the fix.
5. AimFollow is a pure RefCounted; Aiming.raise_time (aiming.gd:19) is the tick's own formula, so view and sim can't drift.
6. Normal speed is unchanged where it matters: at 100 % and 30/60 fps drawn == sim (QA measured 0) and the recoil formula is the
   old one at rate 1.0; above 60 fps it trails by at most a tick (~16 ms) where main stepped. Toy feel untouched.
Failed checks, with evidence:
8. [judgment] The owner's two standing rules (leaving lands on the Match page; your team on the left, through half time) are
   cited as "(owner, 2026-10-29)" in main.gd:448 and hud_score.gd:8-9 but not added to docs/DECISIONS.md, as FB1 and FB4 did.
Must-fix before the push (non-blocking): one DECISIONS.md entry "(owner, 2026-10-29; FB6)" for A and B.
Advisories:
- hud.gd:867 still hides the crosshair on the sim's aim_raise < 0.5: at 25 % it can vanish up to 3 frames before the drawn
  zoom crosses half. Feed it the drawn raise if the owner notices.
- aim_follow.gd:26-27 reads PlaySession.TICK, a node class's constant, from a pure helper; the tick length belongs in sim.
- PAUSE_TITLE_SCREEN now reads "Back to the menus"; rename the key when next touched.
- pipeline/out/qa.md (and this file) are committed on the branch; strip pipeline/out/ before the push (never committed).
- Run tools/check.sh on the final head (8aae085's probe tests were run alone, not in a full unit run).
- QA: below raise_scale 0.8 (not in today's data) a respawn still eases a few frames; revisit if a faster part lands.
Owner should test in the game:
- Quit match and Leave practice: the Match page with PLAY focused; AIRSOFT still opens the title.
- As Beta: score bar BETA (orange) left, ALPHA right, still so after half time; as Alpha unchanged.
- ADS at 25 % and 150 % with irons, red dot and 2x scope: zoom and replica rise smoothly, no stutter or uneven jumps.
- ADS at 100 % on a 144 Hz screen: feels as before (no added float or lag).
- Fire aimed at 25 %: the climb eases between ticks, never steps.
