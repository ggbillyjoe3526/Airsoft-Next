Task: DR1 · head 93e3d55 (HEAD now c9f8bea, QA tests only) · Verdict: Pass
Run: headless, smoke match (Depot, seed 1, x8) with --perf on head and on origin/main (worktree), plus MatchRunner bot matches (3 seeds x 3600 ticks) · budget: no baseline yet, judged against targets and origin/main. Machine: 4 cores, load 2-3.5 from other Godot runs; timings noisy (about +-20 %).
Metrics (--perf, headless, so draw calls 0): nodes_max 1137 / 1057 main (+7.6 %, 10 vs 6 characters; roof adds 3), orphans_max 792 / 792 (same as main), static memory not logged.
Sim script time per tick (bot match, 60 s, MatchRunner): head 5v5 1.84-2.49 ms (mean 2.1) vs main 3v3 0.85-1.18 ms (mean 1.05); per character 175-250 vs 142-197 us (+20 %, inside noise). Share of a 16.7 ms tick: about 13 %.
Bot sight 55 m vs 40 m on the same hall (botSight zeroed): 2.36/1.81/1.93 ms vs 2.49/1.84/2.00 ms, a 2-4 % difference, within noise.
Build cost: MapLevel.build 18 ms vs 6 ms on main (117k-vertex bake, bake accepted, no warning), RoofView.build 1.6 ms (9 ms first), load_map 10.5 vs 4.7 ms. Smoke wall 90 s / 2285 frames vs 52.6 s / 3731 frames: not comparable (different match, 815 vs 385 shots, 5v5 vs 3v3).
Regressions (> 10 % worse): none attributable. Per-tick time doubled with the roster (10 vs 6 bots), not per bot.
Blocking findings: none. Checked: RoofView is built once, nothing per frame; ceiling and trusses are one mesh and one material, lamps one MultiMesh, both cast no shadow; its materials are in the first_use prewarm (play_session.gd:699-700); it is a PlaySession child, freed with it (no orphans added); one BotConfig copy per controller (bot_controller.gd:46), once per match; no preset bypass (shadow distance stays 70 m).
Advisory:
- game/map/map_level.gd:177-183: _add_ceiling was inserted between _add_ground_tiles' doc comment and its function, orphaning that comment (judgment, doc only).
- game/map/map_level.gd:182-194 and game/play/roof_view.gd:60-68: the same footprint loop twice; share RoofView.field_rect (judgment).
- game/play/roof_view.gd:41: CULL_DISABLED draws both faces of the ceiling and trusses; opaque and unshaded so cheap, but the ceiling fills the screen when looking up: check fill on the Low preset on real hardware (judgment).
- Draw calls and frame time not measurable here (no GPU): the roof adds 3 draw calls (ceiling, lamps, plus shadow passes unchanged); 217 blocks stay one greybox draw call plus the shadow caster. Owner to confirm on hardware with F3, and the 6v6 case (not run).
Unexplained: none.
