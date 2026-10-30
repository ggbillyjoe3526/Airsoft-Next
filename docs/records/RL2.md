# RL2 · Manual reloads by default, with a prompt; Automatic in Settings (Dev 1 feedback, fix)

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-30 | 1 | worker | see Verified; QA Pass, performance Pass | Accept 8/8 | – |

## Goal

The owner (2026-10-29): "Weapons currently automatically reload. This shouldn't happen. By default a prompt should come
up for the player to press the R button. In the settings there can be a setting to toggle between manual and automatic
reloads." The auto-reload was `Armament.step`'s dry-fire branch: a trigger pull on an empty magazine clicked dry and
started a reload when a spare had BBs.

## What changed

- **Sim** (`player_command.gd`, `armament.gd`, `vault.gd`): `PlayerCommand.manual_reload`, the controller's setting
  (reset to false, copied, kept through a vault). With it on, the dry click no longer starts a reload; R does.
  `Armament.reload_due()`: empty, a spare with BBs, nothing under way, not holstered (the prompt's rule).
- **Controller** (`player_input.gd`, `controls_config.gd`): `ControlsConfig.auto_reload` (false: Manual); `fill` writes
  `manual_reload = not auto_reload` into every command, also while the mouse is free. Bots, the range pilot and the
  smoke test's autopilot never set it, so they reload on the dry click as before.
- **Setting** (`settings.gd`, `settings_apply.gd`, `settings_screen.gd`, `en.po`): `auto_reload`, saved as
  "auto_reload"; Settings › Controls gets one switch row, RELOAD: Automatic / Manual, after Aim (section renamed
  CROUCH, AIM AND RELOAD), in the existing `add_check_row` style.
- **Prompt** (`hud_reload_prompt.gd`, new; `hud.gd`; `play_session.gd`): the Reload key's cap (`MenuParts.key_chip`,
  read from the input map when it comes up and on resume, so a rebind shows) and RELOAD on a small plate, in the vault
  prompt's column under the crosshair. Shown while the player's last command was manual, you are in play, the round
  is live and `reload_due()`; hidden on a reload starting, a hit, a round or match end, Automatic, or no magazine left.
- Tests: `tests/unit/test_manual_reload.gd` (new, 12), one row test in `test_settings_screen.gd`; `MatchRunner` gets
  `manual_reload` (every bot's command marked manual).
- Docs: wiki Settings, How to Play, HUD and Minimap; PLAYTEST; DECISIONS (the owner's ruling); `game/sim/README.md`.

## Decisions / Defaults taken

- **The setting reaches the sim through the command** (`manual_reload`, written by PlayerInput), not a field on the
  character: every controller states its own, and bots and the pilots keep today's rule with no special case.
- **Bots unchanged:** `BotCombat.reload_when_due` already sends `reload` when empty; a Depot match with every bot's
  command marked manual plays identically (same shots, hits, reloads), so the dry-click reload was never theirs.
- **No migration step or version bump:** a save without "auto_reload" (version 1 or 2) loads Manual, which is the
  owner's default; an Automatic pick is kept.
- **The row sits with crouch and aim** (section CROUCH, AIM AND RELOAD): the same hold/toggle-style choices; one row,
  no new widget, so UI1's restyle is not touched.
- **Prompt only on Manual:** on Automatic the next pull reloads, as before, so a prompt would teach the wrong key.
- **The prompt stays in the vault prompt's column** under the crosshair: where your eyes are when the replica clicks;
  it drops a line when the vault prompt shows.

## Verified

- `test_manual_reload.gd` 12 pass: a manual dry pull never reloads (3 pulls, held trigger clicks once), R reloads,
  Automatic still reloads on the click, `reload_due` cases, the command's copy and reset, PlayerInput writes the
  setting, a bot asks for its own reload, the Depot match with every bot on manual plays the same, the settings default
  and a version 1 / 2 save loading Manual, applying the controls, the prompt shows and hides (reload, Automatic, match
  over, hit, no magazine left) and names a rebound key. Settings screen row test passes.
- `tools/match_guards.sh test_match_guards depot_matches_play_out_on_every_seed`: PASS (129 rounds over 16 seeds).
- gdlint clean; `unit_tests.sh` 1: 885/885, 2: 1973/1973, 3: 929/929; `smoke_test.sh` PASS; `wiki.py check` OK;
  `changelog.sh check` OK.
- Picture (Compatibility, Xvfb, 1920 x 1080, a Depot `PlaySession`, your magazine emptied):
  `/mnt/project-files/screenshots/dev1-feedback/rl2-reload-prompt.png`.
- Not verified: how it feels (whether the prompt is easy to spot without being in the way, on Forward+).

## Advisories left

- **`hud.gd:92`:** `var manual_reload` sits between the two leaves-notice fields (critic).
- **The prompt has no HudAnnounce line**, so a screen reader never hears it (critic, QA).
- **`docs/FEATURES.md:27`** (HUD line) doesn't mention the reload prompt (critic).
- **After switching to Automatic from the pause menu** the prompt can linger one frame on resume (QA).
- **The prompt also shows during a draw**; R then queues the reload and the prompt hides (QA).

## Gate

`tools/check.sh` runs in CI; the worker ran gdlint, the three unit test parts, the smoke test, one match guard,
`wiki.py check` and `changelog.sh check`.
