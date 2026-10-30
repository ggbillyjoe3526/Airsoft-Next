# SF2 · Bots throw their smoke and flash bombs

**Review:** critic Accept ?/8 · qa ? · performance ?

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-30 | 1 | worker | ? | ? | – |

## Goal

The second half of the owner's basic smoke and flash bombs for 0.1 Dev 2 (2026-10-30, "bots use them too"): bots throw
the bombs they have carried since SF1, and hear them go off.

## What changed

- **`BotBombs`** (`game/ai/bot_bombs.gd`), run at the end of each bot's tick:
  - **Smoke:** a bot in cover with an enemy BB close in the last 2 s, its threat 8 to 35 m off and no cloud between
    them yet, may smoke the line to them, half way (at most 12 m out).
  - **Flash:** a bot searching toward a spot 4 to 16 m off that it can't see may flash it, or the first of its route's
    next three points the bang would be seen from. The flash must land before its bang, so none goes off in the air
    over the thrower's cover, and it is never thrown where a teammate within 8 m, or within 16 m with a clear line,
    would see the bang. Then the bot turns its back until just past the bang, even with someone in sight, and pushes.
  - **How it throws:** each chance is the skill's (Easy 0.3, Normal 0.5, Hard 0.7), rolled at most every 1.5 s, from a
    new stream per bot (`Seeds.bomb_seed`), so no other roll moves. It turns to the throw at its turn rate and presses
    within 4° (giving up after 1 s). It stands still and doesn't shoot while turning, throwing or waiting on its bang.
  - **The aim:** it aims 0.75 of the way for the bounce and roll, on the low arc or else the high one, checked clear of
    the level in six rays (`Grenades.throw_pitch`, `Grenades.arc_point`).
  - **Its view:** while busy with a bomb, the bot's view is the throw's, not the fight's (`BotBrain`).
- **Hearing** (`BotHearing`): an enemy's flash bang is heard to 40 m and a smoke's pop to 20 m, as news of someone
  where it went off.
- **The flash rule** (`GrenadeConfig`): `behind_share` goes from 0.25 to 0, and the new `dazzle_least` is 0.1. Looking
  straight away from a bang, or nearly (past about 148°), dazzles nothing; side on still does. In the first whole
  matches, 13 of 20 bot flashes dazzled their own thrower, which looked away and still got 0.6 to 1 s at a quarter.
  Turning away is airsoft's own counter to a flash bang, and it is the same rule for the player.

## Decisions

- When bots throw and the new flash rule: `docs/DECISIONS.md` › Gameplay and feel (SF2).
- **Two situations only, not a planner.** The pin and the corner push are the two moments a player would reach for a
  bomb. Smoking a crossing, a plant or a retreat needs the team plan to know where the danger is (KNOWN_ISSUES).
- **The look away holds even with someone in sight:** facing its own bang would blind the bot for longer than the
  wait.
- **Teammates are checked, not told to look away:** bots can't coordinate, so a bot doesn't flash where one would see
  it.

## Verified

To fill.

## Known issues left

- Bots throw only in the two situations above, and they don't move round or under a cloud on purpose (KNOWN_ISSUES).

## Gate

To fill.
