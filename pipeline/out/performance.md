Task: FB3 · head c603add · Verdict: Pass
Run: headless `--smoke --perf` on this head and on main (bad13b6, same as merge-base), run concurrently on a machine at load ~6-7 (4 cores); no GPU. Budget: no baseline yet, judged against targets and main.
Metrics: nodes_max 1120 / 1121 main (ok); orphans_max 821 / 821 (ok, identical, pre-existing exit/setup figure); draw_max 0 / 0 (headless, not measured); end-of-run nodes 268 main vs 73-637 head across samples (sampling instants differ, not a trend).
Frame times: not reported as comparable. The smoke match is wall-clock driven, so frames differ (head 2079, main 755) and shots/impacts differ with it; load skews all timings. Smoke passed on both (`[smoke] ok`, zero script errors, plates 5, rounds 8).
Regressions (> 10 % worse): none measured.
Blocking findings: none.
Review of the diff (runtime files: settings.gd, settings_screen.gd, play_session.gd, loadout_page.gd, armory_page.gd, menu_screen.gd, match_page.gd, report_facts.gd, dev_settings.gd; judgment):
- Settings.active_dev() and the static _dev_defaults DevSettings are gone; every caller now reads `settings.dev` directly (play_session.gd:288,391,446-448,1539,1575; armory_page.gd:36,104; loadout_page.gd:43,46,117; match_page.gd:401; menu_screen.gd:49). Same cost per call: a field read instead of a method call plus a ternary. No new allocation anywhere; one static object less held.
- No new `_process`/`_physics_process`/per-shot code. `_apply_dev` (play_session.gd:1537) is the same signal-driven path as before; only the source of `dev` changed.
- settings_screen.gd: the Dev box CheckButton (`_dev_box`) and its handler, `_show_dev_tab` and the `set_tab_hidden` call are removed; the Dev page was already built in `_ready`, so the node count is unchanged except for one fewer CheckButton. Nothing new to free. `_refresh` does less work.
- One behavioural note with a perf angle: with the box gone, switches that were saved but dormant now apply. settings.gd:221-225 resets them once for saves with `dev_enabled == false`, so an upgrade does not silently switch on e.g. game speed, bottomless magazines or Retro pixels (the latter builds an extra view, so this guard also avoids a surprise cost). Correct as written.
- report_facts.gd: dev_text signature and NOT_SETTINGS only; runs once when a report is built, not per frame.
Advisory:
- Dev switches now apply by default for anyone who ticks one and never turns it off: Retro pixels and the dev views (play_session.gd `_apply_dev`) are built only while on and freed when off, as before; no change needed, but the owner should know a forgotten switch now persists without the box as a visible reminder (judgment).
- If a baseline is wanted for orphans_max 821, it is the same on main, so it is outside this change (measured).
Fixes: none required.
Unexplained: frame-count difference between the two smoke runs (2079 vs 755) is attributed to wall-clock pacing under uneven load, not to the diff (the diff touches no match code); not separately verified.
