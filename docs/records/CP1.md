# CP1 · The Cyber Pistol in play

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Opus (build thread) | pass (950) | Accept 8/8 | – |

## Decisions

- **Its built-in config** is `game/config/replicas/cyber.tres`, the browser game's `CYBER_PISTOL_BUILT_IN` (electric,
  semi, burst and auto, on semi out of the box, hop-up 0.17 at 95 %), with stats.md's `cyber` row over it as for the
  others. Having a config is what makes the pool offer it, so it is carried as soon as it is unlocked (level 10).
- **Its sounds are its own** (`ReplicaConfig.sound`, `sound_profile()`): shots, dry clicks and magazines play the
  `*_cyber` cues already rendered from the browser game, with no power part apart, as there. Other replicas sound as
  their power, unchanged.
- **Its sights are marked in its model:** `cyber.glb` had no `RearSight`, so `RearSight` and `FrontSight` empties
  were added to the file at the browser game's `ironSight` marks (rear 4.0 cm up, 7.68 cm back; front 10.38 cm
  forward); nothing else in the file changed. The convention (docs/CC0_ASSETS.md › Replica models) now names both
  empties. It sits at the hip and aims as far forward as the GBB Pistol (ViewModelConfig), as its `hold` was the
  pistol's in the browser game.
- **The fire selector shows the mode** (`SelectorPose`, a SkeletonModifier3D): the models key every bone in every
  clip, so the Fire or Reload clip would turn the selector back to safe; the modifier sets the selector bone to its
  Selector clip's pose for the mode (semi half way, burst three quarters, auto the end) after the clip each frame.
  Applies to the AEG too, which had no selector pose before.
- **Realistic colours** turn its slab dark grey and its lines and core plain grey with no glow (the browser game's
  `CYBER_COLOURS.realistic`, `ReplicaSchemes.OWN_REALISTIC`); its metal keeps the model's own. LO3 had left it
  untouched under Realistic colours only because its materials aren't the paints' parts.
- **Tests that stood the Cyber Pistol in for a replica the game can't play** now use a made-up pool row with no
  config (`000099`), so they still test that rule.
- **Only the replica in hand runs its SelectorPose** (performance, attempt 1 advisory): the others are set inactive as
  the hands switch, so a put-away replica doesn't update its skeleton each frame.
- **Not in CP1:** the Inspect clip (the inspect key is a later step in the build order), and bots carrying it (BK1).
