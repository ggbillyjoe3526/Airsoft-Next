Task: HD2 · head 1877de8 · Verdict: Pass
Run: headless `--smoke --perf` on copies (git archive) of head 1877de8 and of the diff base 05ab632 (not /home/claude/bp-read, which is bad13b6, 7 commits older). Smoke is time-driven, so frame counts differ (base 2628, head 3898, 7 vs 8 rounds); no seed to pin. Budget: no baseline yet, judged against targets and the base run.
Metrics: steady nodes 640 / 639 (+1, the new _hit_hold slot; ok); orphans 0 / 0 (ok); nodes_max 1115 / 1115 and orphans_max 821 / 821 (both runs, same transient peak, so not from this diff); draw calls 0 (headless, not measurable); frame times not measured (no GPU).
Regressions (> 10 % worse): none
Blocking findings: none. Read in game/ui/hud.gd and game/ui/match_summary.gd:
- _seat_middle (hud.gd:1191) and _hang_cards (hud.gd:1201) are signal-driven (top.resized, middle.sort_children, hud resized, show_xp), not per frame. They do float arithmetic and offset writes only: no allocation, no string building. MatchSummary.set_top (match_summary.gd:117) early-outs on an unchanged value, so repeated calls are cheap.
- The 3 new connections (hud.gd:298-300) are made once in setup() and join HUD-owned nodes (top, middle, self), freed together with the HUD; no teardown disconnect needed. setup_range only calls _seat_middle, with no new connect.
- No nodes per round: _hit_hold is built once in setup() (hud.gd:234); the XP card is still created per match and freed in hide_xp (_xp set to null on free, so _hang_cards cannot touch a freed node).
- No re-sort loop: _hang_cards writes only to nodes that are not children of middle (round table, XP card, summary panels), so it cannot retrigger its own sort_children.
Advisory:
- hud.gd:833-835 (judgment): while the hit call and a banner show together, update() calls get_combined_minimum_size() twice and get_theme_constant("separation") every frame. Short window (eliminated/between rounds), cached label sizes, no allocation, and the custom_minimum_size write is a no-op when unchanged. Could be set once on the hit_call rising edge if you want it tidier; not needed.
- hud.gd:818 hides _top while the summary shows, so _top.resized does not fire then and the stack keeps its last seat (correct, nothing recomputed); worth one QA look that it re-seats when the bar returns.
Fixes: none needed.
Unexplained: orphans_max 821 / nodes_max 1115 appear identically on base and head (existing startup/teardown transient, not caused by HD2).
