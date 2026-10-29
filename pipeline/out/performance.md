Task: NR1 · head b322395 (base 3a72ac7f) · Verdict: Pass
Run: headless load and static review (no bot match run) · budget: no pipeline/perf-budget.json; judged against the
owner's targets and docs/records/WL10.md.

- No per-frame or per-tick code changed. Game code: map_data.gd presets_in (an early return on a missing file, once on
  the Match page), ambience_config.gd IDS drops city, comments.
- Deleted: 3 city loops, the city ambience cues, neonHeights.jpg and .json: install size and import cost go down.
- play_tuning.tres: every SubResource and ExtResource reference resolves (checked by script), every ext_resource is
  still used; the city beds and calls went with their `&"city"` keys by day and by night.
- `godot --headless --quit`: no errors or warnings from this change (two NUL-character lines after the flag cloth
  shader load are not from this diff, which touches no shader).
- Woodland by night with torches is now the public path; the change there is data only. WL10 measured it: draws mean
  200 to 276 at 5v5 and 217 to 276 at 6v6 by preset, primitives under 1.5M, headless CPU about 8 ms (5v5) and 9-10 ms
  (6v6). Draws over the 150 High ceiling are an existing KNOWN_ISSUES row.

Blocking: none.
Advisory: KNOWN_ISSUES rows on Woodland frame time (unmeasured on real hardware) and night shadow casters weigh more
now every player reaches Woodland at night; the owner should measure Low before a Beta tag.
