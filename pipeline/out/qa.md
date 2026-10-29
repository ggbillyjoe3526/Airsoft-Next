Task: FB4 · QA commit afa6430 · Verdict: Pass
Scope: raise on the run, holstered sprint, BB sight and drawn place, pressed hands depth (notes 5, 7, 11, 12). Head f2c8846.

Blocking: none.

Advisory (for KNOWN_ISSUES or a later polish pass):
1. replica_view.gd:180 a held trigger keeps the replica up on a sprint even when nothing fires: a semi replica with the
   trigger held, an empty magazine, or the whole reload (the reload cant then sits on the raised pose, no carry).
   Harmless, but a sprint-reload with the mouse held never shows the low carry. Trigger: sprint, hold fire, press R.
2. replica_view.gd:134 the early return when not visible (eliminated) stops `_fire_hold` ticking down, so a shot just
   before elimination can hold the replica up for up to 0.35 s after the next spawn. Cosmetic.
3. viewmodel_config.gd:77 `depth_scale` has no range: 0 collapses the hands onto one depth (parts z-fight each other),
   negative values flip it. `sprint_fire_raise` of 0 gives 0/0 = NaN on a zero-length frame (the same hole `carry_time`
   already has). Both are tuning values nobody sets; an @export_range would close them.
4. optic_glass.gdshader:30-31 the comment line is duplicated.
5. bb_view.gd (trail): a ricochet's trail is drawn back along the new heading, so for its first frames it points into the
   surface it left (hidden by depth, but a straight stub, not the bent path). Cosmetic; BB path is correct.
6. A own BB now appears at the eye plane beside the barrel, so its first drawn frame is 0 to 1.5 m ahead of the eye
   (low right), not at the muzzle tip. Intended by the fix; the owner may notice a BB that no longer starts at the barrel.
7. Not checkable here (Forward+ and a real GPU): SSAO is on in the field presets and reads the depth buffer, where the
   hands now sit pressed to a quarter; a dark halo round the replica or on the wall behind it is possible. The glass
   shader writes POSITION.z by hand (`mix(w, z, scale)`) to match the engine's z clip scale; verified on Compatibility
   only. Both go to the owner's list: aim the 2x scope and hip-fire against a wall, look for a halo and for the glass
   sitting in its scope.

Checked and fine: holstered trigger held or a shot then holster never lifts the carry; reload, switch, holster, draw and
shots in one sprint stay finite and settle on the same pose as a fresh view; sprint stop with the trigger down never dips
below the hip; the holstered pace is never slower in any stance (sprint x walk x crouch x lean), walking and crouching gain
nothing, the plain sprint is 1.1x, lean slows it smoothly, aim-walk scales it; no code but movement.gd reads
sprint_speed (grep), bots never fire on a sprint (bot_combat.gd:141) so the third-person figures need no raise; wiki table
generates and `wiki.py check` passes; every surface of AEG (scope, silencer, long barrel, hi-cap), pistol (laser,
silencer, extended) and the Cyber Pistol is a BaseMaterial3D pressed, the scope's glass disc presses its own; Realistic
colours press the realistic paint, shared paints, models' own and a figure's replica stay unpressed, copies free with the view;
a drawn own BB is never ahead along its flight for 400 random muzzles; a full mixed pool draws once each, trails on white only;
a stopped BB takes its ball and trail; trail never longer than the BB has flown.

Tests added: tests/unit/test_fb4_qa.gd (15). Each was run against a scratch copy with the feature stubbed out:
 :76 holstered trigger no raise · removing `not a.holstered` fails it
 :93 reload/switch/holster sequence, finite and back to the carry · a `_fire_hold` that never decays fails it
 :146 no dip stopping a sprint with the trigger down · (guards the carry rate change; passes on main as well)
 :164 stance table · :192 lean/aim · dropping holster_sprint_scale fails both
 :211 every surface pressed (parts, glass) · :242 Realistic colours · :280 freed with the view · :303 two views/figure
   paint untouched · removing `_press_depth(model)` fails all four; :211 and :269 also fail without the glass uniform
 :269 glass follows depth_scale · removing the uniform set fails it
 :322 never ahead along the flight · using the raw muzzle offset fails it; :343 a bot's BB is not offset
 :352 full mixed pool, trails white only · :377 stopped BB · disabling the trail instances fails both; :397 trail length
   bounded by age and following the heading (pure helper check, passes on main for the age bound)

Counts: test_fb4_qa 15/15, 1375 asserts; targeted run (that file plus hands_feel, bb_sight, bb_walls, holster, glow_bbs,
replica_paint, lo3_qa, at3_qa, movement) 115/115, 2077 asserts, 20 s. gdlint clean. tools/smoke_test.sh passes (frames=2625,
zero script errors). Raw output: pipeline/out/qa/fb4-targeted.txt. Not run (machine load, worker ran them green):
full parts 1-3, match guards.

For the owner (needs a display): the raise reads right on a sprint-fire; +10 % holstered sprint is felt; BB rim and trail on
Forward+; the replica over a wall, and item 7 above.
