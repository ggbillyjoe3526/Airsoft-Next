# SP1 · The mix: voice pools with spread, the buses, out and ducking

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (QA's no-voices advisory fixed by the build thread) | pass | 8/8 accept | |

## Decisions

- **Worker defaults, not rulings** (plan `/mnt/project-files/plan/step19-sound-pass.md` section 5): others' steps reach
  22 m, the field 60 m (was 80), the range's targets 80 m, and a sound past its reach takes no voice (5.1). The field
  stays muffled from your hit until the next round, also while you watch a teammate, and clears at MATCH_OVER (5.2).
  The field's echo is left out and noted in `docs/IDEAS.md` (5.6).
- **Your own hit's tick plays on Interface** (the browser's `ui`), so the hit dip and the out muffling never swallow
  the cue that must be read; others' ticks stay on Effects. It now follows the Interface slider, not Effects.
- **Two `VoicePool`s** (plain players for your own sounds, positional for the field), katanashotgun's pick order:
  a free voice, else the cue's oldest at its limit, else the oldest of the lowest priority no higher than the play's,
  else dropped and counted. A cue allowed no voices is dropped (QA). Ages are the order voices were taken in.
- **New numbers:** 4 voices a cue, 6 for shots; level spread (± dB) shot 1.0, mechanism 1.5, step 2.0, vault 1.5,
  rope 1.0, impact 2.0, hit 0.5, steel 1.0, interface cues 0 (small, because the variants already differ). Start limits
  run on the simulation's time.
- **Buses:** Effects and Ambience feed a new Field bus under Master; Interface goes straight to Master. Field's
  low-pass is off whenever you are in play and settled. EffectsHalf/Full and PowerHalf/Full carry SP2's half and full
  muffling (3550 Hz at 0.775, 700 Hz at 0.55), written once at setup from `SoundConfig`. `default_bus_layout.tres` is
  saved in the editor's form, so godot runs no longer churn it.
- **Pausing:** a capture probe showed Godot fades a paused playback over one mix step, so no pause fade was added.

## Known issues left

- SimAudio costs about 4 µs a tick more (0.025 % of a tick; acquire's sweep is about 3 µs a play). Revisit with SP2's
  rays on the same path.
- SoundMix pauses with the tree, so a dip freezes while paused; nothing plays through Field then, and leaving clears it.
  A dip hold of 0 never dips; no config uses one. `_process` runs while settled (1.7 µs a frame).
- Occluded steps on SP2's buses would skip the Footsteps bus; harmless while Footsteps stays at 0 dB.
- **For SP4:** every new sound kind goes into both of `SimAudio._kinds`' dictionaries, or its plays are dropped; calls
  play at `Priority.CALL` on Ambience (muffled while out); no dip for the whistle itself or the round's start.
- Owner tests by ear: getting hit (crisp tick while the field ducks and dulls until the next round); watching a
  teammate while out; round and match end dips; pause mid-dip and quit from pause (no click, nothing stuck); six bots
  sprinting close and a full-auto fight (readable, no cut tails, the level spread natural); steps past 22 m silent.
