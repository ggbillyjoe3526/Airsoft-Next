# SV1 · The save as one: restore points, Undo and delete

**Review:** critic pending · qa pending · performance pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus (worker) | pass | pending | |

## Decisions

- **The plan's defaults, approved with the step 22 pictures, 2026-10-23.** Restore points as the browser's
  (question 5): three, one per day the game is opened, the save as it was at start, none when unchanged, kept in the
  save folder. The restart after a replace (question 6) is SV2's.
- **The bundle is keyed by each store's kind** ("settings", "loadouts", "progress", "records"), which is also its
  name; `SaveBundle.KINDS`, `PATHS` and `VERSIONS` are the one list. `MACHINE_KINDS` names `run` before SV3 adds it.
- **`saved_at` is when the save was last written:** the newest modified time of its files, so "Now" and a point both
  show when that save was saved (the restore confirm's "Saved Today 14:30 · Thu 22 Oct 18:40"). A point keeps its own
  `day` and `taken_at` beside it.
- **Byte for byte through JSON:** Godot reads every JSON number back as a float, and wrote whole floats as "1.0", so
  `SaveFile.payload` now writes every whole number as an integer (up to 2^53). Data read back from a file then writes
  the same payload, which is what lets a restore point (stored inside `restore_points.save`) come back byte for byte.
  Readers are unchanged (they got floats before too); a file saved before this rewrites "1.0" as "1" on its next save.
- **Put back means every copy:** `replace` takes a `SaveFile.snapshot` (the file, .tmp and .bak, as bytes) of each
  store and the Undo slot first, and on a failed store `put_back` restores them all, each written beside and renamed,
  so the backups and a damaged copy come back too. A copy that exists but can't be read stops the replace before
  anything changes.
- **A held file is never written, removed or set aside** (`SaveFile.hold`), so neither a late `save_if_dirty` nor Dev ›
  Reset the save touches the new save before the restart; a refusal is logged and is not a `last_failure` (the tab's
  warning is for real failures). A later good write of the same file clears `last_failure`. `SaveFile.remove` now
  returns whether every copy went (callers that ignored it are unchanged).
- **A newer save names its version:** `SaveBundle.refusal()` (English, for the log and `SaveKeeper.last_error`)
  names a store's version above this build's, or the build that took the point when it is newer
  (`Version.newer`, which orders "0.1 Dev 1" < "0.1 Beta 1" < "0.1" < "0.1.1"). SV2 words it for the player.
- **The Undo slot** holds `{what, taken_at, save}`; Undo writes no slot (the save it replaces is not kept) and removes
  the slot only once every store is written. Deleting an empty save is refused ("nothing to delete") so it never
  overwrites a useful Undo slot with an empty save.
- **A file of a newer format** (`restore_points.save` or `undo.save` above version 1) is read for nothing and never
  written over.
- **The day is the player's local day** from `Time.get_time_zone_from_system().bias` (minutes east of UTC), injected
  as `utc_offset_minutes` with the clock.
- **The failing-write test uses a folder where the store's .tmp goes,** not a read-only folder: the cloud session and CI
  run as root, which writes into read-only folders.
- **Outside touches:** `game/core/version.gd` (`Version.newer`, with tests in `tests/unit/test_version.gd`): ordering
  version names belongs with their rules (contract 7). `docs/ARCHITECTURE.md` (the `game/save/` row, and its duplicate
  older row removed) and `docs/DECISIONS.md` (the save as one).
- **`tests/unit/test_gauge_pattern.gd:169` checks the global object count with `assert_lte`:** the first full run
  failed it with the count lower than before (10267 against 10273: objects from earlier tests freed in those frames),
  not higher; a global count may fall, never rise (unrelated to SV1, a test-only line).

## For SV2

- After a replace, write `renderer.cfg` from the restored settings before the restart (`RendererOverride.put` with a
  fresh `Settings` from the bundle), or the restarted game starts on the old renderer for one run.
- Greying: Undo when `undo_slot()` is null; Delete when the save is empty; restore when `save.refusal()` is not "".

## Known issues left

None.
