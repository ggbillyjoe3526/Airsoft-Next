# PN1 · Pings: the mark, and how bot teammates take it

**Review:** pending (critic, QA, performance)

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-26 | 1 | worker | see Gate | – | – |

## Goal

The browser game's pings (PG1) in today's systems: the middle mouse button marks where your view meets the field
within 120 m for your bot teammates; an enemy you can see under the view is a contact. Bot teammates take it as a
noise heard exactly there, kept 20 s, and one answers; a teammate's Contact call may mark its enemy for you. PN1 is the
mark and the bots' response, kept in a ping book; PN2 draws it. Plan: project files `plan/step27-deferred.md` › Pings.

## Approach

- **Input.** `ping` in project.godot's input map and `KeyBindings` (middle mouse, after the order wheel, "SQUAD: PING
  A SPOT" in `en.po`). `PlayerInput` latches a press and `fill_order` writes `PlayerCommand.ping` once; dead while
  `allow_orders` says no keys (the range). The press sits after the order wheel's in the input's chain.
- **Simulation.** `PlayerCommand.ping` (one-shot) becomes a `GameEvent.Kind.PING` (appended) from a character in play
  in a live round, never in practice: from `Lean.eye`, along yaw and pitch plus the replica's recoil, after the
  character's step; value 1 with the distance to what the view met within `PingConfig.reach`, value 0 for nothing.
  It changes no state.
- **`PingConfig`** (`game/config/ping_config.gd`, new; the browser's config/pings.ts): reach 120 m, cone 2.5°, up
  close 0.5 m, spot snap 3 m, back-off 0.4 m, lifetime 8 s, gap 0.25 s; `SimTuning.pings`, in `sim_tuning.tres`.
  `BotConfig.ping_memory` 20 s.
- **`Pings`** (`game/ai/pings.gd`, new; the browser's ai/pings.ts): the ping book, one reused `Ping` per character id
  (kind, point, floor spot, enemy, owner, team, time, marked) and `placed`, the serial the HUD will hear a new one by.
  `place` resolves a PING event: an enemy in play within the cone of chest or head, nearer than what the view met and
  seen by `BotSenses.visible_part` at the ping's reach is a contact (chest point, feet spot); else the nearest walkable
  floor within 3 m of a point 0.4 m back toward the pinger (`NavGrid.nearest_walkable`); the sky, an out pinger or a
  press inside 0.25 s of the last ping place nothing. `mark` puts a Contact call's mark in the caller's slot. `take` is
  the browser's takePing. `clear` each round; `is_up` within 8 s.
- **Bots.** `Bot.ping_at`, `ping_spot`, `ping_in_mind` and `on_ping_spot`; `threat_in_mind` counts a ping in mind, so
  `BotBrain` plays it as it plays a noise (search by personality, watch from a post, keep an order and watch it) with
  no change of its own. `BotController.observe` hands each PING to the book and the pinger's teammates take it; a new
  round clears it.
- **Callouts.** `_answer_ping`: once the bots have thought on a ping (taken before this tick's think), Going to your
  ping from the nearest that set off for it, else Watching your ping from the nearest that took it; Heard and
  Checking / Pushing / Flanking are not said of a ping. `_mark`: a Contact or Contacts said marks its enemy by
  callouts.md › Marks (35 %, 12 s a team) while the speaker still sees them, on a stream of its own.
- **Outside `touches`:** `game/ai/bot_senses.gd` (`visible_part` takes an optional reach: the bots' view is 40 m, a
  ping's 120 m) and `tests/unit/test_so3_qa.gd`'s finding (no edit there; the input's order changed instead).
- Tests: `test_pings.gd` (23): the browser's pings.test.ts (floor spot and both teammates, the sky and past the
  reach, off a wall, a contact at the feet, not behind a wall, in a bush or behind a body, your team's only and nothing
  while out, going to look, under an order watching, take ignored in a fight, in cover, with a target or out, spot vs
  contact threat, ping memory, rusher vs careful sprinting, the same seed repeating) and matchSessionPings.test.ts
  (recoil in the view, the gap and a miss starting none, nothing between rounds or on the range, a Contact call's mark
  by chance and gap at the enemy's body); plus a contact past the bots' view distance, the book's lifetime and round
  clear, the answer (one Going, no Checking or Heard; Watching under an order), marks changing no line at 0, 0.35 or
  1, the press filling one tick and dead on the range, and ticks pinging every half second allocating nothing.

## Risks

- Nothing shows yet: a teammate's answer in the feed is the only sign a ping was taken until PN2 (KNOWN_ISSUES).
- A ping keeps a bot on its spot 20 s: a far ping can pull a teammate off its lane for a long walk. The browser's
  number, tuned there; PLAYTEST asks.
- A bot-only match places marks in the book for both teams (nobody reads them); the marks' stream is its own, so it
  plays and talks the same.

## Defaults taken

- **The 0.25 s gap lives in the ping book, per character, and only a ping placed starts it:** the simulation changes
  no state, and the browser's session started the gap only on a ping that found something.
- **The PING event is raised for the sky too (value 0):** an enemy against the sky can still be a contact, as in the
  browser, which looked for one along the whole reach.
- **No ping in practice, in the simulation as well as the input:** nobody on the range to take it.
- **Contact sight reaches 120 m (`visible_part`'s optional reach), not the bots' 40 m:** the browser's pingSight gave
  the bots' rules the ping's reach; a bush, the dark or a body still hides.
- **The answer waits until the bots have thought on the ping** (`ping_at` before this tick's think), so Going to your
  ping is said by one that really set off; "goes" also needs its search to be for the ping spot.
- **The marks draw on the callouts' seed with the browser's MARK_SALT flipped (`MARK_XOR`):** "on the callouts' stream"
  without changing the lines, which `test_marks_change_neither_the_lines_nor_play` pins.
- **A mark takes the caller's slot in the book** (owner the caller, `marked` set), one ping per character as the task
  says; bots never take a mark.
- **A middle click while the order wheel is open still pings** where the view was left (KNOWN_ISSUES row).

## Measurements

- A ping resolved and taken by two teammates: about 21 µs (a spot) and 23 µs (a contact) on the open test field,
  2,000 each (scratch timing, CPU shared with another tree's gate). A press is at most one per 0.25 s; the search it
  starts is planned within the routes' tick budget as any other.
- Ticks with a ping every half second, spots and contacts in turn, allocate no object (`test_pings.gd`).

## Verified

- `test_pings.gd` 23, and `test_callouts.gd` 75, `test_callouts_qa.gd` 11, `test_callouts_feed.gd` 25,
  `test_key_bindings.gd` 18, `test_order_wheel_input.gd` 17, `test_player_input.gd` 16, `test_so3_qa.gd` 11,
  `test_so4_qa.gd` 10 pass.
- With no ping a match plays as before: `threat_in_mind`, the callouts' exclusions and `visible_part` change only once
  a ping is taken, and the marks' stream is separate. `tools/match_guards.sh test_match_guards` (5) played the same
  rounds as on OV1's record (Depot 121 and Neon Heights 120 at Normal over 16 seeds; 65, 56, 59 and 56 at Easy and
  Hard over 8), and `test_callout_guards` (4) passes; Woodland's and the Attack / Defend guards are left to CI.
- Not verified: how it plays with a person (middle mouse, the answer's timing): PLAYTEST › Squad orders and minimap ›
  Pings.

## Gate

`tools/check.sh` on `bd27fbb` (PN1 on OV3's branch), on the 4-core container shared with another tree's gate, 1,207 s:
gdlint, the changelog notes, the wiki, the smoke test and the licence notices passed; unit tests part 1 in 373 s and
part 2 in 380 s, all passing; part 3 failed one of 911, `test_so3_qa.gd`'s mouse button as the wheel's key (the test
puts the wheel on the middle button, which the ping held first in the input's chain). With the ping after the wheel
(`4478d8f`), part 3 again: 911 of 911 in 364 s (3,422 tests, all passing). No part near 570 s.
