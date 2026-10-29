# KI1 · Fix the contained known issues before 0.1 Dev 1

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-29 | 1 | worker | see Verified and Gate | – | – |

## Goal

William's 0.1 Dev 1 feedback asked to "check all known issues and attempt to solve as many as possible". This task
fixes the rows a triage of `docs/KNOWN_ISSUES.md` found contained (one file or two, no ruling needed), deletes the
stale rows, and keeps the rest.

## What changed

- **No ping from the open wheel** (`game/input/player_input.gd`): a ping press counts only while the order wheel is
  shut; the wheel holds the view still, so a ping landed where the view was left.
- **Need a Mag with the wheel open** (bug-pass find, no row): H pressed while the wheel is held open now answers in the
  wheel's middle (`_mag_latch_wheel = from_wheel or _wheel.open`), as F, X and V's notices do; the line under the
  crosshair, where it answered before, is hidden while the wheel is open.
- **Lean rustle gap** (`game/play/foley_tracker.gd`, `game/config/sound_config.gd` `foley_lean_gap` 0.6 s,
  `game/play/sim_audio.gd`): one character's lean rustles at most once a gap, yours too.
- **Map spots checked** (`game/map/map_data.gd`): `overtimeFlag` and `flag` are a spot only with numbers for x and z
  (and y if given); anything else given is none, with a warning naming the key. `_vec` reads a non-number as 0 instead
  of stopping the read.
- **`MatchOptions.KIND_MODES`** is a `Dictionary[StringName, Array]` (GraphicsTable's pattern), so it can't hit Godot
  4.7.2's const `Dictionary[K, PackedStringArray]` crash.
- **ReportScrub** takes a web address's user and password out (`https://<credentials>@host/`) before the e-mail
  pattern; tried only after "://", linear on any line.
- **Hold here at the match's end** (`game/play/play_session.gd`): MATCH_OVER clears the orders, so the marker and its
  minimap diamond go from the results.
- **Woodland's card** (`tools/map_pictures.gd`): the render adds `BushView` beside the woods (`add_woods`, now static so
  a test can call it); `assets/maps/woodland.jpg` re-rendered under Xvfb with the Compatibility renderer (its
  `.import` is unchanged: same UID and settings).
- **Bots hunt inside Woodland's hut** (`game/ai/round_planner.gd`): a hunt spot takes the highest walkable floor of its
  column a route from the bot reaches (`_reached_floor`), not the column's top floor; a column with none is drawn
  again.
- **The Match page remembers the last map and team** (`game/progress/progress.gd` `last_map`, `last_team`,
  `remember_picks`; `game/ui/match_picks.gd` `recall`; `game/main.gd`): kept in progress.save when you press PLAY,
  read at launch.

## Known issues rows

- Deleted (fixed): the order wheel's ping, the lean rustle, the const Dictionary, `overtimeFlag`, ReportScrub's web
  address, Hold here's marker, Woodland's card, the Match page's picks, bots in Woodland's hut (see Gate for the
  guards).
- Deleted (stale): ricochets can't be changed in play (`game/ui/match_rules_box.gd` has the Ricochets choice writing
  `custom_rules.ricochets_count`); Depot is the greybox (`game/play/site/site_surface.gd` bevels and finishes,
  `docs/ART.md` › Material families: DD1 and DP2 landed). The Match page row's "bots' levels and Attack / Defend
  greyed LATER" was stale too (`MatchOptions.BUILT_MODES` holds all three modes).
- Trimmed: the Practice swinger row drops Neon Heights; the HUD replica panel row drops "no hit feed until step 14"
  (`game/ui/hit_feed.gd` exists). The Depot props row now waits for Depot's redesign in 0.1 Dev 2.
- Left: the GBB Pistol slide-lock row (`replica_view.gd`, another task's file now) and every row the triage kept.

## Defaults taken

- **The last map and team live in progress.save** (the player's profile), not Settings: they are no options, and the
  save bundle, restore points and Undo already carry that store. Older builds keep the fields as unknown keys.
- **Remembered when you press PLAY** (a match started from the Match page), not on every card click: the picks of a
  match you played. Back from the Loadout into practice and the smoke run remember nothing.
- **Not in a headless run** (the tests and CI): a test's match would otherwise write the shared user folder's
  progress and change the next run's Match page.
- **A map the catalogue no longer has keeps Depot**, the first card; one listed but greyed (dev content off, or it
  can't load) falls back to the first playable card as the page already did. A team that isn't 0 or 1 is Alpha.
- **The lean gap is 0.6 s** (`SoundConfig.foley_lean_gap`): a real peek every 0.6 s still rustles; turning against a
  wall ten times a second rustles at most twice a second.
- **A spot with a non-number coordinate is no spot, with a warning,** for the pole too (the same read).
- **Credentials become `<credentials>`,** a word of its own, so a report says what was there.

## Verified

- New tests, each failing without its fix (checked by reverting the game file): `test_order_wheel_input.gd` (a ping
  press with the wheel open), `test_mag_hand_off_hud.gd` (H with the wheel open, `mag_from_wheel`),
  `test_foley_tracker.gd` (a lean restarting within the gap, another character's own gap), `test_ov1_qa.gd` (spots
  with a string, null, list or object coordinate: none, one warning each), `test_match_page.gd` (KIND_MODES' value
  type), `test_report_scrub.gd` (credentials, a path's "@" kept, 60,000 characters under 500 ms),
  `test_so4_qa.gd` (Hold here's marker gone after MATCH_OVER), `test_bushes.gd` (the card's render adds a BushView of
  every bush), `test_woodland_layout.gd` (ten hunt spots drawn over the hut are all on its floor),
  `test_levels.gd` (picks saved with the progress, recalled; a removed map, a wild team and a new player fall back).
- `tools/map_pictures.gd` re-rendered Woodland: the bushes show as dark green clumps across the meadow and the copse
  (`/mnt/project-files/screenshots/dev1-feedback/KI1-woodland-card.png`).
- Not verified: how the lean gap sounds, and the remembered picks across a real quit and launch on the owner's PC
  (PLAYTEST lists both).

## Gate

Pending.
