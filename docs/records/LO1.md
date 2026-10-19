# LO1 · The loadout you carry: saved loadouts, power sources and BB weight in play

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Opus (build thread) | pass (731) | – | QA Fail: a saved dev power source applied with Dev content off |
| 2026-10-19 | 2 | Opus (build thread) | pass (753) | Accept 7/8 (8: scope) | – |

## Decisions

- Saves name replicas and power sources by pool.md ID (never reused), not by Key, so a renamed or re-keyed row keeps
  its setups.
- A replica is offered only if the game has a built-in config for it (`game/config/replicas/<key>.tres`), so the
  Cyber Pistol, listed in pool.md, waits for step 11 without a special case.
- A missing Power sources table in stats.md is quiet: every power source then changes nothing (the rest of the file
  still reads). A bad cell in it counts as 0 % and warns.
- The site limit caps the rated energy (on the factory BB weight), as the browser game did; a heavier BB still
  carries its usual small share more.
- A dev replica or power source in the kit marks the match off the record, like a dev map.
- The loadout store is `user://loadouts.save` (kind "loadouts", version 1), apart from the settings
  (docs/DECISIONS.md: each store its own). Its fields this build doesn't know are written back unchanged.
- Bots carry their replicas as they come (factory weight, dial, the first power source: no change), as in the
  browser game; their team colours come with LO3.
- The colour schemes (`ReplicaSchemes`) and the Realistic colours setting (`Settings.realistic_colours`, off) land
  here rather than in LO2/LO3, so the Loadout screens and the colours in play can be built side by side on one base;
  LO1 only stores them, nothing shows them yet. Critic's scope note (check 8) answered by this line.
- Removing the carried loadout carries the next one (the one before it when it was last), as the browser game.
- A refused newer loadouts file is overwritten by the first save, as the settings file is; recorded in KNOWN_ISSUES.
