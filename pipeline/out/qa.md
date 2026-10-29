Task: MH3 · QA commit (see git log, "MH3: QA tests") · Verdict: Fail (first round; see the re-check below: Pass)

Blocking
1. game/ui/hud_mag_line.gd:186-203 (_standing): the line and the wheel pick the NEAREST asker and check reach for that one only;
   the simulation's press (MagShare._nearest_asker, mag_share.gd:375-388) tosses to the nearest asker IN REACH. With Rook asking
   from 4 m behind a wall and Brick asking from 5 m in the open, a press tosses to Brick, but toss_ready() is false: the wheel's
   fifth item reads Need a Mag (criterion 1: Toss a Mag while an asker is in reach) and the line names Rook, not underlined.
   Fix: choose the nearest asker for which can_toss_to holds; else the nearest asker.

Advisory
- Smoke test's `mags` counts MAG_ASK/TOSS/REFUSED of the player id; with a bot playing you, the bot's own press can satisfy it
  even if the H or wheel step were dropped (play_session.gd _after_tick). Weak guard, not wrong.
- HUD_MAG_WAIT ("Ask again in a moment") is also the refusal for a toss blocked by your own magazine in the air; wording is off.

Everything else checked, no bug: H and the wheel's fifth item share _latch_order; dead on the range and while out; H alone on H in
defaults and the input map; refusal from the wheel in its middle, from H on the line; hidden under the open wheel; no key in any
string; 2.5 s notices to the screen reader; glyph clears on ask lapse, catch and asker out; pool of 6 made once, thrower's slot
mesh, lands at the chest, lost toss hidden; magToss/magCatch cues exist and play from thrower/catcher; setting On by default,
saved, old files On; player ask gap 4 s; no string per bot MAG_* event; smoke passes (orders=3 mags=2, zero script errors).

Tests (tests/unit/test_mh3_qa.gd, 8)
- :115 wheel/line vs the sim's pick, nearer asker walled off · FAILS on the current code (the bug above; the sim half passes)
- :142 glyph/line clear on ask lapse and asker out · pins; fails if marks or text are left standing
- :170 wheel item back to Need a Mag once the toss is in the air · pins
- :185 each toss wears its thrower's slot/replica mesh (cyber rifle slot 0, pistol slot 1) · fails if the slot key is dropped
- :214 aeg, cyber, pistol models each have a Magazine mesh · pins
- :220 lost toss (catcher out) and round decided hide the copy · pins
- :255 toss ends at catcher's chest · pins
- :276 H on no other default action nor in the input map · fails if another action takes H
Not stubbed out one by one for the pins; they were checked by reading the code path they assert.

Runs: test_mh3_qa 7/8 (1 intended failure); test_mag_hand_off_hud 22, order_wheel_input 17, so4_orders_hud 23, key_bindings 18,
hud_prefs 13, mag_share 29, bot_mag_share 20, play_session 9: all pass. Smoke passes. Full tools/check.sh not run (told not to).
Not testable headless: how the arc, line over bright walls and the sounds' level look and sound (owner's list in PLAYTEST).

## Re-check of fix round 001a224 · QA commit (git log, "MH3: QA re-check") · Verdict: Pass
- Blocking bug 1 fixed: HudMagLine._standing now uses the public MagShare.nearest_asker (nearest in reach, else nearest), the
  press's own pick; tests/unit/test_mh3_qa.gd:115 now passes (8/8). Marks still cover every asker; no allocation added.
- Advisories fixed: WAIT wording split (own mag in the air, toss again, ask again); the smoke test counts only presses of yours
  (PlayerInput.mag_sent is set per fill_order, true only on the tick of a latched press). Minor: the in-air wording reads the
  pool after the step, so a toss that landed the same tick would say the generic toss wait; harmless.
- Runs: test_mh3_qa 8, mag_hand_off_hud 23, mag_share 29, bot_mag_share 20, order_wheel_input 17, so4_orders_hud 23, play_session 9,
  key_bindings 18: 147 of 147. Smoke passes (orders=3 mags=2, zero script errors). No regressions found in the diff.
