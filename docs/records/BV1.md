# BV1 · Bots vault low walls

**Review:** 1 attempt · critic Accept 7/8 (Opus) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-18 | 1 | Opus 5.5 (build thread) | ✓ | 7/8 Accept | – (QA's run log untracked and the files the change landed in recorded, the critic's must-fixes; QA added 2 tests) |

## Decisions

- **Vault links are the browser game's (M102, `nav/vaultLinks.ts`):** from each walkable node beside a blocked one of
  its floor, along the grid's four axes, `Vault.plan` from a standstill (the player's own rule, so 0.6 to 0.95 m, at
  most 1 m deep, open above); the link lands on the first walkable node one to three cells past the vault's clear
  point. Found once per grid when the bots are made, in the play session's `_ready` beside the grid's own build
  (so load time, before the first frame, not a hitch): Depot 10 links, all over the hall wall, in about 120 ms; the
  range 24 over its sandbag wall. Neon Heights has 14. Woodland has none until its step (27) builds its sloping ground and cabin
  for this game.
- **Each link is a search point of its own** between its two nodes, one way, weighted so stepping on and off costs
  its length plus `BotConfig.vault_price` (3 m, the browser's). AStar3D prices a step by the point stepped onto, so a
  plain edge could not carry the price. A walk-off (a called hit's walk) searches with the links turned off.
- **A route takes a link where the search's cells price the walk round higher**; walked straight, that walk is at
  least half the price longer (measured on Depot: 2.2 m to 6.9 m saved). The cells' staircase on a slant makes a walk
  round read a little longer than it is; tuning the price by play is cheaper than a second measure.
- **A vault is a leg of its own:** the route pulls straight to the takeoff node, then straight across to the landing.
  Its end counts as reached once the bot is past it along the leg, wherever the vault set the body down.
- **Bots vault through Jump:** on the first half of a vault leg the bot faces the way over and presses Jump when
  `Vault.find_along` says the vault is there, as the player's prompt does. Held up on a vault leg (`stuck_time`), its
  routes go round for `vault_retry_delay` (6 s).

- **Where it landed:** the task named `bot_movement.gd` and `nav_config.gd`, but route following lives in
  `bot_routes.gd`, the command in `bot_brain.gd` and the view in `bot_combat.gd`, and the price and retry are bot
  tuning (`BotConfig`, the browser's `BOT_BEHAVIOUR`), so the change went there. `BotController` links its grid when
  made (once per grid), so every way bots are made, the tests' included, gets the links.

## Known issues left

None new.
