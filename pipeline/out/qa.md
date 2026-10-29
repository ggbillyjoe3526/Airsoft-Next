Task: MH2 · QA commit (see git log, "MH2: QA tests") · Verdict: Pass

Blocking: none.

Advisory:
- Criterion 5: it says KNOWN_ISSUES' magazine sharing row goes; the worker replaced it with a narrower row (a bot asking you
  before MH3, a busy giver's and a pole-bound giver's asks standing unanswered). Reasonable, but the lead should accept it.
- A bot giver that has its own ask standing never takes a job (bot_mag_share.gd:129, `me.mag.asked < 0`), so an ask to it
  stands its 15 s unanswered: a third unanswered-ask case, not in the KNOWN_ISSUES row.
- The criterion 4 guard (test_match_guards.gd MagWatch) marks a bot "held" if its giver was in FIGHT or COVER at any tick of
  the 10 s, however briefly, so the allowance of 2 per field (MAG_HELD_MAX) could hide a real stall that coincides with a
  short fight; it re-checks "nobody to ask" only at the timeout. Measured: 1 held on Depot (seed 16), 0 on Woodland, so the
  allowance is not being used up. 14 of 55 Depot bots are left out as hit or round over (25 %).
- A bot waiting for a bot giver stands in the open for as long as the giver fights or sits in cover (up to the 15 s ask).

Checked and sound:
- A low bot presses at most once a second and never storms MAG_REFUSED: 0 refusals in 6 full Depot and 2 Woodland matches
  with the Dev setting on (the asker's check mirrors MagShare._ask exactly); two askers for one giver: both served, 0 refusals.
- Priorities fight/cover > bringing > order > pole > waiting (code read; new cover test); sprint over 8 m, walk to 3 m and the
  wall case (existing tests pass); giver or asker hit mid-walk, round end mid-walk: jobs and asks let go, asker plays on,
  nothing pressed after, new round starts clean.
- Asks only for the primary, an unused pistol given freely, the three calls, Bot intentions labels (enum order and en.po keys
  match), no per-tick allocation (existing test; code read).
- Dev setting off = identical: event and position hash, ticks, rounds, hits and shots equal to 9fbce06 for Depot seeds 1-4 and
  Woodland seeds 1-2 (whole matches; 0 asks occur naturally).
- Criterion 4 guard run: passes, Depot 33 served (max 9.6 s), Woodland 47 served (max 4.7 s), 0 late; matches the record.
  No neonHeights references added.

Tests added (tests/unit/test_mh2_qa.gd, 6, all pass; none can pass at 9fbce06 because bots never press there, so
mag_for, asks and tosses are never set):
- test_a_giver_hit_mid_walk_lets_go_and_the_asker_plays_on_without_a_press
- test_an_asker_hit_mid_walk_frees_the_giver_to_go_on
- test_the_round_ending_mid_walk_clears_the_jobs_and_the_next_round_starts_clean
- test_two_askers_for_one_giver_are_both_served_and_neither_press_storms
- test_a_giver_who_cannot_toss_yet_presses_no_more_than_once_a_second
- test_a_giver_in_cover_stays_there_until_the_cover_episode_is_over_then_brings_it

Runs: test_bot_mag_share 20/20; 22 touched files plus mine 368/368 (481 s); match guard (criterion 4) pass; gdlint clean on
changed files. Not run: tools/check.sh and smoke test (told not to); how it plays and the Dev row on a display.
