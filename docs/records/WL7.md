# WL7 · The weapon torch

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | worker | 3,130 of 3,130 | – | – |

## Goal

The weapon torch (the browser's M33h): a Light slot in Customise with the Weapon Torch, fitted only on a field played
at night and dev while Woodland is; T switches it through the command, with an event and torchClick, and it goes out
when holstered, on a replica without one, when hit and at each round start. Every bot carries one at night and
switches it by what it is doing (botTorch.ts). Bots see anyone in a lit beam from the lit range and anyone whose lit
torch points their way. Your own torch is a real light from the rail on Medium and up and a haze on Low; everyone
else's is a drawn beam (owner's defaults, 2026-10-24).

## Approach

- Data: `data/pool.md`'s Lights table becomes a part slot (`Pool.PART_TABLES`, `Pool.LIGHT_SLOT`); the Weapon Torch
  fits every replica (`pistol, rifle`; RM8 modelled the Cyber Pistol's); `PartStats` reads stats.md's Lights columns
  (reach 40 m, beam 14°, spill 28°).
- Simulation: `Torch` (`game/sim/torch.gd`, new; sim/torch.ts): `Torch.Light`, `step` after `Armament.step` (a press
  switches it with a `TORCH` event; no light in hand puts a lit one out with an event), `put_out` when out of play
  (silent). `Armament.lights` and `light_in_hand`; `Character.torch_on` and `torch_time` (reset at respawn);
  `PlayerCommand.toggle_torch`; `GameEvent.Kind.TORCH`.
- The kit: `LoadoutRules.carried` turns a fitted light into `Kit.lights` and `Kit.light_dev`; `Kit.lights_for(night)`
  is empty by day, `Kit.dev_under(night)` counts the light only at night, `Kit.parts_under(night)` drops it from the
  hands' models by day. Bot kits still refuse a light; at night every bot gets the pool's first offered light
  (`BotKits.night_light`, `lights_for`).
- Bot sight: `NightField.update_torches` (once a perception interval, from `BotTorch.refresh`) marks who stands in a
  lit beam's spill cone within its reach across the ground, with a ray for walls; `torch_range` gives the lit range
  for them, and for anyone whose lit torch points within 60° of the viewer; `range_between` takes the larger of that
  and the dark's range. `BotSenses.made_out` puts it in `visible_part`.
- Bot switching: `BotTorch` (`game/ai/bot_torch.gd`, new; botTorch.ts): on fighting a target in play within 20 m (or
  the light's reach, if shorter), on the last stretch of a search, Easy (no `keeps_dark`) while advancing and searching
  too; a press only after `torch_min_hold` (1.5 s). `BotController` refreshes the light and steps each bot's torch
  after `BotBrain.think`. `BotConfig` › Night sight: `night_torch_seen_from_deg` 60, `torch_min_hold` 1.5,
  `torch_fight_reach` 20.
- Input: the `torch` action (T) in `project.godot`, `KeyBindings` (rebindable, after Holster), `PlayerInput` latches
  a press into the command.
- Customise: a LIGHT tab and card (`CustomiseView`), shown LATER while nothing is on offer (Dev content off); its
  cards show reach and spill (`PartOptions`); en.po strings.
- Presentation: `TorchBeams` (`game/play/torch_beams.gd`, new): everyone else's lit torch as a cone (additive,
  unshaded, fading along it and at its silhouette, nothing within 1.5 m of the eye), a lens glare (brighter looking
  down the beam) and a lit spot where the beam's middle lands (a ray): three `MultiMeshInstance3D` draws sized for
  the match. On Low your own torch is its cone too, its tip 2 m out from the rail. `FirstPersonView.set_torch` makes a
  `SpotLight3D` on the rail on Medium and up, shadowed from High. `GraphicsApply.torch_mode` and `pool_lights`: the
  view's torch takes one of Mesh detail's real lights (0, 2, 4, 4), so the light pools get one fewer at night.
  `SimAudio` plays torchClick on a `TORCH` event.
- `PlaySession` wires it: the player's lights by the preset's night flag, the bots' at night, the beams after the
  figures, their materials in the prewarm.
- Tests: `tests/unit/test_torch.gd` (25); `MatchRunner.lights` (`BY_RULE`, `NONE`, `ALWAYS`).

## Risks

- `update_torches` runs every perception interval: a spill test and one ray for each lit torch and each person
  (measured below).
- A shadowed spot light re-renders the scene from the torch on High and Ultra (measured below on the software
  renderer; the GPU's cost is the owner's to note).
- Every other Woodland match in the tests now plays with torches (the runner's `BY_RULE`); WL6's night-sight match
  plays with `NONE` to keep its own measure.
- Files outside the task's `touches`: `game/sim/game_event.gd` (the kind), `game/ai/bot_controller.gd` (two calls),
  `game/play/play_session.gd` (the wiring), `game/ui/armory_facts.gd` (a comment), `data/pool.md` (Fits and prose),
  `game/loadout/kit.gd`, `loadout_rules.gd`, `bot_kits.gd`, `game/input/key_bindings.gd`, `player_input.gd`,
  `tests/support/match_runner.gd`; `test_armory.gd` (a message), `test_key_bindings.gd` (KEY_T is the torch's now: the
  slot test binds U), `test_night_sight.gd` (no torches in WL6's match), `test_at2_qa.gd` (the Cyber Pistol takes
  the torch); the unit split (`tools/unit_tests.sh`, `ci.yml`'s step names, `docs/PROCESS.md`, `docs/records/CI1.md`);
  `data/graphics.md`, `game/{sim,ai,play}/README.md`, `tests/README.md`.

## Defaults taken

- **The torch fits every replica, the Cyber Pistol too:** the browser fitted it on every replica and RM8 modelled the
  Cyber Pistol's, so `test_at2_qa`'s "no part fits it" now allows the light.
- **By day the light is not fitted at all, its model included** (`Kit.parts_under`), as the browser's partsUnder.
- **A dev light marks only a night match as dev** (`Kit.light_dev`): by day it isn't fitted, so it changes nothing.
- **The bots' light is the pool's first offered light, with Dev content** (the browser's botKit botLight); none without.
- **Easy's torch on the move reads `keeps_dark`:** the browser's M71 "sloppy" bots are the ones that don't keep dark.
- **The switch works through a vault**, captured before the vault takes the command.
- **Going out on holster or a switch clicks (an event); going out when hit is silent:** the hand goes up.
- **The watched character gets the real spot**, spectating too, so the view always has its own light.
- **At night one real light is kept for the view's torch whenever torches are drawn**, on Medium and up.
- **Torch shadows from Mesh detail High** (`GraphicsApply.TORCH_SHADOWS_FROM`), as the owner's default says.
- **The torch's light is warm white, Color8(250, 250, 236):** 20° clear of every team hue (a test).
- **Low's own haze starts 2 m out from the rail:** seen from its tip a cone is all rim, a hard ring round the view.
- **The bots' figures show no torch model:** 20 models in view cost 55 to 67 draws (below), a fifth of Low's frame at
  night, for a part barely seen in the dark; a KNOWN_ISSUES row keeps it. Your hands show yours at night.
- **A figure's beam starts 0.3 m back from its muzzle**, about where a rail torch sits; with no replica shown, under
  the eyes.
- **The LIGHT tab shows LATER while no light is on offer**, as the laser did before its part came.
- **The presentation numbers live in `torch_beams.gd`** with the other views' look constants.

## Measurements

### Frame times (acceptance 6)

Measured by a scratch script: Woodland at night, 5v5, the teams placed 22 m apart facing each other with the bots
fighting, every torch switched on each frame (or every one off), the eye behind its team; the wall time of 90 rendered
frames after 60 to warm up, on Compatibility under Xvfb at 1600x900. The container has no GPU (llvmpipe on 4 cores,
other work running), so the numbers compare torches on with off on one machine; they are not a frame time. Torches go
out as people are hit, so 5 to 6 of the 10 were lit on average. Two interleaved runs each:

| Preset | Torches on, ms a frame | Your torch unshadowed, ms | Torches off, ms | Draws on / unshadowed / off |
|---|---|---|---|---|
| Low | 180.9, 187.9 | – | 171.5, 155.7 | 340 to 362 / – / 337 to 349 |
| High | 1,640.1, 1,202.0 | 1,261.4, 927.2 | 1,183.6, 940.0 | 495 / 399 / 412 |

On Low the beams cost 5 to 20 % here (three draws; the software rasteriser pays for every additive pixel a GPU
barely notices). On High your torch's real spot costs nothing measurable without its shadow and 28 to 39 % with it:
the shadow re-renders the field from the rail, about 83 more draws. `TorchBeams.update` itself: 26 to 61 µs a frame
with every lit torch (a ray each for its spot), 4 µs with none. What only the owner's PC can tell: Forward+ on Low and
High with every torch on against the 16.7 ms budget, and whether the shadow is worth its draws on High
(PLAYTEST › Woodland, WL7).

### The bots' torch light

`NightField.update_torches` (headless, `BoxWorld`, 12 people all with lit torches): 196 to 198 µs a perception interval
(0.1 s) with each of them looking at one other, no object made. Six ticks share it.

### Woodland's figures

Fitting the torch's model to every bot's replicas as the figures fit other parts (a mesh of its own on each), counted
in two still views of Woodland at night (the pictures' two scenes, 10 frames each) with the 20 models and with them
freed: Low 306 against 239 draws and 297 against 242; High 369 against 302 and 446 against 384. So the figures carry no
torch model (Defaults).

## Woodland 5v5 at night (acceptance 3)

`test_torch.gd`, Woodland 5v5 at Normal, first to 2, seed 5, every bot with the pool's torch: 2 rounds in 87 s, 15
hits; torches switched on 14 times and off 7 (the rest went out silently with a hit or at a round's end), at most 4
lit at once, none switched inside the 1.5 s hold while drawn and in play, none lit as a round started. Of 3,538
sightings sampled each tick, 848 were by torchlight (past the dark's range, outside close awareness) and none beyond
the lit range (40 m, plus 1.5 m for a look's lag).

## Day plays the same

`test_torch.gd` plays Depot by day, seed 11, 150 s, twice: every character with no light, then every one with the
torch in hand (`MatchRunner.lights` `NONE`, `ALWAYS`; in the game a day kit isn't even fitted). The ticks, the hits,
the rounds and who hit whom are the same: with no night field no bot presses its switch.

## Gate

`tools/check.sh` on the 4-core container: every gate passed, 3,130 tests of 3,130, in 18 min 55 s. The unit split
moved from `test_f` to `test_fl` (`tools/unit_tests.sh`, CI's step names, PROCESS, CI1's record): WL6 left part 1 at
350 s and part 2 at 550 s against its 600 s limit; now part 1 (98 files) 517 s and part 2 (157 files, `test_torch.gd`
about 28 s among them) 506 s. A first run the same day read 478 and 508 s.

`tools/match_guards.sh`: 7 of 7 in 28 min 55 s (Depot and Neon Heights by day, so no torch is fitted).

## Verified

- `tests/unit/test_torch.gd`, 25 tests: the slot and its stats; offered with Dev content on every replica; saved with
  the loadout and an older save loading; lights only at night through the Kit, its hands' parts without the torch by
  day; the bots' night light; the command's switch and events both ways; no switch without a
  light; out when holstered, on a replica without one, when hit and at round start; a beam's spill, reach and walls;
  bots making out who a beam lights and a lit torch pointed within 60°; no allocation; the bots' wishes, the minimum
  hold and nothing by day; Depot by day the same with and without torches; the Woodland 5v5; T, rebinding, older
  settings and a T already taken; the input filling the command once; the torch mode and pools per preset; the view's
  spot made and freed; three instanced draws; the hue gap; the click cue; Customise's Light slot with and without Dev
  content.
- Pictures (Compatibility under Xvfb, 1920x1080), in `/mnt/project-files/screenshots/step26/`: `wl7-own-torch.png`
  (your torch on High in Woodland at night: the lit ground spot, the bot ahead lit, another's glare to the right),
  `wl7-own-haze-low.png` (the same on Low), `wl7-side-beam.png` (a bot's beam from the side, its cone and glare from
  its rifle), `wl7-customise-light.png` (Customise › Light with the Weapon Torch fitted).

## For the owner to test

- PLAYTEST › Woodland: the weapon torch, others' torches and the frame time with every torch on (WL7); Replicas ›
  Light.
- On High and Ultra, your torch's shadow: its frame time in a busy night fight against the 16.7 ms budget.
