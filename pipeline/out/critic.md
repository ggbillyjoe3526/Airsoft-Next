Task: MH2 · Bots ask for magazines and bring them
Attempt: 1 of 4
Head: 51ebaa5 (vs MH1 9fbce06; the critic re-ran test_bot_mag_share + test_mh2_qa on it: 26/26)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✗
Score: 7/8 → Accept (QA Pass, performance Pass with its one fix done in 51ebaa5)
Evidence: 1 bot_mag_share.gd:57-70 (press to ask, primary only), :105-112 (toss in reach and sight, sprint over
mag_hurry_distance, walk to mag_walk_up_to), :113-117 (walks up to a player it asked); bot_brain.gd:151-167 (fight,
cover, bringing, order, pole, waiting); callouts.gd:197-201, 294-300; bot_intent_view.gd:14; dev_cheats.gd:63-85,
bot_controller.gd:95-97; test_match_guards.gd MagWatch (Depot 33 served max 9.6 s, Woodland 47 max 4.7 s, 0 late;
Neon Heights dropped by the coordinator); KNOWN_ISSUES row replaced by the narrower MH3-bound one. 2 presses go
through PlayerCommand.mag_hand_off; tuning in BotConfig › Magazine hand-off. 3 update/ask_when_low/waiting/move and
_pace_allows allocate nothing (code read; test_bot_mag_share.gd:534, perf OBJECT_COUNT +0). 4 test_bot_mag_share.gd:338
asserts mag.asked == 2 and giver.mag_for: at 9fbce06 no bot presses, so it fails.
Failed checks, with evidence:
8. [judgment] docs/wiki/Development.md:54-59 lists the Dev tab's switches and those that keep a match off the record
   but not Bots run low on BBs, and Bot intentions doesn't say it now shows bringing or waiting for a mag.
   docs/wiki/Bots.md:89 and :91 tell players a bot brings "your" ask and waits "for your toss": nothing binds
   mag_hand_off for the player until MH3, so the page describes what a later PR adds.
Must-fix (non-blocking, fold into this PR or MH3): add Bots run low on BBs to Development.md (list and off-record line);
word Bots.md's player part as coming with MH3 or drop it until then.
Advisories:
- bot_controller.gd:97: the bots' controller writes armament state (DevCheats.run_low); contract 2 says bots read state
  and fill commands. A dev cheat, deterministic, so not failed; its home is the simulation step with the other cheats.
- Guard exclusions are the worker's reading of criterion 4: up to MAG_HELD_MAX 2 "held by the giver's fight" (1 used,
  Depot seed 16) and 7 of 55 Depot bots "nobody to ask" never served. Consistent with criterion 1; owner may confirm.
- bot_mag_share.gd:194-202 is the 4th copy of _character/_flat (bot_senses, pings, bot_hearing); a BotWorld helper.
- bot_controller.gd:130 returns Bot.Mode.size() as the waiting sentinel; dev_cheats.gd:67 ammo[0]: named constants.
- Unwrapped long lines: bot_controller.gd:7, dev_settings.gd:5 and :51, settings_screen.gd:35.
- The record doesn't say where magShare.test.ts's player cases (hint, "says why", HUD line) went (MH1/MH3).
Owner should test in the game:
- Dev › Bots run low on BBs on Depot: a teammate calls Mag coming, sprints, slows near, tosses; asker says Thanks.
- Bot intentions shows Bringing a mag / Waiting for a mag and the labels switch back afterwards.
- Stand nearest a low bot: it walks up and waits 15 s for a toss you can't give yet (MH3); does it get in the way?
- A giver in a fight: the asker standing in the open meanwhile, does it read as silly or fine?
- Need a mag / Mag coming / Thanks pacing: not spammy with Reloading and other calls.
- Attack / Defend: a bot off to the pole never comes; does the asker's wait feel off?
