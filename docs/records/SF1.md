# SF1 · Smoke and flash bombs

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-30 | 1 | worker | ✓ (see Gate); QA Pass, performance Pass | Accept 8/8 | – |

## Goal

The basic smoke and flash bombs the owner asked for in 0.1 Dev 2 (2026-10-30): every player and bot carries one of
each a round, throws it, and bots are affected by both. Bots throwing their own is the next task, SF2. The CO2 sound
grenade and the rigs and pouches that decide carrying stay in 0.2.

## What changed

- **Simulation.** `Grenade` (one pooled bomb) and `Grenades` (the throw, the flight, the smoke and the flash), tuned by
  `GrenadeConfig` in `sim_tuning.tres`. `PlayerCommand.throw_grenade` presses a throw; the replica is put down for the
  windup (`Armament.put_down`) and drawn again after (`Armament.bring_up`), and the command fires, aims and reloads
  nothing meanwhile. A bomb falls, bounces off the level by its normal and rolls to rest. A smoke pops at 1.2 s and
  smokes for 18 s (grows 2.5 s, fades 3 s) as an ellipsoid; a flash bangs at 1.5 s and dazzles every character in play
  with a clear line to it, by distance and how far it is from their view. Six new `GameEvent` kinds. A new round, a new
  match and a respawn clear the bombs; the range refills after each throw.
- **Bots** (`BotSenses`, `BotBrain`). Smoke blocks sight by `Grenades.smoke_depth` (thin edges let `smoke_see_through`
  through). A dazzled bot sees nothing, drops its target, holds its view and crouches until it wears off.
- **Presentation.** `GrenadeView` draws the canisters, each smoke as one MultiMesh of soft puffs (darker at night),
  the flash's light and flare, the canister held in first person, and the player's own white wash or milky smoke
  screen. Four new sounds (`tools/render_grenades.gd`), and a flash dips the field's sound. The replica panel shows
  "SMOKE 1 · FLASH 1"; the Loadout's Grenades slot is no longer greyed and shows what you carry. Keys G and Y,
  rebindable.

## Decisions

- One of each a round, G and Y, smoke never stops BBs, a flash blinds teammates and the thrower too:
  `docs/DECISIONS.md` › Gameplay and feel (SF1).
- **The throw is held by the sim, not the input.** A press starts a throw that runs on its own; a second press does
  nothing until it ends. Simpler than hold-to-cook, and bots use the same command.
- **The bomb is a sphere of radius 4 cm against the level only.** Characters don't stop it (KNOWN_ISSUES).
- **Smoke is an ellipsoid (radii 4 m across and 2.2 m up, its middle 1.2 m up), not particles, in the sim:** cheap,
  seedable and the same for bots and for the view.
- **The view's puffs are drawn from the sim's cloud, 28 per smoke,** with proximity fade so walls and the floor don't
  cut them hard.
- **No vault starts mid-throw** (QA's advisory): a Jump press then hops instead, and the wall is vaulted once the bomb
  has left the hand. A press of G or Y during a vault is dropped, not kept for after it like a reload.
- **A flash that would dazzle less than the dazzle running makes no event** (QA's advisory), so the sound doesn't dip
  again for nothing.
- **Throw speed 13 m/s lofted 0.12 and half the thrower's own speed:** about 13 m on flat ground.

## Verified

- `tests/unit/test_grenades.gd`, 28 tests: carrying and refills, the press, windup, release and redraw, refusals,
  flight, bounce and settling, the smoke's life and depth, BBs through smoke, the flash's dazzle by distance, angle
  and walls, teammates, wear-off, a new round, the range, bots in and beside smoke, a dazzled bot, no vault mid-throw,
  a shorter dazzle, and no allocation once warm. The vault test fails without its fix.
- QA's `tests/unit/test_sf1_qa.gd`, 38 tests: GrenadeView (canisters, clouds, light, wash, held canister, frees, no
  allocation), the replica panel's counts, keys and rebinding, the input latch, and sim edge cases. QA checked four of
  them fail with the feature stubbed out.
- Four older tests now know the bombs: the event order (`test_mh1_qa`), the prewarmed materials (`test_play_session`),
  the night's real lights leave out the bombs' hidden flash light (`test_night_light_qa`), and the torch rebinds to J
  now G throws smoke (`test_torch`).
- Screenshots of the smoke, its edge from inside, the throw and a fading dazzle (Compatibility under Xvfb), in the
  shared files under `concepts/gr1-grenades/`.
- Performance (headless): +22 nodes in a match (the pooled view, made once), 0 orphans, teardown back to main's
  counts; `GrenadeView.update` 20 µs a frame idle and 231 µs with all 12 slots smoking; `smoke_depth` about 2 µs a
  sight line.
- **Not verified:** how it looks and costs on a GPU, how the throw and the blinding feel, and the sounds: PLAYTEST ›
  Smoke and flash bombs.

## Known issues left

- Bots don't throw yet, or hear the bombs, or walk round a cloud (SF2).
- The numbers are first guesses (PLAYTEST › Smoke and flash bombs).
- Bombs pass through characters; no throw animation on the figure; the held canister is a plain cylinder.
- A torch goes off for the throw; a frame hitch can skip the flare.

## Advisories left

- The torch comes back on after a throw by setting its state, so with no click; going off for the throw clicks
  (critic).
- `GrenadeView.smoke_inside` recomputes the cloud's shape that `Grenades` owns, and two view values (the wash's 2 and
  the held canister's 0.75) are unnamed (critic).
- Two bangs in one tick draw one flare; a weakest dazzle (0.5 s) peaks at about 0.42 white (QA).
- A G or Y press during a vault is dropped, not kept for after it (QA).
- Every bot sight line walks the 12-slot pool even with nothing thrown (about 1.5 µs), and the view checks 12 slots a
  frame (20 µs); an active count would make both free (performance).

## Gate

Worker's run on 5470dc8, 2026-10-30: gdlint clean; changelog notes and wiki (25 pages) OK; unit tests parts 1, 2 and 3
passed 885, 2034 and 1016 (3935 in all, the parts run side by side); smoke test passed (`[smoke] ok frames=3145 …
rounds=9`, zero script errors); licence notices unchanged. The first full run, on 2ff1634, failed the four older tests
above and the sound files' count (379 to 391), all fixed. Match guards not run locally: no bomb is thrown in a bot
match yet, so they play as before; CI runs them.
