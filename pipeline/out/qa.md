Task: PN2 · QA commit (this commit) · Verdict: Pass

Blocking findings: none. Every acceptance criterion is met and pinned by a test that passes.

Advisory
- A teammate who is hit keeps their ping up for its remaining life (at most 8 s): `Pings` (game/ai/pings.gd) never drops a ping on elimination, and the HUD only reads the book. Matches the browser and PN1's book ("kept PingConfig.lifetime"); a dead teammate's contact diamond is still useful. Not a PN2 defect; no stale marker survives past its lifetime or a new round (pinned below). No disconnects exist (single player).
- game/play/sim_audio.gd header comment line for on_ping runs past 120 columns (gdlint passed, so within the project's limit).

Criteria checked (existing tests/unit/test_ping_markers.gd, 21 tests, plus mine)
1. Ring/diamond, words, never follows, pop 0.35 s, none under Reduced motion, 7 s whole then 1 s fade: test_ping_markers.gd; the gone-at-lifetime and re-pop of a new ping after a fade: test_pn2_qa.gd.
2. Off-screen pinning under the minimap and under flag/Hold plates, hidden spectating / scoreboard / paused / Off, HUD size and opacity: test_ping_markers.gd; pinned behind you stays inside the screen: test_pn2_qa.gd. Pause hides via hide_pings and the paused tree stops PlaySession._process. Looked at pn2-offscreen.png and ping.png: matches the concept.
3. Minimap ring/diamond, on the rim off the panel, Off hides them: test_ping_markers.gd; a new round clears the minimap's too: test_pn2_qa.gd.
4. Pip only for your own ping (not a teammate's ping or mark), once a ping: test_ping_markers.gd; two own pings pip twice with a teammate's in between or in the same tick, a ping after a new round pips again, Off does not mute the pip: test_pn2_qa.gd. Recipe matches SoundConfig (test_the_pip_is_the_browsers_recipe).
5. Setting On by default, saved, old file loads On, Off hides markers only: test_ping_markers.gd; On again mid-ping shows the ping still up: test_pn2_qa.gd. Markers made once (setup_field is called once per session), a frame with none allocates nothing, freed with the HUD: test_ping_markers.gd.

Tests added (tests/unit/test_pn2_qa.gd, 8, all pass; each is a regression pin, none found a bug)
- new round clears markers and minimap: fails if Hud/minimap kept their own copy or cached visibility; checked by reading place()/add_pings, which re-derive from book.is_up each frame.
- gone at lifetime, back whole and popping for a new ping: fails if modulate/scale were left from the faded marker.
- On again mid-ping; Off keeps the pip; two own pings / same-tick teammate ping; ping after clear; out teammate expires; pinned behind you inside the screen.

Runs (raw output in pipeline/out/qa/): test_pn2_qa 8/8; touched files (test_ping_markers, test_pn2_qa, test_hud_minimap, test_hud_prefs, test_assets, +1) 87 tests, 919 asserts, 28 s, all pass; tools/smoke_test.sh pass (0 script errors). Full tools/check.sh not run (per brief).

Not testable here (needs display/speakers, for the owner): how the pip sounds, the pop's feel at real frame rates, markers over a real window resize / fullscreen.

## Re-check of a165471 (fewer draw calls) · Verdict: Pass

Reviewed `git diff 877a929..a165471`: `Mark` (one triangle array a glyph, refilled in place), the field marker drawing its glyph and words itself, the plate filled only when pinned, `set_age` writing on change.
- Blocking: none. Look (pn2-field, pn2-offscreen re-renders: ring, diamond, words, pinned plates, minimap marks) matches the concept; the pop, fade, pinning, Off and freeing tests all still pass (Marks are RefCounted, freed with their marker/View); Mark refills write packed arrays in place, no object made (the no-allocation tests pass).
- Runs: test_ping_markers (22), test_pn2_qa (8), test_hud_minimap, test_minimap_field, test_hud_prefs: 71 of 71 on two reruns and 22 of 22 alone three times; smoke pass, 0 script errors. One earlier grouped run failed `test_a_ping_in_a_match_shows_on_screen_and_the_minimap_and_pips` ("the pip", line 409) once and passed on every rerun.
- Advisory 1: that test counts a pip still playing (0.08 s) after two physics and two process frames, so a slow frame (first run, loaded machine) can see it already finished: timing-dependent, flaky in rare cases. Better to assert the player's stream was started (or `_ping_serial` moved) than that it is still playing.
- Advisory 2: `plate_size()` now calls `_fill_edge()` every frame a marker is pinned, and `_edge_box.border_color = _colour` emits `changed` each time (StyleBoxFlat setter does not compare), so a pinned plate redraws every frame. Cheap (a plate or two) but it undoes the "only on change" idea; guard it with `if _edge_box.border_color != _colour`.
- Advisory 3: in `set_age`, `k != scale.x` compares a double with a float32 read-back, so it is true on every frame of the pop (0.35 s) and the saving applies only to the whole span and the fade's alpha; harmless.
