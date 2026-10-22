# SO1 · Orders through the command, and Hold here

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Opus (QA's test-time advisory fixed by the build thread) | pass | 8/8 accept | |

## Decisions

- **Step 17 is four tasks** (plan: `/mnt/project-files/plan/step17-squad-orders.md`): SO1 (this, the orders and Hold
  here), SO2 (Follow me and Regroup), SO3 (the order keys, the wheel's input, the radio click), SO4 (the wheel and hold
  marker on screen, from concepts the owner approves). Pings, Need a Mag and callouts stay at steps 29 and 30.
- **An order rides `PlayerCommand.squad_order`**, so bots stay honest and a bot leader orders as you do. The sim turns
  it into `SQUAD_ORDER`, or `SQUAD_ORDER_REFUSED` while you're out or between rounds, reading it before the out and
  vault substitutions; the event is its only effect.
- **`BotController` hands orders out** in `observe`, after the step: the same key again cancels, the wheel keeps an
  order in force, Hold here again moves the hold only when you look somewhere else, Team plan ends it. An order ends
  when its giver or the bot is hit and at a new round. `order_outcome` (giver, order, notice, serial) is for SO3/SO4.
- **`Bot.Mode.ORDER` sits after a fight and before the pole:** an ordered bot still fights what it sees and stands aside
  from raising and retaking the flag, team waits, rusher pushes and anchor holds; it goes back when the order ends.
- **Hold here is the browser's:** the spot you look at (within `hold_range`), the bots side by side across it, a wall
  gap, watching your way; looking at nothing, each holds where it stands; an unreachable spot, where the bot got to.
  Its numbers are `SquadConfig` in `bot_tuning.tres`; Follow me's and Regroup's come with SO2.
- **No order, no change:** QA ran six whole bot matches hash-identical to main; performance measured +1.5 % a tick,
  inside noise.
- The squad tests build each test field's nav grid once (QA: the file took 54 s and the unit gate times out at 600 s).

## Known issues left

- Bots under Follow me or Regroup stand where they are until SO2 (no key gives those orders before SO3).
- For SO2 (sent to its worker): an order given in the tick its giver is hit reads NOBODY rather than NOT_NOW;
  `_partner_moving` lacks the browser's order check for the one tick before a bot's think; the order bookkeeping
  could move out of `bot_controller.gd` (370 lines).
- Owner to test once the keys land: bots play as before with no orders (lanes, pole, pairs), and Bot intentions never
  shows "Under orders" unless you gave one.
