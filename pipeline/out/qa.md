Task: AB1 · re-check of 46493f3 (diff 395a152..46493f3) · QA commit none (tests/unit/test_ab1_qa.gd uncommitted) · Verdict: Fail

Blocking
1. tests/unit/test_overtime_bots.gd:107 and :113 call BotFlag.spot(w); the signature is now spot(b, w) (game/ai/bot_flag.gd:73). The file fails to parse, so Elimination's overtime-bot tests do not run at all (Elimination coverage lost). Fix: BotFlag.spot(list[0], w) in both places.

Checked, no bug
- One pole / Elimination: pick_retakers is called only in Attack / Defend; in Elimination role is NONE so retake_pole stays -1, pole_of is 0 and spot is the overtime foot while it is up. flag_pole default -1 is handled by on_worked_rope (<0 returns false) and _flag repicks once.
- retake_pole range: always set from a pole index; reset every tick before use; on_worked_rope guards flag_pole against flags.size() before indexing. Shrinking poles with a stale pick is re-picked first (pinned).
- Defender released when its flag reaches the bottom: wants_flag false, rope IDLE, pole_of falls back to the pole in play (pinned).
- Squad orders: _free_defender excludes ordered bots from both the on-rope pass and the fill, even on a worked rope (pinned).
- HUD: _shown_pole is kept inside the round's poles (next_in_play checks range, PlaySession clamps). _flag_eye is zero until the first place_flag_marker call, so the first frame picks the pole nearest the origin (cosmetic, one frame).

Advisory
- wants_flag reads w.flags[b.retake_pole]; with retake true and retake_pole -1 (only a hand-built fixture, e.g. test_fg2_qa.gd:101) it reads the last flag via negative indexing, silently.
- pick_retakers now runs every tick even with the flag at the bottom, so b.retake is true for nearest defenders at a bottomed flag; wants_flag gates it, so no behaviour change.

Tests added (tests/unit/test_ab1_qa.gd, 13 tests, all pass): both flags same tick scores once; overtime on B rope; defender at A cannot stop B; Elimination ignores flags; flags array resize keeps one object; BotWorld stays in range; one-pole planner; flags-list file edge cases; Depot poles standable and clear; 100 s Depot bot match shows no pole flipping and both flags going up; Elimination picks no retakers; defender released at the bottom and no out-of-range pole; ordered defender not sent. Each new test passes before and after the change where it pins a regression; those needing two poles fail on the old one-pole API.
Suite run: only touched/related files (test_two_flags 18, test_ab1_qa 13, fg2 6, bot_flag 14, squad_orders 14, so1_qa 22, flag_play 14, fg1 13, hud_minimap 17, overtime_flag 19). Not run: tools/check.sh, smoke test, whole suite.
