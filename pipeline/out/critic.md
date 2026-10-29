Task: HD2 · HIT! over the score bar when your hit ends the round (Fix, Dev 1 bug pass)
Attempt: 1 of 4
Head: 724357c (checks: worker gdlint, targeted 102, unit part 1 885/885, smoke, wiki/changelog on bf3b903; QA 24 HD2 tests on 724357c, which adds only QA tests; CI runs parts 2-3)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. Brief met: the stack hangs MIDDLE_GAP under `_top`'s real bottom (hud.gd:1225), from MARGIN while the summary hides the bar (hud.gd:1222-1228); the cards hang XP_GAP under its foot and fit the height left (hud.gd:1234-1245, 558, 566, floor hud.gd:42); the slot keeps the banner still (hud.gd:865) and the next banner clears it (hud.gd:1149). Pictures hd2-after-*.png and hd2-qa-150-cards.png show HIT! and LOST clear of the bar and the table on screen at 150 %.
2. No contract in ARCHITECTURE › Contracts names the HUD layout; `MatchSummary.set_top`/`column_height` are additions (match_summary.gd:117, 126).
3. Signal-driven seat/hang (hud.gd:301-303); the per-frame `_fit_summary`/`_fit_round_result` in update (hud.gd:832-837) read cached minimum sizes and write scale only on change (set_fit early-outs): no allocation. The slot is measured once on the rising edge. QA and performance: Pass.
4. test_hd2_hit_call_stack.gd `test_the_banner_keeps_its_place_as_the_hit_call_ends` fails without `_hit_hold` (the banner rises by the call's height); QA's stale-slot and on-screen-at-150 % tests fail on 1877de8.
5-8. Presentation only, typed, constants named (MIDDLE_GAP, CARDS_FIT_FLOOR); no new nodes per round; record, changelog note and PLAYTEST line present; the wiki never placed the call, so no page change.
Advisories (non-blocking):
- When the round's table gives way to the match summary the bar hides and the stack (the match banner) jumps up to MARGIN, about 110 px at 1080p; the slot avoids that jump at the call's end but not here. Owner's call.
- hud.gd is 1257 lines; a later Beta tidy could move the stack and card hanging into a small HudMiddle helper.
- performance.md was measured on 1877de8, before the fix round; the round's added per-frame fit was read here (no allocation), not run.
- A hit call arriving while a banner is already up pushes the banner down by the call's height (QA advisory).
Owner should test in the game (Forward+):
- Be the last of your side hit: HIT!, the walk-off line and LOST stack under the score bar, none over the clock.
- Let the walk-off end with LOST up: LOST does not jump; the next round's ROUND 2 banner sits right under the bar.
- Same at HUD size 150 % on Attack / Defend (FLAG gauge): the round's table stays on screen and readable.
- Finish a match: the summary and XP card fit under the match banner; note whether the banner's jump up as the summary opens bothers you.
- Resize the window mid-summary (and 4:3 / ultrawide): cards stay on screen.
- HIT! sits higher than before, near the bar: does it still read in a fight?
