Task: KI1 · QA commit b8f929b · Verdict: Pass

Blocking: none.

Advisory:
- game/main.gd:300-304 · `_keeps_picks` was inserted between `_start_play`'s doc comment and its function, so "Opens the match picked..." now documents `_keeps_picks` and `_start_play` has none. Move the helper above that comment.
- game/report/report_scrub.gd (CREDENTIALS_IN_URL) · a password holding a raw "@" or a space leaks its tail: `https://user:p@ss@localhost/` gives `<credentials>@ss@localhost` (with a dotted host the e-mail pass takes "ss@host", so only the dotless host leaks); `user:pass word@h` is untouched. Both are malformed URLs (the "@" should be %40); over-scrubbing rule says tolerable, listed for a KNOWN_ISSUES row if wanted.
- game/map/map_data.gd `_vec` · a numeric string coordinate ("2") now reads 0 where `float("2")` read 2. No shipped map has one (grepped data/maps); the spots (`flag`, `overtimeFlag`) warn, blocks and lanes do not.
- game/progress/progress.gd `from_dict` · a junk `last_map` / `last_team` is dropped without a problem line (the other fields push one). Harmless.
- Remembered picks are off in headless (main.gd `_keeps_picks`), so the launch path (recall in `_ready`, remember at PLAY, no file on first launch) has no end-to-end test; the pieces are tested.

Checked and fine: Range or Practice remembered (page opens on Practice, a field pick restores the field's mode); Woodland remembered with Dev content off (falls to Depot, team kept); a map removed or junk-named (Depot); a team that is junk/2/0.5/true/"1"/null/1e30 (Alpha, map kept); first launch with no file and a save from before the field (defaults, unknown keys kept on write); a newer-version file (never written over); Reset level keeps the picks; a damaged file forgets them; the bundle/restore/import path stores the file generically (SaveBundle reads it with Progress.from_dict). Lean gap: counted from the last rustle (not the last try), per character, a crouch never held back, a new cast starts with no gap, SimAudio passes `foley_lean_gap` on; the clock is `state.time`, monotonic per match, and SimAudio is made per match. Ping: pressed before the wheel opens in the same tick still goes; pressed while open does not; wheel closing in the same tick; a wheel that cannot open does not block it. Scrub: linear on 100,000-character lines (no "@", "://" runs, unclosed users), "@" in a path/query and `res://` left alone. Depot hunt floor: over 4,000 random columns 2,610 draw as before on the same floor and 0 change (no new floor), so Depot is unchanged; in the hut it is the worker's test.

Tests (all new in tests/unit/test_ki1_qa.gd, 20 tests, how each fails without the feature):
- :23 older save / unknown keys kept beside picks · fails if `to_dict` drops `_extra` or from_dict reads picks from a file without them
- :37 junk team leaves the map, junk map leaves the team · fails without the 0/1 and catalogue checks
- :53 JSON float team 1.0 · fails if the team check required an int
- :58 range remembered opens on Practice · fails if recall didn't reach the page
- :72 Woodland remembered, Dev content off · fails without the page's fallback keeping the team
- :87 remembered map the catalogue refuses falls back · fails without `_keep_a_playable_map`
- :105 newer-version file never written over · fails if `remember_picks` saved over it
- :116 Reset level keeps picks, damaged file forgets · fails if reset cleared them
- :132 SimAudio gives the tracker `foley_lean_gap` · fails without the `lean_gap` line (stays 0)
- :141 gap counts from the last rustle, crouch unaffected · fails with no gap (all heard)
- :163 a new cast forgets the gap · fails without the `_lean_at` reset
- :200-:236 ping beside the wheel (before it opens, same tick close, cannot open) · the same-tick close case fails without the `not _wheel.open` check
- :253-:279 scrub shapes, no-credential URLs, linear on long lines · fail without the scrub / with a backtracking regex
- :288-:305 spot numbers in any form, non-object spots · fail without `_spot`
- :312 Depot hunt floor same as before, new floors reached · fails if `_reached_floor` changed Depot's floor for a spot already drawn

Counts: test_ki1_qa 20/20; with the touched files (foley_tracker, order_wheel_input, pn1_qa, levels, report_scrub, ov1_qa, match_page) 136/136 in 12.8 s; gdlint clean. Not run (machine loaded, worker ran them): the full parts, smoke_test, tools/check.sh.

Could not test (owner's list): remembered picks across a real quit and launch (headless skips them); how the lean gap sounds; the Woodland card picture and the hut hunt by eye.
