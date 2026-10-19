# DV1 · Debug view: BB paths, hit areas, seed and position

**Review:** 1 attempt · critic Accept 7/8 (Sonnet) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Sonnet 5.5 (worker, tier ui) | ✓ | 7/8 Accept | – (the KNOWN_ISSUES row for the faint trails and the changelog note, the critic's check 8; QA added tests) |

## Decisions

- **Keys: F4 BB paths, F5 hit areas** (F3 stays the overlay). They are the input actions `debug_bb_paths` and
  `debug_hit_areas` in `project.godot`, and F4 and F5 join `KeyBindings.UNBINDABLE`; the settings list is
  `KeyBindings.ACTIONS`, which doesn't name them, so they never show there.
- **Nothing exists while off:** `DebugView` (a node in the play session) makes the trail buffers and its line mesh when
  a draw is switched on and frees them when it is switched off; `_process` is off unless a draw is on. What stays is
  one `_unhandled_input` check and a `bool` test per tick.
- **BB trails** (depth tested) are a ring buffer per pool slot written once a tick (`BBTrails`), 2.5 s long (`DebugViewConfig`, a BB's
  whole life), fading from transparent to the BB; a slot clears when its BB dies or its serial changes. The line mesh is
  an `ImmediateMesh` rebuilt each frame (the engine allocates inside it); GDScript allocates nothing per frame.
- **Hit areas** are rebuilt each frame by `Hitbox.build_volume` on one reused `Volume`, from the tick's state (not
  interpolated), for every character in play but the one whose eyes you look through (the camera sits in its head), drawn over
  solid figures (no depth test), coloured by team: the head sphere and nine capsules
  (ring at each end, four side lines, two half circles at each end). The volume's bounding capsule is not drawn.
- **Overlay** gets a line when a match is on: seed, position (2 decimals), entities (characters plus BBs in the air).
  `Main` hands the session to `DebugPerf.watch`; the overlay reads `PlaySession.match_seed_used`, `player_position` and
  `entity_count` only. It refreshes every 0.5 s with the rest. The overlay's words stay plain text, as its other lines
  are (developer-facing, not in `en.po`).
- **`--seed <n>`** (also `--seed=<n>`, which `docs/PROCESS.md` already named) is parsed once at launch, 0 to 2^32-1;
  anything else is ignored with a warning. The browser game's seed was never wired in this port: `PlaySession` played
  seed 1 every time, so each Play now gets `LaunchSeed.fresh()` as DECISIONS requires. The smoke test keeps seed 1 so
  it plays one fixed match. With `--seed`, every Play in that launch replays that seed.

## Known issues left

- The trails are 1 px lines, faint at range, and drawn in GDScript; a row in `docs/KNOWN_ISSUES.md`.
- The first toggle compiles the line material, so one hitch is possible then (debug only).
