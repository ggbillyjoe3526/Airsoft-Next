Task: RL2 · Manual reloads by default, with an R RELOAD prompt; Automatic in Settings (fix)
Attempt: 1 of 4
Head: 28ae917 (checks passed on it: QA's tools/check.sh green, 3802/3802, smoke, wiki, changelog, licences)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. No auto-reload under Manual: armament.gd:+327 `next_spare() >= 0 and not cmd.manual_reload`; prompt with the bound
   key: hud.gd:+840 show_when(manual_reload and in_play and is_live() and reload_due()), hud_reload_prompt.gd:+37-46;
   setting: settings.gd:+72/+249 (default Manual, old saves load Manual), settings_screen.gd:+246 row, en.po.
2. Commands contract kept: the setting rides PlayerCommand (player_command.gd:+27), the one interface every controller
   uses; bots and pilots reset it to false and keep their own reload (match guard and the Depot same-play test).
3. Per frame: one bool copy (play_session.gd:+1047) and short-circuited field reads; reload_due/next_spare loop
   without allocating; key text rebuilt only on hidden -> shown and on resume. Perf: Pass.
4. test_manual_reload.gd:57 fails on origin/main (RELOAD_START 1, not 0); QA's vault test fails with the old vault.gd.
5. Rule in Armament (sim), HUD only reads reload_due and the command; typed throughout; pads and gap are named consts.
6. A dry click then a deliberate mag change is airsoft; the owner's ruling is in DECISIONS, Automatic kept for those
   who want it; the prompt is the one named exception to "no hints".
7. Prompt is its own 50-line script, built once, child of the HUD, no signals or timers; the settings lambda is
   connected once in _build_controls.
8. Scope is the owner's ask; DECISIONS, wiki (Settings, How to Play, HUD), PLAYTEST, sim README, changelog note done.
Advisories (not blocking):
- hud.gd:+92 `var manual_reload` sits between `_leaves_notice` and `_leaves_left`; move it below the leaves pair.
- hud.gd:+840 the prompt has no HudAnnounce line, so a screen reader never hears RELOAD (QA advisory); KNOWN_ISSUES
  row or a follow-up.
- docs/FEATURES.md:27 HUD line doesn't list the reload prompt; for the changelog agent.
Owner should test in the game:
- Empty the AEG on Manual: each pull clicks once, R RELOAD shows under the crosshair, R loads and it goes.
- Is the prompt easy to spot mid-fight without covering the target (Forward+, 1080p and 1440p)?
- Rebind Reload in Settings from the pause menu, resume: the prompt names the new key.
- Switch to Automatic: the empty pull reloads as before and no prompt shows.
- With a vault prompt up and an empty magazine: both read, neither jumps about.
- Run dry with no spare left: no prompt, OUT OF BBS on the panel.
