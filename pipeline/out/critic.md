Task: FM1 · The full-screen map and Go there
Attempt: 1 of 4
Head: a8f19da (NOT the checks' head: check.sh parts passed on 9d4cd12, the rest still running; on a8f19da I ran test_fm1_go_there, test_fm1_field_map, test_fm1_qa, test_order_wheel_input, test_so4_orders_hud: 87/87, and gdlint on the changed .gd: clean)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept, conditional: it stands only once (a) tools/check.sh (or CI) is green on a8f19da and (b) FM1's performance report is in pipeline/out/performance.md (the files there now are UI1's and SF2's). Missing either, critic.md makes it Retry.
Evidence:
1. Held M opens, release closes: player_input.gd:197-199, 343-345; hearing only: hud_minimap.gd fill (teammates, heard patches, pole, hold; never the other team), hud_field_map.gd:115-117, test_it_shows_what_the_minimap_shows_and_never_the_other_team; any layout: fit_whole from the drawing's size (hud_minimap.gd +410), areas_of from map.areas, Depot and Woodland tested; bots obey: bot_controller.gd:239-241 → squad_order_book.gd give_move/move_arrivals; view ping stops at a wall: pings.gd move_spot → _floor_spot back_off, test_go_there_at_a_wall...; map click anywhere: pings.gd map_spot, never a contact.
2. PING event gains value 2 and value2 (game_event.gd:36), PlayerCommand gains fields; no contract changed. Sim stays node-free.
3. Per-frame paths read: hud_field_map.update (title string only on a new round), Overlay.place (redraw only when the pointer moves), MapPointer (values), move_arrivals (no alloc), give_move reuses _order_team. Allocation tests exist for the open map and walking ticks.
4. test_go_there_on_the_map_sends_the_squad_side_by_side_and_turns_to_hold_once_there fails without give_move/move_arrivals (MOVE never given, never turns to HOLD).
Advisory (not blocking):
- pings.gd:187 a view Go there snaps to the nearest walkable within spot_snap (3 m); beside a thin wall with no floor on your side (a crate against it, a ledge) it can pick the far side, against the 2026-10-31 ruling. A clear_line check from the back-off point would pin it. judgment
- QA's open items (F/X/V on the open map act on the frozen view; Tab shuts the map until M is pressed again) are not in KNOWN_ISSUES or the record, which says "Known issues left: None".
- Not committed at head: changelog.d/full-screen-map-and-go-there.md, docs/FEATURES.md; the record's placeholders. They go in the records push.
- docs/PLAYTEST.md order-wheel line has two parentheticals in a row ("(Go There lower right) (Need a Mag upper left)").
Must-fix before merge: check.sh green on a8f19da; FM1 performance report on disk; the records push above.
Owner should test in the game:
- Hold M on Depot and Woodland: is it big and readable, are the area words placed right, is the pointer speed right?
- Click a far corner: radio click, both teammates set off side by side, "GO · N M" turns to "HOLD · N M" on arrival.
- Mouse 4 at a wall with a crate or ledge in front of it: the squad stops on your side.
- Click inside a building's walls or off the field: "Nowhere there to go" shows, and isn't hidden under the dimmed map.
- Release M mid-fight: the view turns again at once and the first click after is not lost or doubled.
- Six items on the wheel: still easy to hit the one you want?
