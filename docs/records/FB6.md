# FB6 · Back to the Match page, your team on the left, the sight even at any game speed (fix)

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-30 | 1 | worker | see Verified | – | – |

## Goal

William's 0.1 Dev 1 notes, verbatim: A "When the player leaves a round they should go back to the MATCH screen not the
title screen." B "When a player selects their team 'Alpha' or 'Beta' their team should always be on the LEFT of the
scoreboard. For example, I'm playing as Beta and it still reads ALPHA BETA. It should be BETA ALPHA." C "game speed at
25% is stuttering when ADS. possibly also stutter present at 150% but animations are too fast to tell."

## What changed

- **A, leaving** (`main.gd` `_end_play`). Leaving practice already opened the Match page; leaving a match built the
  screens again with the title showing. Now every way out of play (the pause menu's Quit match or Leave practice, a
  map that won't load's back button) lands on the Match page with Play focused, the picks kept. The AIRSOFT wordmark
  still opens the title. The refusal's button reads "Back to the menus" (`en.po`).
- **B, your team on the left** (`hud_score.gd`, `hud.gd`). The score bar laid Alpha out left and Beta right whatever
  your team. `setup` now takes the team drawn on the left (yours) and places each team's pips, colour block, score
  and ATK / DEF tag at its end; every other call still names teams, so the HUD's updates are unchanged. Each team
  keeps its colour, and Beta its stripes with gauge patterns on. Your team is a character's fixed team (only the ends
  on the field swap at half time), so the bar never changes sides during a match. The Tab scoreboard, the round's
  table and the match summary already listed your team first (and the match stamp's score); tests now pin all three.
  `HudTable.team_names` is a test accessor.
- **C, the sight at any game speed** (`aim_follow.gd` new, `first_person_view.gd`, `replica_view.gd`,
  `play_session.gd`, `aiming.gd`). The cause: the camera's zoom, the replica's sight alignment, the sway's steadying
  and the optic glass all read `Character.aim_raise`, which moves once a simulation tick and was never drawn between
  ticks. At 25 % the pacer runs a tick every fourth frame, so the sight held for three frames and jumped a tick's
  share (a ninth of the raise at 0.15 s) on the fourth; at 150 % it moved one tick on one frame and two on the next.
  Now `AimFollow` draws the raise following the simulation's at the simulation's own raise speed
  (`Aiming.raise_time`, the one formula the tick uses) over the simulation time each frame stands for (frame time
  times the pacer's rate): the same step every frame at any speed, never ahead of the simulation and never more than
  a frame's worth (or a tick) behind. It snaps when the view moves to someone else or they are out. The view's recoil
  follows over simulation time too (`FirstPersonView.sim_rate`), so slowed it eases between ticks instead of stepping.
  Sway from the mouse, the kick's recovery and the carry stay on real time (they never stepped).

## Defaults taken

- **The summary's continue is not a way out:** a click on the match summary starts the next match (as before); the
  only ways out of play are the pause menu's leave and the refusal's back button, both now on the Match page.
- **A follower, not interpolation, for the raise:** the tick-to-tick fraction is exact below 100 % but at 150 % only
  one past tick is kept, so it cannot spread one and two ticks evenly; following at the simulation's own speed does,
  and adds no field to the simulation.
- **Only the sight path:** at 150 % everything else drawn between two ticks (positions, figures, BBs) still moves one
  tick on one frame and two on the next; spreading that needs more than one past tick kept. Not seen as a problem yet
  (KNOWN_ISSUES).

## Verified

- `tests/unit/test_fb6.gd` (new, 9): leaving a match from the pause menu and leaving practice land on the Match page
  with Play focused and the title hidden, and the wordmark still opens the title; on Beta the score bar's Beta block,
  score, pips and ATK tag sit left in Beta's colour and stay there after half time, on Alpha as before; on Beta the
  Tab scoreboard, the round's table and the summary list BETA then ALPHA; at 25, 50, 100, 150 and 200 % the drawn
  raise moves the same step every frame from the first to the one it arrives on (no hold, no doubled step), the FOV
  narrows and the replica moves every frame, never ahead of the simulation and at most a frame's worth behind; the
  follower snaps when out and on a new view; recoil eases over simulation time. A control shows the simulation's own
  raise holds for three frames in four at 25 %.
- Against main (a scratch tree): the leave test fails (menus hidden, title shown) and on Beta the score bar's Beta
  score sits right (x 370 against Alpha's 136); the new file does not compile there (no `AimFollow`).
- `tests/unit/test_mn1_qa.gd`: the leave test that pinned the title now expects the Match page.
- Pictures (Compatibility, Xvfb): `/mnt/project-files/screenshots/dev1-feedback/fb6-beta-score-bar.png` (on Beta, 3–1:
  Beta's striped orange block and pips left, Alpha blue right) and `fb6-beta-tab-scoreboard.png` (BETA first, "your
  team").
- Not verified: how the slowed and sped-up sight feels in play (owner).

## Gate

gdlint clean on every changed script; `tools/unit_tests.sh` 1, 2 and 3, `tools/smoke_test.sh`, `python3 tools/wiki.py
check` and `tools/changelog.sh check`: see the hand-off report.
