Task: NR1 · Neon Heights removed, Woodland public · QA commit 9683682 · Verdict: Pass

Blocking: none.

Risks checked:
- Leftover references: no Neon, neonHeights or city in game/, data/, tests/, tools/, .github/, docs/wiki, changelog.d,
  README.md, export_presets.cfg or docs/*.md outside tests that name the removed map on purpose (the one `city` hit
  checks the id falls back to the yard). No orphaned `.uid` or `.import`; peaks.json lists yard, pines, insects, crackle.
- Wiki: `python3 tools/wiki.py check` passes.
- Stale picks: the Match page pick is session-only (MatchPicks), Settings hold no map id, `_keep_a_playable_map` falls
  back to Depot before play; a records file with `best_challenge.neonHeights` loads cleanly (test_wl9_qa.gd:100).
- `MapData.presets_in` (game/map/map_data.gd:225) on a missing file gives day alone with no engine error in the run.
- Woodland public: a Woodland PlaySession with Dev off ends with `dev_content` and `off_record` false; bots carry the
  torch, so the match counts for records and XP.
- Torch public: a level-0 item, so the Armory counts rise to 10/20 and 20/20; LIGHT is no longer LATER;
  `BotKits.night_light` gives the torch with Dev content off.

Non-blocking:
1. `DevContent.use_*` swap a shared static and rely on `restore_*` at the end of the test (GUT asserts don't throw, so
   only a script error would skip it); the same pattern as before.
2. An old crash record names "Neon Heights" from the id; harmless.
3. The no-engine-error claim for `presets_in` is read from the run output; GUT can't capture engine errors.

Tests added, tests/unit/test_nr1_qa.gd (gdlint clean, 6/6): a gone map's presets and load; no shipped map or item dev
and the range listed; the torch a bot night light without Dev content; a Woodland night match on the record; nothing of
the gone map on disk; a gone map's record worded without a catalogue entry. Each but the first fails on base 3a72ac7f.
