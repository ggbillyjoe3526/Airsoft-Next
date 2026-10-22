# CR2 · The Rules section on the Match screen

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Sonnet | pass | pending | |

## Decisions

- **RULES is its own part, `MatchRulesBox`:** the picker, the blurb, the chips and the five Custom rows live in
  `game/ui/match_rules_box.gd`, so the page stays one screen's layout (it was already over 500 lines). It saves each
  Custom change at once (as a click in the settings screen) and tells the page, which reads the round tuning again.
- **The page's tuning follows Custom:** `_round_tuning()` is the loaded tuning, or `CustomRules.applied_to` it while
  Custom is picked. The Elimination card's "First to N", the chips and the map check read it. A change of team size
  lists the maps again (a map that can't seat that many greys with LATER); other changes don't touch the map cards.
- **Skirmish's chips gain Friendly fire** (the concept's sixth chip), so `MatchOptions.rule_chips` has six. The chips
  are kept in step with the tuning while hidden under Custom, so the page reads one tuning everywhere.
- **Skirmish's blurb is built from the tuning,** not typed: "3v3, first to 5, 2:30 rounds, friendly fire on" are its
  numbers. Custom's cap is `LevelTable.multiplier(LevelTable.CUSTOM)`, shown bold as the concept does.
- **Looks reuse the menu parts:** the picker is two `MenuCard`s with the ring (the team cards' look at the concept's
  48 px); the Custom rows use `MenuChoice`, which gains a `compact` look (buttons share the row, words as given, the
  unpicked dim, padding of the concept's `.diff`). The round time slider is the theme's, with a yellow knob
  (`GameTheme.knob()`, the concept's), on this slider only: the settings sliders keep their look. The chips' padding
  now counts the border, as the concept's 8 + 2.
- **The blurbs under the rows are the browser game's words** (matchRules.ts), kept per choice as translation keys with
  the number from the choice (`RULE_WINS_BLURB_%d` carries "%d"). Team size shows 1v1 to 3v3 only (`CustomRules`).
- **The concept's Elimination card says "First to 5" under Custom too;** acceptance 3 wins: the card follows the
  switches ("First to 7" with 7 picked).
- **Reviewers' fixes:** `CustomRules.copy()` and main hands a match a copy, so a settings change mid-match can't move
  its rules; `RULE_SETS` is built from `RULES_SKIRMISH` and `RULES_CUSTOM`.
- **Not done here:** the concepts' Opponents and Teammates rows (MN3), the three bot levels' look and the Pro level
  stay as they are.
