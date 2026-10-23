# SV1 · The save as one: restore points, Undo and delete

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus (worker) | pass | not run | QA Fail: a Restore over an empty save wrote an empty Undo slot (a deleted save lost); damaged and newer stores could be destroyed |
| 2026-10-23 | 2 | Opus (worker) | pass | Accept 8/8 | |

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
  the slot only once every store is written. Deleting an empty save is refused ("nothing to delete").
- **QA attempt 1 Fail, fixed in attempt 2:** a replace over an empty save (nothing, or only damaged stores) leaves the
  Undo slot as it was, so Delete, restart, Restore can still undo the Delete. A damaged store is set aside
  (`SaveFile.quarantine`, a `.corrupt-` copy) before it is replaced or removed, and a damaged `restore_points.save`
  before a new list replaces it. Any replace over a save holding a store from a newer version is refused (`last_error`
  names it): Undo couldn't give it back. A replace after one this run is refused up front ("restart first") instead of
  reaching the roll-back. `put_back` leaves a copy that is unchanged, so a store that couldn't be touched isn't
  rewritten. QA's proof test is folded into `test_save_keeper.gd`, with tests for a Delete that can't remove a store
  (rolled back), a full disk dropping the oldest point (a keeper whose `_write_points` has room for two), a damaged
  points file and a day west of UTC.
- **The Delete roll-back test locks a folder** with `chattr +i` (as root) or `chmod 555` (otherwise), and is pending
  where neither stops a removal (Windows).
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
- Before `replace`, flush `save_if_dirty` on the shared Settings, Progress, Records and SavedLoadouts, so the save kept
  for Undo is the one the player has, not the last one written.
- Greying: Undo when `undo_slot()` is null; Delete when the save is empty; restore when `save.refusal()` is not "".
- A save holding a store newer than this build refuses Restore, Delete and Undo for good; word it for the player and
  offer a way out (QA attempt 2).
- Undo's confirm shows the slot's `what` and `taken_at`: a slot kept from before a Restore over an empty save can
  still bring back an older save (QA attempt 2).

## Known issues left

None.

## Advisories left

- Damaged stores are set aside before the snapshot and the Undo write (save_keeper.gd:134-136), so a replace that then
  fails has already renamed them to `.corrupt-*`: nothing lost, but not literally "nothing changes" (critic, QA).
- Only a store with every copy damaged is set aside; a damaged main with a good `.bak` is replaced without a
  `.corrupt-` copy (the `.bak` holds the good data). `SaveFile.quarantine` ignores a failed rename (QA).
- `put_back`'s skip of unchanged copies has no test of its own; the Delete roll-back test passes either way (QA).
- A failed rename in `SaveFile._put` leaves a stray `<file>.put` that nothing cleans (critic, QA).
- `current.refusal()` is called twice in `replace` (critic).
- keep_today reads the whole bundle before checking for today's point (about 0.6 ms at boot); `_plain` rebuilds the
  payload on each write, worth watching if records grow (performance).
- Performance measured f97c55f; ae22751 changes only the boot and replace paths, no hot path (critic).
