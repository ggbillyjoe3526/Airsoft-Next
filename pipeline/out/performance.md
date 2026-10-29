Task: FB1 · head 9ce3f72 · Verdict: Pass
Run: seed 1234, headless --smoke --perf (no GPU: draw calls 0) on this head and on main bad13b6 (/home/claude/bp-read), plus a 50-cycle menu script · budget: no baseline yet, judged against targets and origin/main. Machine load average ~7.5 on 4 cores: all timings are skewed and are reported only.
Metrics (measured):
- Smoke: head ok, 0 script errors, 664 frames; main ok, 755 frames (the smoke run is time-driven, so the frame counts differ under load). nodes_max 1116 / 1121 (ok), orphans_max 821 / 821 (same on both, a start-up spike that is not from this diff), menu steady-state nodes 637 / 637, orphans 0 / 0 (ok).
- Menu script (open and close Settings and its Graphics tab, Loadout, Armory, Match, QUIT GAME? ask and close, AIRSOFT wordmark to title and back, x50 after one warm-up cycle): nodes 264 -> 264, orphans 0 -> 0, objects 3288 -> 3288, resources 427 -> 427, from cycle 10 to 50. Settings screen and quit prompt are null after each cycle (freed). Static memory +3.6 MB over 50 cycles then flat from cycle 30; main's same loop shows the same +3.6 MB, so allocator slack, not a leak. Per-cycle time 909 ms head vs 671 ms main, but the loops are not equal (on main the Settings screen stays open, so it does less work each cycle) and the load is high: not a regression signal.
Regressions (> 10 % worse): none.
Blocking findings: none.
Scope: HUD, match and sim untouched (measured: the diff in game/hud, game/sim and game/play is one line, play_session.gd:1369, a ButtonWidth.group on the "refused map" screen's single back button).
Reviewed (judgment, all ok):
- button_width.gd: group() is called once at build; refresh() re-runs only on a button's minimum_size_changed. It measures get_minimum_size(), which leaves out custom_minimum_size, so setting the width does not change what it measures; a second pass is a no-op (equal values do not emit again) and it converges. No _process, no resize-signal loop. O(n) for n <= 8 buttons.
- Lifetime: the group is held by each button's meta and by its own signal connection; buttons are not refcounted, so there is no cycle. It goes with the buttons, and freed or queued buttons are dropped from the list on the next refresh. No leaked connections seen in the 50-cycle counts.
- menu_switch.gd: width fixed once on ENTER_TREE and THEME_CHANGED (two font measurements); no per-toggle layout. The old per-check meta and bind are gone.
- quit_prompt.gd / main.gd:542-566: built on Esc, queue_free()d on CANCEL or Esc (checked: gone after 50 cycles). _input and _unhandled_key_input exist only while it is open. Main._unhandled_input is a cheap early-return chain per event, not per frame. QUIT connects once to get_tree().quit.
- settings_screen.gd: _input now gated by esc_closes (cheaper in the menus). Still built on open and freed on close (main.gd:243-258); the top bar's wordmark button adds one Button in place of one Label.
- settings_graphics_page.gd:254: BLURB_LINES min height computed once, so toggling a switch no longer relayouts the rows below. z_index=1 on the tag: no cost.
Advisory:
- button_width.gd:76-80: each member of a group connects its own refresh, so a theme change on an n-button group runs refresh n times. Fine at n <= 8; do not group long lists (judgment).
- quit_prompt.gd:106 / main.gd:555: between close() and the deferred free, _quit_prompt is already null, so a second Esc in that same frame opens a second prompt. Harmless and one frame long (judgment).
Fixes: none needed.
Unexplained: orphans_max 821 in both runs (same on main, at the transition into the match); not caused by FB1.
Note: /home/claude/fb1-perf has no .godot cache, so a run in it fails with "Could not find type" errors (setup, not a code bug); I imported a git-archive copy in the scratchpad instead and edited nothing in the tree.
