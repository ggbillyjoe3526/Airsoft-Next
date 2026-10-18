# BE1 · Bots and Elimination on Depot

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-18 | 1 | Opus 5.5 (build thread; two workers: the nav grid, lean and vault) | ✓ | pending | – |

## Decisions

- **You play Alpha with two bot teammates against three bots** (`RoundConfig.team_size` 3), first to five. Every
  character but you is a bot; with the smoke test's pilot on, a bot plays you too.
- **The bots are the browser game's Normal bots, Elimination's part** (`legacy/browser/src/ai/`): lanes from the map's
  JSON and a team plan per round (split, pair or stack), holds at lane points, hunting by the team's sector memory,
  fighting with strafes, crouch cover and lean spots at tall corners, searching where a threat was seen or heard,
  sometimes flanking. One skill level, `BotSkill` at Normal; the rest is a later task (`docs/KNOWN_ISSUES.md` › Bots).
- **Senses are the player's** (`docs/DECISIONS.md` › Bots and balance): a 120° view to 40 m, anyone within 2.5 m,
  sight ten times a second staggered across bots; hearing of gunfire (22 m), running, sprinting, landing and vaulting
  feet, hit calls and near misses, with walls cutting a sound to 0.6 of its range. A hit call tells a bot's teammates
  the way the BB came, not how far.
- **Route searches are queued, one a tick,** shared with walk-off routes (`docs/DECISIONS.md`, 2026-10-18). The nav
  grid's `AStar3D` search is weighted (`search_greed` 1.5); a cross-map route costs 1.2 to 1.5 ms (a known issue).
- **Bots don't vault:** the nav grid has no vault links in Dev 1, so bots walk round low walls (a known issue).
- **Lean is held on Q and E, vault is Jump at a low wall.** A lean slows you to walking pace and stops sprint; the view
  rolls 0.12 rad. Crouch stays a toggle and aim held; `ControlsConfig.aim_toggle` is the one place to flip aim if the
  owner asks.
- **Out in the dead zone, you watch a teammate still in play** (else anyone), through their eyes, until the round ends.
- **The smoke test plays a whole match** with bots on both teams at eight ticks per physics tick (ARCHITECTURE contract
  9), and fails if the match isn't won within 30 minutes of match time.
- **`BotCombat.reload_when_due`, not `reload`:** a static `reload` on a script class resolves to `Script.reload`.

## Measured

- Headless bot matches on Depot, seeds 1 to 3: 23 rounds, none by the clock, no friendly hits, nobody off the map. The
  smoke match: 8 rounds.
- Nav grid build 205 to 240 ms; 27,363 walkable cells (the browser game's 27,380).

## Known issues left

- Bots are the core slice only (no other levels, names, kits, callouts, pings, squad orders, magazine sharing or Pro
  tactics); no vault links; a cross-map route over the 1 ms aim; a wall-cut lean snaps the view and a vault has no
  camera dip or prompt (`docs/KNOWN_ISSUES.md` › Bots and Play).
