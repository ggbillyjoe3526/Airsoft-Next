Task: UI1 · head 621f3d2 · Verdict: Pass
Run: no bot match needed (menus only; HUD/play untouched). Headless bench of the real screens at 1920x1080, same machine, main (365852a) vs head, 2 runs each · budget: no baseline yet, judged against targets and origin/main
Metrics (headless, no GPU, so script/layout time only; frame times are reported, not judged):
- Settings build+open+first frame, ms: main 122-141 / head 108-172 (same range, run-to-run noise). Nodes 854 -> 819.
- Settings tab switch, ms: main 7,7,7,8-14,26-28,10-12,33,10-13 / head 7,7,7,7,23-29,6-7,30-37,10: same shape; the slow tabs (5 and 7) are equally slow on main (not from this diff).
- Menus build 120-129 -> 116-131; nodes 227 -> 219. Loadout 76-82 -> 76-109 (noisy); Customise 22-38 -> 15-24; Customise tabs 12-35 -> 13-34; Armory 100-103 -> 94-104; Title 6.6-7.5 -> 4.8-5.0.
- Resources 63 menus / 6 settings, equal on both. After Settings queue_free: nodes +0, orphans +0, resources +6 (same as main). After menus and title freed: orphans 0.
Regressions (> 10 % worse): none (measured)
Blocking findings: none
 - No _process or _physics_process in any changed file; the new _draw (menu_switch.gd:66) is event-driven (queue_redraw on toggle, hover, focus), 4 shape calls, no allocations (measured/judgment).
 - Shared objects: MenuSwitch's ring box and blank icon are static, built once (menu_switch.gd:30-31); fonts come from the GameTheme.spaced_font cache; MenuChoice and swatches share 3 boxes across all their buttons; the Theme is the one shared instance. No StyleBox is made per frame (judgment).
 - GameTheme.dress and small_button run at build time only (key_binding_list.gd:42, settings_screen.gd:153-502); not in refresh paths (judgment).
 - Signals: each new connection is made once in _init/_build and owned by the node it watches (menu_toggle.gd:48, match_page.gd:410, settings_graphics_page.gd _preset.sort_children, title_screen.gd:149); no connect in a handler. MenuChoice._on_pressed -> put() uses set_pressed_no_signal, so no feedback loop (menu_choice.gd:49-82).
 - Per-layout callbacks are cheap: _place_tag (sort_children), MenuToggle._fit (minimum_size_changed; row is full-rect so no size loop), match_page._fit_play (theme_changed only: 2 text sets + measures, plus one deferred call). Not per frame.
 - Tooltips: text strings on controls, no tooltip nodes built until hover; SettingsScreen.explain() walks find_children once per row at build (settings_screen.gd explain), 9 call sites, none in refresh.
 - The vsync tooltip is re-set on refresh (settings_display_page.gd, string assign only); fine.
 - HUD/play path: the diff touches no file under game/play or game/ui/hud*; game/main.gd changes one line (show_heading). Settings is freed on close (main.gd:263 queue_free; confirmed 0 orphans).
Advisory:
 - game_theme.gd:131 small_button builds 3 StyleBoxFlat per call (about 15 key buttons plus a few more, build time only). Could share one set per edge colour; not worth doing now.
 - menu_switch.gd:60 connects 5 Callables per switch (about 40 switches in Settings); freed with the screen, measured no cost.
Fixes: none needed.
Unexplained: Settings tabs 5 and 7 cost 25-37 ms headless on both main and head (existing, not in this diff); worth a look on the owner's hardware only if it hitches.
Verdict: Pass

## Re-check at bea0818 (against main d35e82e)
Run: same headless bench, 2 runs each tree, worktrees removed. Measured: Settings open+first frame 95-136 ms (main 112-179); tab switch same shape (slow tabs 5 and 7: 21-42 ms vs 25-39 on main, existing); menus build 102-138 (main 119-143); Loadout 66-105 (main 86); Customise and tabs 13-33 (equal); Armory 110-131 (main 95-128, noise); Title 5.5-6.5 (main 5.4-7). Nodes: Settings 854 -> 813, menus 227 -> 210. Resources equal (63 / 6). After Settings and menus close: nodes +0, orphans +0.
Layout callbacks: the only new _process is none; fps_readout.gd keeps its existing _process gated on visibility (this round only moves its anchors, MARGIN 4, font size 13). MenuScale.MAX_SCALE 2.0 is a constant, read when the window resizes, not per frame. The Match re-layout (_columns, _column, _centred, _line) and loadout_strip _cap_name are build/refresh-time only; no new sort_children, resized or minimum_size_changed hooks beyond the ones already reviewed (no feedback loops). Performance panel fixed height removes a size-follows-content path.
Regressions (> 10 % worse): none. Blocking: none. Advisory: none new.
Verdict: Pass
