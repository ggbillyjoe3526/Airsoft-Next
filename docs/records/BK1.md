# BK1 · The bots' kits

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Opus (build thread) | pass (978) | Accept 7/8 | – |

## Decisions

- **Ported from the browser game** (`pool/botKit.ts`) into `game/loadout/bot_kits.gd` (`BotKits`): bot-kits.md read
  against the pool, a row it can't read left out with its line (the same checks: a name not in pool.md, a part that
  doesn't fit, two for one slot, a weight that isn't a number of 0 or more, a weapon torch, a Suits name bots.md
  doesn't list, a kit named twice, the same replica in both slots); each opposing bot's pick drawn by its difficulty's
  weights among the kits whose every item is offered (dev gear only with Dev content on, and then the match is off the
  record as dev content is).
- **Seeded per bot:** `Seeds.kit_seed(match seed, character id)`, a stream of its own, so a seed replays the same kits
  and no other seeded stream moves.
- **A kit is built as your loadout is** (`LoadoutRules.carried`: parts, power source, magazines, the site limit), by
  rules that follow no progress (`PlaySession._bot_kit_rules`), so what you have unlocked never changes it. A kit with
  no Secondary carries its primary alone. Each replica comes on full auto where it has it (bots never touch the
  selector, as in the browser game): the kit's own copy of the config, so the Cyber Pistol in your hands still comes on
  semi.
- **Your teammates carry their replicas as they come** (bot-kits.md); the other team's bots pick. Their figures get
  their parts' figure copies (`FigureView.setup`'s parts, by character id).
- **Suits is read and checked but not used yet:** bots have no personalities in this game, so every kit keeps its
  weight (bot-kits.md's guide says so). The lean comes with personalities.
- **The match guards and the balance report kit every bot** on both teams at Normal by the same weights
  (`MatchRunner.kitted`, `difficulty`), so both ends carry gear alike and the fields stay comparable; each tally
  records the kits picked.
- **A rematch keeps the kits:** the characters, figures and hands are built once a session, and a rematch restarts the
  match on them. Picking again would rebuild every view; it can wait until a rematch rebuilds the session.
- `Pool.named` (a Name or ID, waiting items too) and `DataTable.names` (a comma-separated cell) moved out of
  LevelTable so both readers share them.
- **Outside the block's touches** (the critic's check 8): `game/sim/seeds.gd` (`kit_seed`, the kits' own seeded
  stream), `game/pool/pool.gd` (`Pool.named`) and `game/progress/level_table.gd` (now reads through `Pool.named` and
  `DataTable.names` instead of its own copies). Each is the smallest home for what both readers share.
- The tests look shipped kits up by name, so reordering bot-kits.md never breaks them (the critic's advisory).
