# SO2 · Follow me and Regroup

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (SO1's two QA tests updated by the build thread at the rebase) | pass | 8/8 accept | |

## Decisions

- **Follow me and Regroup are the browser's** (`squadOrders.ts`): spots in pairs behind the giver, rows further back,
  straight behind and then the giver's own spot as fallbacks; pace from the giver (walk, run, sprint), one step up or
  down by the gap, a sprint beyond catch_up; followers watch behind and to the sides, on the move too
  (`bot_combat.gd`, outside the touches list, accepted by the critic). Two browser literals became data:
  `crouched_pace` and `follow_run_from`.
- **Regroup turns into Follow me** in `BotController.think`, before the bots think, once a bot reaches you; the order
  reads Follow me once none is still regrouping. An order given this tick is never turned in the same tick.
- **The order bookkeeping is `SquadOrderBook`** (`game/ai/squad_order_book.gd`, RefCounted): SO1's review sent it out
  of `bot_controller.gd` (386 to 245 lines). The controller keeps one-line delegates, so readers are unchanged.
- **SO1's review items:** a giver hit in the tick its order is handed out reads NOT_NOW; `_partner_moving` skips a bot
  under an order.
- **Follow guard on Depot** (in `test_match_guards.gd`, since CI runs guard files by name), measured in Godot before
  setting limits, seeds 1-4, 90 s: ticks judged 3225 / 5043 / 4025 / 3931; near 100.0 / 98.0 / 99.7 / 100.0 %;
  worst 4.73 / 6.96 / 7.40 / 6.64 m against catch_up 8; standing 0.67 % over the four against 3 %. The browser's
  limits stand.
- **No order, no change:** Depot and Neon Heights, seeds 1-4, 240 s, give identical tallies before and after (worker),
  and seeds 1-3, 150 s (QA). Performance: +11 % think time on Depot with five followers, about 9 µs a follower a tick.
- SO1's QA file: a bot given Regroup 3.6 m away now turns to Follow me, so the test asks only that it keeps an order;
  the allocation test warms 1050 ticks, as the event pool grows once followers move.

## Known issues left

- The follow guard's margin is 0.6 m (seed 3, 7.40 m against 8): re-measure after any nav or movement tuning.
- Four test files carry a copy of the open-field squad harness; move it to `tests/support` (can wait).
- A follower's heading only eases under its order: back from a fight it can take about 2 s to swing behind you.
- Owner to test once the keys land (SO3): Follow me at a walk, run and sprint with no stop-and-go; followers walking
  backward to cover you (readable or silly?); Regroup from across the map; sharp turns; three bots in a corridor and up
  Depot's ramp.
