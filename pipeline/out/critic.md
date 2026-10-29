Task: NR1 · Neon Heights removed, Woodland public
Attempt: 1 of 4
Head: f6b8209 (checks passed on it: CI green; QA and performance read pre-rebase heads 9683682 and b322395, both Pass)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. Removed: data/maps/neonHeights.json, assets/maps/neonHeights.jpg, the city loops and cues, play_tuning.tres's city
   sets (@@ -122 and the `&"city"` day/night keys), ambience_config.gd:10 IDS, ci.yml:208 job, match/flag/callout
   guards, KNOWN_FAILING (field_standard.gd:88). There was no Neon bake. No Neon in game/, data/, tools/ or wiki.
   Cancelled: ROADMAP.md:316. Public: data/maps.md:24 woodland public, data/pool.md:210 torch public, wiki
   Maps.md:+48 Woodland, FAQ, Roadmap Built, changelog.d/neon-heights-removed.md, DECISIONS (+514, +715). Fallbacks:
   map_data.gd:225 presets_in, test_match_page.gd:200 Depot, test_wl9_qa.gd:100 records.
2. No contract in ARCHITECTURE › Contracts touched (data-driven, saves and sim/presentation all unchanged).
3. No per-frame code changed. presets_in only runs on the Match page.
4. test_nr1_qa.gd:45 (a Woodland night match with `off_record` false) fails on base, where Woodland is dev and so
   is the torch. tower_block.json keeps storeys and Day/Night covered (test_night_light.gd:+123).
5. map_data.gd:225 typed by inference, no literal. DevContent swaps the shared table only in tests.
6. Woodland public at night with the torch, so a public night match isn't marked off the record. Fits the pillars.
7. Non-blocking nits: comment wraps left ragged at armory_facts.gd:5, customise_view.gd:5 and ROADMAP.md:188.
8. Docs updated (ROADMAP, DECISIONS, KNOWN_ISSUES +91 swinger row, IDEAS doors, ASSETS, PLAYTEST, FEATURES, wiki,
   pending notes). The torch going public is Claude's call, recorded in NR1.md and DECISIONS.
Non-blocking, fix if touched again:
- docs/wiki/Loadout.md:32 is over the 120-character wrap.
- ROADMAP.md:186 still says Woodland goes public "after the owner's playtest", but it is public now.
Owner should test in the game:
- With Dev settings off, the Match screen shows Depot, Woodland and the Range, with no DEV tag and no Neon Heights.
- Woodland at night: you and the bots carry torches, and the match gives XP and counts for records.
- Customise › LIGHT offers the Weapon Torch on every replica, Cyber Pistol too. It is no longer greyed LATER.
- The Armory counts include the torch (10/20, 20/20) and look right.
- Woodland's frame rate on Low and High, now that every player can reach it (KNOWN_ISSUES draw rows).
- Practice on Depot and Woodland shows no swinger target (known). Check it doesn't feel missing.
