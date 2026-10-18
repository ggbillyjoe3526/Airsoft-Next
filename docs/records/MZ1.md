# MZ1 · Magazines on the HUD and the pistol's slide lock

**Review:** 1 attempt · critic Accept 8/8 (Sonnet) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-18 | 1 | Opus 5.5 (build thread) | ✓ | 8/8 Accept | – (QA added 5 tests; hud.gd's header re-wrapped) |

## Decisions

- **The gauges live in their own small script,** `game/ui/mag_gauges.gd`, beside the HUD rather than in it.
- **Spares sort fullest first,** so the one a reload takes next sits beside the loaded one.
- **An empty gauge is a dark well inside its outline.** Every gauge sits on a soft dark backing, so full reads light
  and empty dark on Depot's light concrete as well as in shade, without colour.
- **The slide closes at 85 % of the reload** (`ViewModelConfig.slide_release_at`), as a real GBB's slide drops once
  the magazine is seated, not on the reload's last frame.
- **Only gas replicas lock their slide** (`ReplicaConfig.power` "gas", and the model has a `SlideLock` clip).
- **A reload cut short** (a switch, a new round) poses its clip to the end, so no magazine is left half out.

## Known issues left

- A reload started within 0.05 s of the last shot doesn't hold the slide back through it (`docs/KNOWN_ISSUES.md`).
