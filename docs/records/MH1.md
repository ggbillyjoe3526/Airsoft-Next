# MH1 · The magazine hand-off's rules (Dev)

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified | – | – |

## Goal

The browser game's magazine hand-off (MG1, the owner's Dev 6 item 43) as simulation rules: one press of
`PlayerCommand.mag_hand_off` tosses a magazine to a teammate who asked you and is in reach, else asks for one if you
are low, else is refused with its reason. MH1 is the rules only; MH2 makes the bots press and bring one, MH3 puts it on
H, the order wheel and the screen. Concept: `concepts/step27/mag-hand-off.png`.

## Approach

- **`MagShareConfig`** (`game/config/mag_share_config.gd`, new; the browser's config/magShare.ts): ask range 30 m,
  toss range 6 m, flight 0.3 s + 0.05 s a metre, catch 0.4 m and throw 0.3 m under the eyes, low and keep one full
  magazine, asks stand 15 s, gaps 4 s (player) and 20 s (bot), 6 tosses at most. `SimTuning.mag_share`, in
  `sim_tuning.tres`.
- **`MagShare`** (`game/sim/mag_share.gd`, new; the browser's sim/magShare.ts with the press of src/magHandoff.ts and
  the ask of ai/magShare.ts): the pure rules (`fits` by stats.md's Class, `low_on`, `pouch_room`, `choose_spare`,
  `leaves_low`, `fill_spares`), `can_toss_to` (teammates in play, not vaulting, a spare that fits with room, within
  6 m eye to chest, `WorldQuery.ray` clear), `press` and `step`. Inner classes `Toss` (one pool slot), `Hand` (a
  character's ask: whom, since when, magazines coming, the next time it may ask, `player`) and `SparePick`.
- **The press** (`press`): out of play, between rounds or on the range, NOT_NOW. Else a toss to the nearest teammate
  asking you, with nothing in the air to it yet, that you can toss to now; else, low, ALREADY (your ask stands or one
  is in the air to you), WAIT (inside your gap) or an ask to the nearest teammate in play within 30 m, not asking
  itself, with a spare that fits and a full spare of its own kept (MAG_ASK), NOBODY without one; else TOO_FAR or
  NO_SPARE about the nearest asker out of reach, NOT_LOW with none. A toss is WAIT while your own is still flying or
  every slot is.
- **The step:** the press is read with the squad order at the top of each character's tick (so a press while out is
  refused); after the BBs fly `MagShare.step` lands each toss whose flight is over in the catcher's emptiest spares of
  the slot it was tossed for (MAG_CATCH), loses it with the catcher out of play or the round decided (MAG_LOST), and
  ends asks that lapsed (15 s), whose asker or giver is out or whose giver can spare none any more; a landing or a loss
  ends the catcher's ask. An ask that ends starts the asker's gap.
- **State:** `Character.mag` (a `MagShare.Hand`, cleared at each respawn but for `player`), `GameState.mag_tosses` (a
  pool of `max_tosses` made with the state; `Simulation.start_match` grounds any left), `Simulation.mag_share`.
- **Events** (appended): MAG_ASK (actor asks target; slot the replica in hand), MAG_TOSS (value BBs, slot the
  catcher's, value2 the thrower's slot it came from, position the hand, reach the toss's metres), MAG_CATCH (value the
  BBs that went in, position the chest), MAG_LOST (value the BBs lost), MAG_REFUSED (value a `MagShare.Refusal`:
  NOBODY, NOT_LOW, NO_SPARE, WAIT, ALREADY, TOO_FAR, NOT_NOW; target the teammate concerned or -1).
- Nothing random is drawn, so a match where nobody presses plays exactly as before.
- Tests: `test_mag_share.gd` (29), below. Docs: `game/sim/README.md`, the KNOWN_ISSUES row reworded.
- **Outside `touches`:** none. `round.gd`, `armament.gd` and `replica_config.gd` needed no change (`site_class` and
  the pouch were there; respawn clears the hand).

## Risks

- Nobody presses yet: bots at MH2, the player at MH3. Until MH3 sets `Hand.player` on the player's character, every
  character waits a bot's 20 s after an ask (KNOWN_ISSUES).
- A bot pressing every tick while low with nobody to ask makes a MAG_REFUSED a tick; MH2 paces its presses.

## Defaults taken

- **Reach and line measured eye to chest, as the criterion says;** the magazine leaves the hand (0.3 m under the eyes)
  for presentation. The browser measured hand to chest; at 6 m the difference is under 2 cm.
- **The toss goes to the nearest asker it can reach,** not only the nearest asker: one asker behind a wall doesn't
  block a toss to another in reach.
- **The ask's giver is whoever is nearest with a spare,** player or bot, not one already asking; whether a bot comes
  is MH2's. An ask stands while its giver is in play and can still spare one (the browser's rule for a player giver).
- **No hand-off on the range** (NOT_NOW): the spares stay full there, and MH3 makes it dead there.
- **Refusal for a thrower whose own toss is still flying, or a full pool: WAIT** (the list has no other fitting
  reason).
- **Finding nobody starts no gap:** "after an ask ends" only; the bots' pacing on nobody (browser 20 s) is MH2's.
- **Bushes don't block a toss** (the level's ray only, as in the browser; KNOWN_ISSUES).
- **A press is read before the character moves,** with the squad order, so out of play it is refused; the browser
  read it after the armament. Positions differ by a tick's step at most.

## Measurements

Headless scratch timing on the cloud container (shared with a guard run), 12 characters on BoxWorld:
- `MagShare.step` with five asks standing: 14 µs a tick; with all six tosses flying as well: 19 µs (0.1 % of a tick).
  With no ask standing it is one loop over the characters and the pool.
- A press that tosses: 61 µs (the reach's rays); one that asks: 43 µs. One a press.
- Ticks with magazines in the air and everyone pressing allocate no object (`test_mag_share.gd`).

## Verified

- `test_mag_share.gd` 29 pass: the browser's magShare.test.ts (low, room, fit by class, the spare not in hand first,
  keep a full spare, in reach and sight, toss range eye to chest, out of play, BBs moved never made, one in the air a
  thrower and the pool's slots, lost on a hit or the whistle, fill the emptiest) and magShareSim.test.ts through
  `Simulation.step` (an ask then a toss, nothing when not live, lost when the round is decided, a pistol magazine, out
  of reach and an enemy, one seed twice alike); plus the ask (nearest within 30 m with a spare kept, a pistol needs a
  pistol's, nobody), every refusal, the 15 s lapse and the 4 s / 20 s gaps, an ask ending with its giver, the nearest
  asker in reach, the pool made once, a press while out, 3,600 ticks of hand-offs with no BB made or lost but a lost
  toss's, and no allocation with magazines in the air.
- `test_simulation.gd`, `test_squad_orders.gd`, `test_pings.gd`, `test_saved_configs.gd` (52) pass; gdlint clean;
  `tools/smoke_test.sh` passes (`[smoke] ok`, zero script errors).
- Play unchanged with nobody pressing: `tools/match_guards.sh test_match_guards depot_matches_play_out_on_every_seed`
  passes with Depot's 121 rounds over 16 seeds at Normal, 0 on time, 0 to the overtime flag, as on OV1's and PN1's
  records; the other guards are left to CI.
- Not verified: how it plays (needs MH2 and MH3).

## Gate

`tools/check.sh` not run by the worker (the build thread's gate).
