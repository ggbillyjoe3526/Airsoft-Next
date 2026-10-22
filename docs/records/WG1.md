# WG1 · What got you and skipping the round

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (build thread) | pass | | |

## Decisions

- **Built from the approved concept** (`/mnt/project-files/concepts/step14-match-info/out.png`, William 2026-10-22
  06:07). The card sits on the left under the score bar, from HitFacts: a dial with you in the middle facing up and the
  shot's line from the shooter's side, the shooter's name in their team's colour with the side and distance, then
  whether they held the angle, how long you were in their view (each only when known), whether you were moving, and
  the bot's personality note with its lead in bold.
- **The side reads from where you faced at the hit**: within 45° of ahead it is "in front", within 45° of behind
  "behind", otherwise left or right. HitFacts gained the victim's yaw for this.
- **The setting is Auto, On or Off, on the Display tab for now** (HO1 moves it to the HUD tab). Auto shows the card
  only against Pro bots, as the browser game did. Saved with the settings.
- **The card goes when the next round starts**; your hit line in the feed stays framed and does not fade until then.
- **Skipping: hold Jump (Space) for 0.5 s while out and the round plays on.** The rest plays at 6× with the HUD hidden
  and "Skipping the round" at the bottom; it stops when the round ends and the round's table shows as usual. The hint
  ("SPACE Hold to skip the round") names Jump's key as bound. The pause menu's Skip to next round shows only while you
  can skip. Hold time and speed are in PlayTuning (`skip_hold`, `skip_speed`).
