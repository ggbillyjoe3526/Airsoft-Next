# LO3 · Replica colours in play

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Sonnet (worker) | pass (772) | Accept 8/8 | – |

## Decisions

- `ReplicaPaint` (game/play/replica_paint.gd) builds one set of five materials per paint (and per Realistic), shared
  by every replica wearing it; the cache is capped at 32 sets and cleared when a session ends.
- Only surfaces whose material is named Body, Furniture, Detail, Accent or Metal are painted; Rubber, BB and Tip
  keep the model's look. The Cyber Pistol's materials aren't named for the parts, so it keeps its own (a test pins it).
- Figures now hold their active replica as the glb's cut-down Figure mesh at fixed hold points (no hands, aim pitch
  or recoil), hidden once the figure starts its walk-off fade, since the shared paint can't fade. Placeholder until
  the art pass; in KNOWN_ISSUES.
- Realistic colours is read when a match starts, so a change applies from the next match.
- The player's own figure isn't drawn, so only the hands wear the player's paint.
