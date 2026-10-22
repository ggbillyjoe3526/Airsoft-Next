# FG3 · Attack / Defend in play

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | 6/8 retry | pause card said Elimination; marker and warning lacked the concept's flag, lowercase unit and tail; gauge built its pennant each redraw |
| 2026-10-22 | 2 | Opus (build thread) | pass | 7/8 accept | |

## Decisions

- **Built from the approved concepts** (`/mnt/project-files/concepts/step13-flag/`, William 2026-10-22 06:06): the pole
  with its reach ring, ATK / DEF tags over the scores, the FLAG gauge (one notch per rope step, 12), OT on the clock,
  the "Their flag is going up!" warning, the flag marker, the round banners and the Match card's attack line.
- **The pole is visual only** (`FlagView`, no collider): BBs and players pass through it, as FG1's rules have no pole
  body. Its look is `FlagViewConfig` in PlayTuning; the cloth waves in a shader and takes the attackers' colour.
- **The ring says who works the rope:** white idle, the attackers' colour raising, the defenders' lowering, yellow
  contested (the concept's legend).
- **A/D is offered on any map whose kind hosts it and has a pole**; a map without one keeps the card, greyed, saying it
  needs a flagpole. The session falls back to Elimination (and files it so) if handed A/D on a map without a pole;
  no such map exists yet, so that path has no test.
- **The overtime clock clamps:** OT shows the overtime left (15 s less what was played), 0:00 once End round now sets
  it to INF.
- **The marker shows only while a round is live** (QA), and hides within 5 m (`HudConfig.flag_marker_hide_within`).
- **The warning still shows while you are out** (QA advisory, kept): a spectating defender still learns the flag is
  moving. Easy to change if William prefers it quiet.
- **QA (Pass; 9 scratch tests, the rope sound one copied in)** and **performance (Pass: +8 HUD nodes, +10 for the
  pole, 0 orphans; rope and cleat cast no shadow on its advice).**

- **Critic attempt 2 (Accept 7/8):** its one failed check, the warning copying the sim's reach test, is fixed by
  calling `Flag.at_pole`. Left as advisories: the concept's slanted plates and the warning's glow (square in engine),
  the cloth shader's inline stripe and roundel numbers.

## For William to try

- Raise the flag to the top: the cloth climbs, the rope ratchets each notch, FLAG RAISED shows in the winners' colour.
- Let time run out with attackers on the rope: OT counts down, then DEFENDED / TIME'S UP.
- Defend away from the rope: the warning pulses and stops once you reach the ring.
- The flag marker through cover and with the pole behind you.
