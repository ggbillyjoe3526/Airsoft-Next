# MM2 · What your side heard: the enemy patches

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (QA's storey advisory fixed by the build thread) | pass | 8/8 accept | |

## Decisions

- **`MinimapHearing` lives in `game/play/`**, not `game/sim/ai/`: it is the viewer's perception, depends on whose eyes
  the view is through and never reaches the rules. Plain RefCounted, fed by `PlaySession` after each tick with
  `spectated()`, like audio and the HUD. It draws only from its own stream, `Seeds.minimap_seed`, reseeded per match.
- **A patch is placed only by an enemy in play whose sound lands within reach** (steps and vaults at step reach, shots at
  shot reach times the replica's `heard_scale`). Its centre is a seeded disc draw around the feet, so the enemy is always
  inside `radius = blur + pad`. A sound inside a live patch renews it and keeps x and z (a silent creeper is never
  tracked); its height takes the new sound's floor, so a patch heard on another storey moves to that storey.
- **A hit call removes that player's patch at once** (owner ruling), wherever the hit was. A new round clears every patch;
  a listener on the other team clears them, and coming back does not hand them back.
- **Worker defaults, not rulings** (plan section 5): only the listener hears (Q1); the browser's reaches (Q2); a patch
  stays put until heard again outside it (Q6); with no listener the side is kept and nothing placed (Q7, Dev side).
- The QA file's PlaySession run is 120 frames (was 240), saving about 4 s of the suite; it still sees over 100 patch-ticks.

## Known issues left

- `PlaySession.spectated()` falls back to an enemy when your whole side is out, and now calls `Spectate.next_bot` once a
  tick. Harmless today: the round ends and ROUND_START resets.
- `on_tick` restarts the match (reseed, clear) if the character count changes mid-match. Unreachable now; an index by id
  would also replace `patch_of`'s scan of 12.
- **For MM4:** draw patches anonymously (no name or colour from `character_id`); turn `centre.y` into a storey bucket,
  never a height; `beyond_view` is a circle of `view_radius`, but the panel is square and turns when Rotating, so clip in
  panel space and never draw one patch both inside and on the rim.
- Owner tests after MM4: a patch appears on a far shot and not on a walker beyond 22 m; a patch holds still while an enemy
  creeps inside it; a hit call clears it at once; patches survive switching to watching a teammate.
