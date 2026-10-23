# FI6 · Settings › Looks › Robots and the first-person arms hook

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus 5.5 (worker) | pass | Accept 8/8 | – |
| 2026-10-23 | QA attempt 1 | Opus 5.5 (worker) | pass | QA Pass (advisories fixed); performance Pass | – |

## Decisions

- **Mixed by default, an older save reads Mixed** (plan › 5, 10): `Settings.robots` is true; the key is read with the
  other flags' `_flag`, so a missing or non-bool value is Mixed. `Settings.VERSION` stays 1 (a new key with a default).
- **`Settings.robots` replaces `FigureConfig.robots`:** two switches for one thing would let the tuning file quietly
  override the player's pick. The field is deleted (`game/config/figure_config.gd`, outside `touches`); `robot_salt` stays.
- **"Paused in a match" is `SettingsScreen.end_round.is_valid()`,** as `can_replace()` already tells the title's
  settings from a match's: no new field on the screen or change to the pause menu (outside `touches`).
- **The page is a `SettingsLooksPage`** like the Accessibility page: `MenuCard`s with an IN USE `MenuTag`, built from
  `SettingsScreen.add_section`; the picks save at once (`changed(true)`), a click or Enter.
- **The cards take their screen-reader text from `accessibility_name` and `accessibility_description`** (their own
  text is a laid-over panel a reader can't see): the name is the choice, the description its blurb plus "IN USE"
  while picked, updated on every pick. The tab itself is read from its title as the other tabs are.
- **The kind goes through `FigureMix.pick` for everyone, you included,** so the practice kind is the one-member
  team's coin from the seed (a robot about half the time) with no second rule; `ReplicaView.arms_kind` is set right
  after the mix. No arm is drawn (step 32).
- **The mix still shows only behind Dev › Rigged figures** until FI7; the setting is read at the start either way, so
  `figure_kinds` and `arms_kind` are right with the switch off.

## Fixes after QA

- **A rematch reads the Looks setting again** (`PlaySession._refresh_kinds`, after `_sim.start_match`): the mix is
  picked again from the same seed, `arms_kind` set, and a figure whose kind changed gets a new body through
  `FigureView.set_body` when rigged bodies are drawn (`set_body` itself untouched). Before, a change made while paused
  ("From the next match.") only showed from a new session. The pick is one helper, `_pick_kinds`, shared with the
  first start.
- **The cards are described for the screen reader as they are built,** not only on the first refresh.
- **QA's probe file is folded into the real tests** and deleted: wrong-typed "robots" values read Mixed, the Tab
  and Enter order across the cards, Escape closing, no orphans after opening and closing the screen, and a rematch
  after a changed setting (replacing the probe's stale "rematch keeps the old mix" check).

## Checks

- Unit tests: `test_settings.gd` (148), `test_settings_looks_page.gd` (8), `test_figure_mix.gd` (13) pass.
- `tools/check.sh`: gdlint, changelog notes, unit tests (2,595 passing, 0 failing), the smoke test and the licence
  notices pass.
- Screenshots (Xvfb, Compatibility, 1920×1080): `pipeline/out/fi6-looks.png` (from the title, no "From the next
  match.") and `pipeline/out/fi6-looks-paused.png` (paused in a match, the line shown), viewed against
  `settings-looks.png`.

## Owner's checks

PLAYTEST › Players and replicas › Looks › Robots: Mixed then Humans only over two matches, and a screen reader reading
the tab and both choices.

## Known issues left

- The page differs from the concept in small ways: "ROBOTS" is 20 px where the picture's reads a little smaller, the
  cards sit 218 px from the top (the screen's section gap above the heading), and the Dev settings strip is the real
  screen's. The concept's two note boxes are not part of the screen.
- No arm is drawn: `arms_kind` has no reader until step 32.

## Advisories left

- A real screen reader may read the card's child labels as well as its name (the name and description are set on the
  card; the laid-over labels aren't hidden from it).
- The Looks page is built eagerly with the screen, like Display, Graphics and HUD (small: two cards).
- From the critic: `LABEL_TOP := 0` in settings_looks_page.gd pads nothing; the "From the next match." line
  reaches its pad through `_next.get_parent()`, which leans on the layout; DECISIONS › ST1 still lists the settings
  groups in the old order (the tab bar already differs).

## Outside `touches`

- `game/config/figure_config.gd` (the `robots` field removed), `game/play/figures/README.md` (docs).
