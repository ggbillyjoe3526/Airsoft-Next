# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## AC6 · Screen reader messages for hits and rounds
tier: ui
perf: skip
touches: game/ui/announcer.gd, game/ui/hud_announce.gd, game/ui/hud.gd, game/ui/hud_feed.gd,
  game/ui/settings_access_page.gd, game/ui/text/en.po, project.godot, docs/ARCHITECTURE.md,
  tests/unit/test_announcer.gd
contract: Events (3); Headless (9)
acceptance:
  1. Announcer (plain RefCounted) turns events into lines with the HUD's own words: each hit feed line ("Beta 2
     called HIT · Alpha 3", "You" for the player), your own hit ("You're hit · Beta 2"), round start ("Round 3"),
     round over (winner, reason and score), match over. Lines inside 0.3 s are joined into one message.
  2. HudAnnounce is a Label kept in the accessibility tree but not drawn, accessibility_live POLITE (your hit and the
     match result ASSERTIVE); with Screen reader messages off it is LIVE_OFF and gets no text.
  3. project.godot states accessibility/general/accessibility_support = 0 (Auto: AccessKit runs only while a screen
     reader does, so it costs nothing otherwise); ARCHITECTURE notes it.
  4. GUT: each event's line; the join window; off sends nothing; the label's live mode.
  5. The tab's Screen reader messages row loses LATER; the record lists the owner's NVDA and Orca checks.
status: open
attempts: 0

## AD1 · Adaptive difficulty (Dev)
when: build order step 31, after the late features (owner, 2026-10-22)
tier: core
perf: optional
touches: game/ai/, game/config/, game/save/dev_settings.gd, game/ui/settings_screen.gd, game/play/play_session.gd,
  game/ui/xp_card.gd, game/progress/, tests/
contract: Data, not literals (6); Saves (8)
acceptance:
  1. A Dev switch makes the other team's skill a rating that blends the levels' numbers (the browser game's
     adaptiveDifficulty.ts): up a little after a round or match you win, down after one you lose, within its limits;
     the on/off habits come from the nearest level and stay fixed through a match. It never changes a level's own
     numbers (DECISIONS 2026-10-06).
  2. Your teammates never adapt; an adaptive match gives no XP and stays out of the records.
  3. The rating is saved and the end-of-match card says where the next match starts.
status: open
attempts: 0
