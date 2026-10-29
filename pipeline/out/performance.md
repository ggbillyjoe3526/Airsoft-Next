Task: PN2 · head cec11e8 (code identical to c3d54e4) · Verdict: Pass (one advisory sits on the 10 % line, see Regressions)
Run: real PlaySession on Depot, Elimination, Compatibility under Xvfb 1920x1080 (draw calls), 3-a-side so 3 markers; plus headless --smoke --perf; vs origin/main 3a72ac7 (git archive copy) · budget: no baseline yet (pipeline/perf-budget.json absent), judged against targets and origin/main. Frame times are llvmpipe, not reported.
Metrics (measured):
- Hud.place_pings headless: 6.4 us/frame none up, 17.2 us with 3 up (field + pinned); minimap add_pings 5.8 us with 3 up. Worker's 5.5/24 us matches. 0 objects made over 5000 calls (OBJECT_COUNT delta 0).
- Live play frames: objects delta 0 over 300 frames with pings up (the +6 in the first 180 frames is first-use warm-up; 0 after).
- Strings: HUD_PING_MARKER text is rebuilt only when metres/kind/colour change (hud_ping_marker.gd:92-96); unchanged set_ping 0.2 us, a changed-metres rebuild 42 us/marker (tr + format + to_upper + two label sets + layout), at most once per metre walked. set_age 0.65 us. No per-frame String/Array/Callable; Vector2/Vector3/Rect2 temporaries are values.
- Nodes: main 589 -> 614 in a match (+25: one layer + 3 markers x 8, +4 %); constant over 480 frames; smoke nodes_max 1097 -> 1101; orphans_max 821 both (pre-existing, same on main); after session.free() nodes back to 1, orphans 0 (markers freed with the HUD).
- Draw calls (Compat): main 132; PN2 none up 132 (same); 3 up 172 (+40, +30 %): field-only 171, pinned-only 174; minimap rings/diamonds alone +16; field markers +23-26 (~8 each). Markers pref Off: 132 again.
- Pip: no new player; reuses the pooled _own voices through _play (sim_audio.gd:315), no new connection. ping_pip_1.wav is 7,100 B (+ .import 24 lines); a whistle cue is 12,392 B each; assets/audio is 11 MB, so +0.06 %.
- Signals: one new connect, the Settings row's toggled lambda (settings_hud_page.gd ~147), the same pattern as Callouts, freed with the page; none in the HUD, minimap or audio. No Tween, Timer or load() added.
Regressions (> 10 % worse): draw calls 132 -> 172 (+30 %) but only while pings are up (up to 7 s, 3 pings here, so a 5-a-side team with all five up is about +65 by extrapolation); with none up, or Ping markers Off, it is unchanged. Judged advisory: they are small 2D canvas items, not 3D passes. The coordinator may treat it as blocking if the 10 % rule is meant literally for any state.
Blocking findings: none
Advisory:
- hud_minimap.gd:~522-534 (_draw_ping): a ring is 2 draw_arc calls + a transform reset; the diamond switches transform; about 5 calls a ping on the minimap. Caching the ring as one prebuilt polyline would cut about 40 %.
- hud_ping_marker.gd:91-97: set_ping fills _edge_words as well as _words even while the pinned plate is hidden, so a metres change shapes text twice (42 us). Set the hidden one in _set_pinned instead, or only when it shows.
- hud_ping_marker.gd:125-129: set_age writes scale and modulate every frame; both are set every frame even when unchanged (judgment). Cheap (0.65 us), but skip when age >= pop and not yet fading.
- First ping of a session shapes new glyphs ("PING", "CONTACT", digits, the middle dot) on the first use; no hitch was measurable (objs warm-up only) but no prewarm entry exists. Not blocking: no new shader or material (default canvas material).
Fixes, ranked: none required.
Unexplained: smoke frame count differs (PN2 2676 vs main 3442; both ran in parallel on 4 cores, the smoke match is wall-clock paced); shots/impacts differ in step. Orphan peak (821) is identical on both so unrelated to PN2.
Probe scripts: scratchpad/pn2_measure.gd, pn2_measure_d.gd (nothing committed; .godot import caches created in pn2-perf, git-ignored).
