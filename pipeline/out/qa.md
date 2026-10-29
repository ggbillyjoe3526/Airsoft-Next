Task: BP1 · QA commit eb4bd0e · Verdict: Pass

Blocking: none.
Advisory:
- `ProcessCheck._first_arg` still logs "Unicode parsing error" for a non-UTF-8 argv0, or a multi-byte character cut by the 4096-byte buffer (game/core/process_check.gd:76); pre-existing, needs an absurd cmdline. A byte-wise ASCII decode would end it. KNOWN_ISSUES row at most.
- A bot waiting on the player's toss re-reads the line every tick, so a leaning player on the edge of a beam can flip it between standing and walking (game/ai/bot_mag_share.gd:174); no hysteresis, cosmetic.
- A giver whose line can never clear (receiver unreachable) walks until the ask lapses (ask_time 15 s) and then drops the job; it does not loop forever.
- test_run_record_real_process.gd asserted the own-process cmdline unguarded, so it failed off Linux; QA gated it on OS.get_name() == "Linux" (the file's other tests do the same).

Hunted, no bug: giver at exactly 3.0 m (walks when blocked, tosses when clear), 0.8 m, 5.9 m, 6.1 m (out of range, line clear: walks to 3 m); waist and chest cover and a beam, giver and receiver standing or crouched, leaning left, right or upright (no prone in this game); the receiver's line clearing mid-walk (presses the next tick); the receiver eliminated mid-walk (job dropped by update); the player as receiver and as giver; `_first_arg` with an empty file, all NULs, a 10 000-byte argument with and without a NUL, a missing file (what Windows has: no /proc, and the function is only reached on Linux), a multi-byte name.

Tests added (tests/unit/test_bp1_qa.gd, 9 tests; the two beam sweeps fail on the old _up_to, checked by restoring bad13b6's bot_mag_share.gd and running them: 2 fail, then restored):
- :73 and :78 · a bot bringing one walks or tosses, never stands without a toss, across 4 distances x 11 heights x crouch x crouch x lean; cover from the floor up and a 15 cm beam. The beam sweep fails on the old code, the cover sweep passes on both (guards the invariant).
- :97 and :102 · a bot waiting on the player's toss walks up unless the player can toss from where they stand, the same sweeps; the beam one fails on the old code.
- crouched catcher behind low cover blocks the toss, standing one doesn't, giver stepping up clears it (toss_line_clear).
- line clears mid-walk: presses next tick; catcher out mid-walk: job dropped.
- `_first_arg`: empty, all NUL, 10 000 bytes with and without NUL, missing file, multi-byte name (pin the results only; the old code gave the same strings and logged the NUL errors, which test_compiling_the_process_check_logs_no_error already pins).

Run: targeted files (bot_mag_share, mag_share, mh1_qa, run_record, run_record_real_process, bp1_qa) 93 tests pass; smoke test passes (0 script errors, 0 "Unexpected NUL" lines). Not run (load; worker ran them): full parts 1-3, match guards, tools/check.sh.
Not tested: the real maps (the sweeps use a plain level with one obstacle; real-map bot matches were the worker's guards).
Not testable here: how the walk-up looks and feels in play (owner: ask a bot for a mag across a window frame and a low wall, on both maps).
