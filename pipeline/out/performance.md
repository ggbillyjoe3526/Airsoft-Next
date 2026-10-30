Task: FB6 · head ed36aab · Verdict: Pass
Run: headless smoke match with --perf on ed36aab and origin/main (own worktrees, removed); no baseline yet in pipeline/perf-budget.json, judged against targets and origin/main
Metrics: nodes_max 1115 / 1115 (ok), orphans_max 821 / 821 (ok, identical, load-time peak, final orphans=0 in both), final nodes 264 / 264, draw calls n/a (no GPU), smoke ok on both. Frame count differs (2317 vs 1353) because the smoke run is event-paced; frame times not comparable here.
Regressions (> 10 % worse): none
Blocking findings: none
Advisory:
- game/play/aim_follow.gd:20-22 (judgment): per-frame cost is one id compare, Elimination.is_in_play, Aiming.raise_time (two field reads, one array index) and move_toward. No allocation. AimFollow is a RefCounted held by PlaySession (play_session.gd:177), freed with the session.
- game/play/play_session.gd:1013-1018 (judgment): no new Array, Dictionary, string or Callable per frame; the ternary `aim if watched == player else player.aim_raise` is a float select. `_eyes.sim_rate` is a plain float assignment.
- game/play/first_person_view.gd:90-92 (judgment): recoil follow now multiplies by sim_rate inside the existing exp(); no extra cost.
- game/play/replica_view.gd:157-162,236 (judgment): aim replaces c.aim_raise in the same expressions; no new work. The optic glass gets the drawn raise (optic_glass.gd:123), so its SubViewport switches on/off up to one frame's worth of raise later; negligible and the update-mode toggling is unchanged.
- game/play/aim_follow.gd:22 (judgment): raise_time is a divisor; a zero aim_raise_time would divide by zero, the same as the sim's own division before (aiming.gd), so nothing new, and the config is 0.15.
Score bar (game/ui/hud_score.gd:39-66, hud.gd:189): the left/right mapping is computed once in setup (_end_of, _block_x, pip x positions); set_score/_draw still redraw only on a value change. _draw's two block rects are a loop of 2 over a cached array, no allocation. Pip and label counts are unchanged (no extra nodes). hud_table.gd team_names is test-only, not called per frame.
Menus after a match (game/main.gd:441-452): _end_play still frees the play session, loading screen and old menus/title path exactly as before (_build_screens at 446; the old screens are freed at 327 when play starts); the only change is _show_menus now always runs. _show_menus only toggles visibility and focus; it connects no signals (connections are in _build_menus/_build_title, run once per build), so no duplicate connections. Orphans return to 0 after the match in both runs.
Fixes: none needed.
Unexplained: none (orphans_max 821 is identical on origin/main, so not in this diff)
Verdict: Pass
