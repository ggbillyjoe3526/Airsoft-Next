Task: SF1 · QA commit HEAD of this report · Verdict: Pass

Blocking: none. I tried to break the throw, the flight, the cloud, the dazzle, the view, the panel and the input. Nothing failed.

Advisory (not SF1's rows in KNOWN_ISSUES; for a row or SF2):
- game/sim/vault.gd:172-190 holds a reload, switch, selector, holster or hop-up press made during a vault and replays it after. A throw press made during a vault is dropped without a word (Grenades.press refuses it, and `throw_grenade` is not held). Press G while vaulting and nothing happens.
- game/sim/simulation.gd:123-125: `Vault.try_start` is not gated by `Grenades.throwing`. A jump mid-windup starts a vault and the bomb is released mid-vault from the eye. Read from the code, not run (needs a vaultable obstacle).
- game/play/grenade_view.gd:106-114 `on_tick` uses `events.first(FLASH_BANG)`, so two bangs in one tick draw one flare and light. The wash and the sound still play for both.
- game/sim/grenades.gd:327-336 `_bang` emits DAZZLED (and the sound dip, sound_mix.gd) even when the new dazzle is shorter than the one running. The dip restarts for no change in the screen.
- game/play/grenade_view.gd:233-237 `dazzle_wash` fades over the last 1.2 s of any dazzle, so a minimum 0.5 s dazzle peaks at about 0.42 white. A weak flash looks weaker than its strength implies. Design call for the playtest.
- game/ui/loadout_gear.gd `_build_grenades` calls `SimTuning.load_default()` on every build of the page (disk read). It could use the tuning the page already has.

Tests added (tests/unit/test_sf1_qa.gd, 38 tests, 172 asserts, all pass, 1.0 s):
- :84-:215 GrenadeView · idle view, canister and cloud per slot, no cloud before the pop, bang light fading, wash white/soft/fading/gone, smoke wash by eye position and density, held canister only in the windup, 0-slot and oversized pool, no orphan nodes after free, no allocation per frame once warm · these call new APIs and fail to parse without the feature.
- :222-:260 ReplicaPanel · bomb counts "SMOKE 1" / "FLASH 1", spend and respawn, no HOLSTERED flicker while throwing, HOLSTERED after a throw by a holstered replica, no hand leaves the row blank · mutated `if throwing: status = 0` to false: the flicker test failed.
- :270-:312 KeyBindings · G and Y defaults, in project.godot's InputMap, no default key shared by two actions, rebinding smoke to Y swaps with flash, both ACT_ labels translated.
- :314-:350 PlayerInput · a press arrives once, last of two wins, dropped while inactive and after release.
- :353-:565 Sim edge cases · vault refused; sprint speed rides along; pool full at the release keeps the bomb and redraws; respawn mid-windup leaves no ghost throw; hit after release keeps the bomb flying and spent; round over mid-flight lets it pop; torch off in the throw and back on after, a torch press mid-windup does not switch it on; pitch straight up and down never tunnels under the floor; a throw at a wall an arm away stays on the thrower's side; eliminated characters are not dazzled; smoke dazzles nobody.
- :585-:660 Smoke and bots · two clouds add, no depth before or after the cloud, from the middle out is one radius, a bot inside a cloud sees a far enemy only through a last wisp, a worn-off dazzle sees again.
Checked against copies of the tree with a production line stubbed out (copy deleted): no `bring_up` after the throw failed 2 tests; no torch restore failed 1; no `stop()` on respawn failed 3; the status line failed 1. The rest (view, keys, input) fail without the feature by calling APIs that do not exist.

Suite: test_grenades.gd 26 pass; test_sf1_qa.gd 38 pass, 1.0 s. I did not run tools/check.sh, the smoke test or the full suite (running elsewhere in this tree); the smoke test and its time are the caller's.

Not tested (needs a display or a person): how the puffs, flare, wash and held canister look; whether the 0.3 s windup, 13 m/s throw and 22 m flash feel right (PLAYTEST section); fullscreen and resize with the wash layer; the four rendered sounds; alt-tab during a windup (release() drops the latch, and the sim keeps the throw running).
