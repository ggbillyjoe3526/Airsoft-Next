# BB1 · BB physics pass: wind, the hop-up dial in play, ricochets

**Review:** 2 attempts · critic Accept 8/8 (Opus) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-18 | 1 | Opus 5.5 (build thread) | ✓ | 6/8 Retry | two browser tests unported, README and known-issue rows missing |
| 2026-10-18 | 2 | Opus 5.5 (build thread) | ✓ | 8/8 Accept | – (QA added 8 tests; the counted-ricochet match ported) |

## Decisions

- **The breeze is the browser game's (M30):** 0.3 to 1.8 m/s, two gust waves of up to a quarter and a slow veer, drawn
  from the match's seed and its number (`Seeds.wind_seed`), so a rematch on the same seed gets a new breeze. BBs fly
  through the moving air (drag on the air-relative velocity), so lighter BBs and longer flights drift more.
- **The dial turns on 4 and 5** (and Page Down and Page Up), in 5 % notches, each replica keeping its own
  setting until the match ends. Every press sends a HOP_UP event, also at an end of the dial, so the readout and the
  click answer it.
- **The readout flies one BB, only on a turn,** with `Ballistics.hop_up_reach`; over-hopped, it says where the BB
  climbs out ("climbs from"), so a stronger dial never reads as a plainly worse one.
- **Ricochets always bounce; counting them is the rule.** Concrete and steel bounce a BB (the owner's G12
  restitutions), crates and the ground stop it. `HitConfig.ricochets_count` is off by default: a bounced BB that
  reaches someone ticks them ("Ricochet: play on") and stops. Counted, it can knock out anyone, its shooter included.
- **The dust is a single GPU particle box round the eye,** its drift updated twice a second, not per BB or per frame.
  It is faint on purpose (the browser game's sunlit motes); the BBs' drift is the real wind cue.

## Known issues left

Each has a row in `docs/KNOWN_ISSUES.md`.

- No Match options screen for the ricochet rule, and no off switch or Low-preset scale for the dust (settings, SE1).
- The hop-up turn while holstered waits for the holster (MO1).

The browser game's counted-ricochet match test is ported over 8 seeds, not 16 (45 of 251 hits off a bounce).
