Task: KI1 · head a83dea6 (vs main bad13b6) · Verdict: Pass
Run: headless `--smoke --perf` (the smoke match, not a fixed seed or frame count: it runs until its goals are met), plus a hunt_point micro-timing · budget: no baseline yet (pipeline/perf-budget.json absent), judged against targets and main's run. Machine heavily loaded (load avg 4-8 on 4 cores), so timings are skewed; counts are not.
Metrics: nodes steady 637 / 637 main (ok) · nodes_max 1121 / 1121 (ok) · orphans at steady state 0 / 0 · orphans_max 821 / 821 (load-time peak, identical to main) · draw calls 0 (headless, not measurable) · [smoke] ok on both. Frames 3771 head vs 2466 main: the smoke ends on goals (rounds 9 vs 7, shots 325 vs 212), not a fixed count, so this is a different run length, not a regression; script time per frame is not comparable across them under this load.
hunt_point micro-time (2000 calls, bot 0, default config, loaded machine, 2 runs each): Woodland main 79 / 78 us, head 67 / 76 us; Depot main 100 / 97 us, head 96 / 84 us. No measurable change (the new loop is within noise, if anything slightly faster: one node_at plus a downward scan of at most a few floors per draw replaces is_walkable_at + node_at + linked).
Regressions (> 10 % worse): none
Blocking findings: none
Advisory:
- game/ai/round_planner.gd:156 `_reached_floor`: static, no allocation; cost is one cell lookup plus a scan down its few floors with an O(1) `linked`. At most hunt_candidates x hunt_tries_per_candidate = 240 draws per call (unchanged bound); the call is per hunt-goal pick (bot_movement.gd:446), per bot every few seconds, not per tick. judgment + measured.
- assets/maps/woodland.jpg: 58,632 -> 60,074 bytes (+1.4 KB, +2.5 %); assets/maps total 236 KB, negligible against the 500 MB install budget. measured.
- tools/map_pictures.gd: `add_woods` now also builds BushView, but tools/* is in the export exclude_filter (export_presets.cfg:11), so it ships nothing and runs no game-time code. judgment.
- game/play/foley_tracker.gd:37-50: `_lean_at` (PackedFloat64Array) is resized once per match with the cast; per-tick work is one float compare; `update` takes `now` as a default arg, no allocation. judgment.
- game/play/play_session.gd:965 `_bots.orders.clear()` once at MATCH_OVER; no growth, no node freed. judgment.
- game/main.gd:127,321 and progress.gd: picks recalled once at start, one save_if_dirty at match start and only when map/team changed; two small keys in progress.save. Skipped in smoke and headless. judgment.
- game/map/map_data.gd:666-681 `_spot`: allocates an ["x","y","z"] literal and a stringify only at map parse (twice per map load, not per frame). judgment.
- game/report/report_scrub.gd: one more RegEx, compiled once as a member; possessive and anchored on "://", linear per line; runs only when a report is scrubbed. judgment.
- game/input/player_input.gd:186,235, game/ui/match_options.gd:28-60 (const Dictionary[StringName, Array], `modes_offered` per UI build): no allocation change of note. judgment.
No new per-frame/per-tick allocation, no unfreed node or resource, no unbounded growth, no new material or particle (so no prewarm entry needed), no preset bypass.
Fixes: none needed.
Unexplained: none. Smoke frame count difference (3771 vs 2466) is run-length variance of a goal-based smoke under load, not attributable to the diff; node counts and orphans match exactly.
Bench script (outside the tree): /tmp/claude-0/-home-claude-Airsoft-Next/31fbb162-b6e4-592c-9898-73d95dc67b63/scratchpad/fg/bench/hunt_bench.gd; logs: .../fg/head.log, .../fg/main.log.
