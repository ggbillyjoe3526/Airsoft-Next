Task: RL2 · QA commit (see git log, subject "RL2 QA") · Verdict: Pass

Scope: git diff origin/main...HEAD (24ed35c). Hunted manual vs automatic across: empty with and without spares,
held AUTO trigger and a burst running dry, vault, sprint, swap to the pistol and back, a draw with R queued, a spare
arriving while empty (magazine toss), range/practice, pause/resume with a rebind, death, round over, holster, bots, and
the settings row and save/load.

Blocking: none.

Advisory (not blocking, for KNOWN_ISSUES or a later look):
- game/ui/hud.gd:840 · the prompt is not read to a screen reader (HudAnnounce has no line for it) and nothing flashes
  it for players who do not look under the crosshair; the owner's brief only asked for a prompt.
- game/play/play_session.gd:1047 · `_hud.manual_reload` reads the player's last command; after Settings is changed to
  Automatic from the pause menu, the prompt lingers until the first physics tick after resume (one frame). Harmless.
- game/ui/hud.gd:840 · the prompt also shows while a draw is under way (R then only queues the reload); correct, the
  press is kept, and it hides once R is pressed (reload_queued).

Checked and fine: a dry click while sprinting is not made at all (can_fire false) and R still loads; the setting
rides the command through a vault (vaulting_command and with_held_presses) and into the range pilot / autopilot / bots
(reset to false, so they keep the dry-click reload); the eliminated and idle commands never pull a trigger; a corrupt
"auto_reload" (string, number, null, array) loads Manual and Automatic round-trips; a missing file is Manual.

Tests added: tests/unit/test_rl2_qa.gd (15, all pass)
- :41 held AUTO trigger runs dry: 3 shots, one dry click, no reload · fails with the dry-click reload (Automatic path).
- :54 burst dry midway ends, no reload · same.
- :66 no spare: no prompt, dry click, R refused · pins reload_due and RELOAD_REFUSED under Manual.
- :77 swap to the pistol and back never loads the empty rifle · same.
- :96 R during a draw queues, prompt not due after; reload runs once up.
- :112 sprint: no dry click, R loads.
- :122 a spare arriving while empty makes the prompt due but never loads.
- :133 the setting holds through a vault; :152 Automatic through a vault still reloads · checked by restoring
  origin/main game/sim/vault.gd: the Manual vault test then fails (2 asserts), restored afterwards.
- :165 eliminated command; :178 prompt hides at round OVER and returns; :195 holstered and swapped-to-full hide;
  :210 a rebind shows on refresh_key, not before; :228 prompt ignores the mouse, no orphan; :239 corrupt values and a file
  round trip.

Runs: targeted 218/218 (pipeline/out/qa/targeted.txt); tools/check.sh: gdlint, changelog, wiki, units 1-3 (3802/3802),
smoke, licences all green (pipeline/out/qa/check.txt).
Not tested: how the prompt looks and reads in play on Forward+, a real rebind through the settings UI and resume, and
focus loss with the prompt up (needs a display); for the owner's list.

Verdict: Pass
