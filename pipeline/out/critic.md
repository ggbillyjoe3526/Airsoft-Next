Task: PN2 · Ping markers, the minimap and the pip
Attempt: 1 of 4
Head: 33e0c4f (CI ran only on cec11e8; per brief judged on the code; test_ping_markers + test_pn2_qa re-run here at 33e0c4f: 30/30, 105 asserts)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept (QA Pass incl. re-check of a165471; performance Pass, its draw-call finding cut by a165471 and the rest in KNOWN_ISSUES)
Failed checks, with evidence (file:line, one or two lines each, each marked measured or judgment):
none. Evidence per check:
1. AC1 hud_ping_markers.gd:76-79 (spot +0.3 m over floor spot, contact +0.8 m over chest from the stored point, never the live enemy), hud_ping_marker.gd:95-97 + en.po:136-140 ("PING · 9 M"), :129-172 pop/fade on hud_config.gd:99-101 and PingConfig.lifetime 8 (7 s whole + 1 s fade), hud.gd:484 Reduced motion; AC2 hud_ping_markers.gd:86-93 + hud.gd:919-942 (under minimap/flag/Hold plates; hidden spectating, board, summary, Off), play_session.gd:1180 pause, hud_ping_markers.gd:81 HUD size, restyle covers the plate; AC3 hud_minimap.gd:186-192, :443 (rim via _pin); AC4 sound_config.gd:89-91 = legacy audio.ts:259 (1700 Hz, 0.08 s, 0.13), render_whistle.gd:82 matches whistle.ts beep, sim_audio.gd:307-315, answers stay CO2 callouts; AC5 hud_prefs.gd:51/95, settings_hud_page.gd:147-151, hud.gd:354 + :920, made once in setup_field (play_session.gd:363).
2. No file under game/sim, game/ai, game/nav changed; HUD and audio only read the Pings book; the pref saves through the existing SaveFile path.
3. Hot paths read: place()/place_pings/add_pings/_draw_ping/on_ping write reused packed arrays and fields; text rebuilt only on a metres/kind/colour change (hud_ping_marker.gd:90); Mark.draw refills in place; tests at test_ping_markers.gd:356/366 and perf's 0-object runs agree.
4. test_ping_markers.gd:77 (no HudPingMarker / HUD_PING_MARKER, fails) and :270 (no on_ping / ping_pip cue, fails) checked by reading; both pass at head.
5. Presentation only reads state; every var/param/return typed; tunables in HudConfig/MinimapConfig/SoundConfig, the rest named drawing consts; no globals.
6. Soft self-rendered pip on the Interface bus, team-colour ring/diamond matching concept step27/ping.png (pn2-field, pn2-offscreen looked at); no new asset source; ASSETS.md and assets/audio/README.md record the cue.
7. Small new scripts (331 + 118 lines), Marks RefCounted, nodes freed with the HUD (test :376), one settings lambda freed with its page; advisories below.
8. Dev scope only; KNOWN_ISSUES (draw calls, overlap), changelog.d/pings.md, wiki HUD-and-Minimap/Settings/Squad-Orders/Roadmap, PLAYTEST updated.
Must-fix for the next attempt: none. Before merge: CI green on 33e0c4f. Advisories (no retry):
- hud_minimap.gd:305-306, :191 use HudPingMarker.Mark and .shade: a shared draw primitive inside one marker's script; move Mark to its own file (e.g. game/ui/hud_mark.gd) when next touched.
- hud_ping_markers.gd:87 and hud_ping_marker.gd:121 call plate_size() (_fill_edge + min-size) twice a pinned frame; pass the size in.
- test_ping_markers.gd:240 only tests the existing _pin, not that a ping is drawn on the rim (add_ping path untested for far pings beyond the count at :230).
- Comment lines past the house 120 columns: sim_audio.gd:13 (221), settings_hud_page.gd:8 (146), hud_minimap.gd:8 (122).
- docs/records/PN2.md Verified says 21 tests and a check.sh run before the fix rounds; now 22 + QA's 8; refresh with the head's gate.
- performance.md measured cec11e8; the after-fix draw calls (81 → 94) are the worker's numbers, not re-measured by performance.
Owner should test in the game (at most 6, one line each):
- Ping a spot and an enemy: the pip is soft and reads as "mark sent", not the shot timer; the teammate's radio answer follows.
- Ring sits just over the floor, diamond over the head where they stood and stays put as they move; both readable through cover at 10-40 m.
- Pop (0.35 s) feels snappy, not bouncy; Reduced motion shows them whole; the 1 s fade is noticeable but not distracting.
- Turn away: plates pin under the minimap (and under a pinned OT flag / Hold plate) with chevrons the right way.
- Minimap ring/diamond visible and on the rim when far; Settings › HUD › Ping markers Off hides both but pings still answered.
- Two pings close together on screen overlap (known issue): judge whether it bothers you in play.
