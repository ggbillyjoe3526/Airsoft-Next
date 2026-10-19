# AT1 · Parts change how a replica plays

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Opus (build thread) | pass (822) | – | QA Fail: taking a part off a non-replica made a setup; an optic with no row zoomed 1× |
| 2026-10-19 | 2 | Opus (build thread) | pass (835) | Accept 8/8 | – |

## Decisions

- Parts are pool.md items of a third kind (`Pool.Kind.PART`), each with the slot of its table (optic, grip, laser,
  magazine, barrel, muzzle). Lights wait for night fields (the Weapon Torch is dev and not read yet).
- A setup saves its parts by pool.md ID and slot (`ReplicaTune.parts`); a slot not listed is as it comes.
- A part with no stats.md row, or a missing part table, changes nothing (quiet), as power sources do; a bad cell
  changes nothing there and warns.
- What parts make of a replica lives on the carried `ReplicaConfig` (aim_zoom, raise_scale, shake_scale, rattles,
  heard_scale, muffled), so the simulation, the bots and the view read it from the replica in hand with no new
  plumbing; as it comes these change nothing.
- A silencer counts as muffled because its Heard from is under 1 (stats.md has no Muffled column).
- The barrel's and muzzle part's energy multiply with the power source's before the site limit, as the browser game.
- A rattling magazine sends a RATTLE footstep every running stride while walking or crouched (heard 7 m,
  `BotConfig.footstep_hearing_rattle`, and played as the magRattle cue); running, it is heard as running.
- With an optic fitted, aiming zooms to the optic's Zoom instead of the iron sights' (ViewConfig.aim_zoom).
- An optic with no stats.md row has no zoom of its own: aiming keeps the iron sights' zoom (QA attempt 1).
- A rattling magazine in either slot rattles, whichever replica is in hand (the pouch rattles), as the browser game.
- `muffled` and the minimap and sound-cue side of Heard from are read by AT3 and the minimap step; AT1 sets them.
