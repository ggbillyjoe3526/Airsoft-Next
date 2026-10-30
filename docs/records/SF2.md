# SF2 · Bots throw their smoke and flash bombs

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-30 | 1 | worker | ✓ (see Gate); QA Pass, performance Pass | Accept 8/8 | – |

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
- **Out of sight, a smoke goes toward where the bot knows the threat to be** (`last_known`), never where the enemy
  really is; with no idea, no smoke (the critic's advisory, taken after its review; its test fails without it).
- **Bots hold fire holds their bombs too** (Dev settings; QA's advisory).
- **Teammates are checked, not told to look away:** bots can't coordinate, so a bot doesn't flash where one would see
  it.

## Verified

- `tests/unit/test_bot_bombs.gd`, 14 tests:
  - the throw's pitch comes down where aimed (both arcs), and none out of reach;
  - a bot's smoke settles about where it meant;
  - the turn, then the throw along the line to a threat in sight, or to the spot it knows when out of sight;
  - no smoke out of cover, unpinned, too near or far, or with a cloud already between;
  - a flash round a corner: the bot looks away, the enemy is dazzled and the thrower not, then it pushes;
  - no flash that would go off in the air over a wall, at a spot in sight, too near or far, by a teammate, or with
    none left;
  - a failed roll waits its gap, and a throw it can't turn to in time is given up;
  - an enemy's bang and pop are heard, a teammate's not, and a pop past its reach not;
  - each level throws more often, and the bombs' rolls are their own stream;
  - whole Depot matches at Normal over two seeds: 16 rounds, 13 smokes and 11 flashes, with 6 enemies, 0 teammates
    and 0 throwers dazzled.
- QA's `tests/unit/test_sf2_qa.gd`, 8 tests: the reset, a refused throw, a dazzle mid-turn, the teammate check, NaN
  aims, the same seed twice, no snap back, and Woodland and Attack / Defend runs with no script error.
- Two older tests now know the bombs: a throw puts the replica down but is no holster (`test_bots`), and the skill's
  bomb chances are fields added after the levels moved (`test_tl1_qa`).
- Performance (headless, Depot, three seeds): `BotController.think` takes 483 µs a tick on average, against 490 on
  main; a decision tick takes 163 µs at most; nothing allocates per tick.
- **Not verified:** how it feels to play against, how often is too often, and whether turning away makes a flash too
  easy to dodge: PLAYTEST › Smoke and flash bombs.

## Known issues left

- Bots throw only in the two situations above, and they don't move round or under a cloud on purpose (KNOWN_ISSUES).

## Advisories left

- A throw being turned to stays decided for up to 1 s; a teammate who walks into the bang's reach meanwhile isn't
  checked again (QA).
- With the bomb pool full at the release (12 slots), no bang comes, but the bot still looks away (QA).
- A route point's flash has no least distance, so one can land a metre ahead of the thrower (critic).
- Bots' first rolls aren't spread out, so several can decide on one tick (about 70 rays at worst each; performance);
  `_mate_sees` repeats its rays per route point.

## Gate

Worker's run on 95f8545, 2026-10-30:
- gdlint clean, and the changelog notes and wiki (25 pages) OK.
- Unit tests: parts 1, 2 and 3 passed 898, 2034 and 1031 (3963 in all), run side by side.
- Smoke test passed (`[smoke] ok … rounds=8`, zero script errors), and the licence notices are unchanged.

The first run, on db29874, failed the two older tests above. The critic's smoke fix came after this run:
`test_bot_bombs` and `test_sf2_qa` pass on it, and CI runs the rest. Match guards were not run locally; CI runs them.
