# AB1 · Two flags in Attack / Defend

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-31 | 1 | thread | two-flag and flag tests pass; full suite on CI | Retry 6/8 | the highest flag, not the one going up, was in play (a flag started under a stalled higher one went unanswered) and the HUD's marker and warning could name different poles; docs promised otherwise; the ruling missing from DECISIONS; the letter's billboard had no prewarm (performance) |
| 2026-10-31 | 2 | thread | two-flag (15), flag, minimap and QA tests pass | | |

## Goal

The owner's answer on the Depot concepts (2026-10-31): two flags, A and B, in Attack / Defend; the attackers raise
either. Third of four pull requests for the new Depot: DR1 the map (merged), DO1 doors (merged), AB1 two flags, DR2 the
CC0 dress.

## Approach

- **Data.** A map lists its poles as `flags` (a list of spots, flag A first, two at most, `Flag.MOST`); one `flag`
  still reads as one pole, so Woodland is untouched. `tools/depot/build_map.py` writes Depot's from `layout.py`'s
  `FLAGS`: A (44, -27) on A site, B (45, 28) on B site. `MapData.poles` holds them; `pole` and `has_pole` stay flag A's.
- **The rules** (`Flag`, `RoundState`, `Round`). `RoundState.poles` and `flags` (a `FlagState` a pole, sized each
  round in `reset_flags`, the same array kept so readers keep it); `pole` and `flag` are flag A's (setting `pole`
  makes one pole). `Flag.step_all` works each pole on its own, and either raised wins (CAPTURED); the buzzer's overtime
  runs while the attackers work either rope (`Flag.rope_worked`). `Flag.in_play`, `highest` and `nearest` pick a pole
  for the bots and the HUD; none allocates.
- **Bots.** The attackers draw a pole each round from the planner's seeded stream (`RoundPlanner.attack_flag`, drawn
  only with two poles, so one-pole maps play as before). The pole in play (`BotFlag.in_play`, `BotWorld.flag` and
  `flag_index`) is `Flag.in_play`'s: the highest flag going up, else the highest (so a flag started at one pole while
  the other stands stalled higher is the one everyone goes to; critic, attempt 1), else the drawn pole; so both teams
  go where a flag is going up (the player's too); a bot in flag mode picks its spot again when it changes
  (`Bot.flag_pole`). A defender's post for its search leash is the pole nearest the end of its lane
  (`BotFlag.post_of`).
- **The view and the HUD.** A `FlagView` a pole; with two, each carries its letter over its top (a Label3D turned to
  face you, `FlagViewConfig.letter_*`, billboarded as the "HIT!" sign is so the prewarm's sign covers its shader;
  performance, attempt 1). The marker, the gauge and the warning follow the same pole, `Flag.in_play`'s
  (else the nearer pole, `Hud.flag_shown`): the marker names it ("FLAG B", `HudFlagMarker.set_letter`, text built only
  when the letter changes), and the warning shows while that flag goes up and you aren't at its rope ("Their flag is
  going up at B!", built only when the pole changes). The minimap draws both (`Flag.MOST` slots made once).

## Defaults taken

- The marker shows one pole, not two, so two pinned plates never stack under the minimap: the pole in play, or the
  nearer.
- Attacking bots draw A or B evenly each round; their lanes are still dealt as before (they converge on the drawn pole
  once swept), and a flag started at the other pole pulls them there.
- The letters are off-white on the fittings' dark outline, off both team hues.

## Checks

- Locally: `tests/unit/test_two_flags.gd` (14) and the flag, bot flag, minimap, map and Depot tests pass; gdlint, the
  wiki check and the changelog check pass. CI runs the full suite and the match guards (now with both of Depot's
  poles) on the merge head.
- For the owner to play: whether A and B read from across the hall, whether the bots' split between A and B feels
  right (do they ever stack on one site too often?), and whether the marker should show both poles at once.
