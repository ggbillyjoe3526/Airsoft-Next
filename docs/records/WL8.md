# WL8 · Glowing BBs

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | worker | 3,149 of 3,149 | – | – |
| 2026-10-25 | 2 | worker | 3,166 of 3,166 | Accept 8/8 | QA and performance passed with fixes asked: white BBs paid for the glow test; a `glow` entry was kept for a non-replica |

## Goal

The browser's Glowing BBs (config/glowBBs.ts, BB_VISUALS.glowInDark): a Customise choice per replica beside BB weight,
At Night (the default), Always or Off, saved with the loadout, an old save reading At Night and every bot loading At
Night. A glowing BB is drawn green (157, 255, 122) with a green streak (92, 255, 74), never under 0.0045 rad, its streak
0.05 s of its flight, on every preset, with nothing drawn round it; white BBs draw as before. Drawing only: a seeded
match plays the same with every choice.

## Approach

- `Loadout` gains `enum Glow { NIGHT, ALWAYS, OFF }`, `glow` (each replica's choice by pool ID; one not there is At
  Night), `glow_of`, `set_glow` and the browser's `bbsGlow` as `Loadout.glows(choice, night)`; `copy` and `to_dict`
  carry it (`"glow": {id: "night" | "always" | "off"}`).
- `SavedLoadouts._loadout_from` reads `glow`: a loadout saved before it has none and loads At Night with no warning; a
  value or replica that won't read is At Night and listed. The file stays version 1 (a new key, nothing old changes).
- `LoadoutRules.carried` puts each slot's choice in `Kit.glow_bbs` beside its paint; `BotKits.GLOW_BBS` is At Night,
  the rule for every bot on both teams (bots don't use the Loadout; `kit_of` trims it with the other slot arrays).
- `BB.slot`: the loadout slot that fired it, set by `BBPool.spawn` (a new last argument, -1 by default) from
  `Armament._fire`. The simulation never reads it; presentation needs it so a BB keeps its colour when its owner
  switches replica mid-flight.
- `PlaySession._glowing_bbs` gives `BBView.set_glowing` one byte per character id, a bit per slot that glows on this
  field (`BBView.glow_bits`: your kit's choices, every bot's `GLOW_BBS`, under the preset's night flag), once a match.
  `BBView.update` takes the eye's position too, and the glowing materials join ShaderPrewarm's first-use list.
- `BBView` keeps its white BBs as they were (the same sphere, size and colour, no streak) and draws glowing ones in two
  child MultiMeshes: an unshaded green ball (`ball`: `bb_size`, never under `glow_min_angle` across its radius) and an
  alpha streak quad back along its flight (`streak_of`: `velocity × min(0.05 s, age)`, `glow_streak_angle` wide at its
  distance, turned to face the eye; not drawn end-on). Each child is hidden while no glowing BB flies. No quality input:
  every preset draws them.
- `EffectsConfig`: `glow_colour`, `glow_streak_colour`, `glow_min_angle`, `glow_streak_time`, `glow_streak_angle`,
  `glow_streak_opacity`.
- `CustomiseView`: a GLOWING BBS row under the BB weight's blurb, a `MenuChoice` of At Night, Always and Off with the
  picked one's line under it (the browser's blurbs); `glow_picked` reaches `LoadoutPage._pick_glow`, which edits the
  carried loadout and marks it changed (saved on leaving, as every Customise edit). Seven `en.po` strings.
- Tests: `tests/unit/test_glow_bbs.gd` (15; QA added `test_glow_bbs_qa.gd`); `test_play_session.gd`'s prewarm count takes the two glow materials.

Outside `touches`: `game/sim/bb.gd`, `game/sim/bb_pool.gd`, `game/sim/armament.gd` (the firing slot),
`game/loadout/kit.gd`, `game/loadout/loadout_rules.gd` (the kit's choices), `game/play/play_session.gd` (wiring),
`game/ui/loadout_page.gd` (the edit), `game/play/README.md`, `docs/DECISIONS.md`, `docs/KNOWN_ISSUES.md`.
`game/ui/part_options.gd` needed no change.

## Risks

- Tone mapping: the screen shows the green paler than its colour (Measurements; KNOWN_ISSUES row). The owner judges
  whether it reads as glowing.
- `BBView.update` costs about 1.4 µs more for each glowing BB (two transforms and a streak's few vector sums), and two
  more draw calls while any flies.

## Defaults taken

- **The choice is kept per loadout, per replica** (`Loadout.glow`), as the replica's setup is: every Customise edit
  goes to the carried loadout, and a copied loadout keeps it. The browser kept one per replica across loadouts.
- **Not in `ReplicaTune`:** a tune's numbers make how a replica plays; Glowing BBs only change the drawing, so they
  stay beside it and reach the match through the Kit as the paint does.
- **No version bump of `loadouts.save`:** the key is new and an old save simply lacks it (At Night).
- **0.0045 rad across its radius** (the browser's `minAngularRadius`, and how `gas_min_angle` reads here): a glowing
  BB is never under 0.009 rad wide, so it meets 0.0045 rad on either reading of "across".
- **The streak 0.0018 rad wide at 0.75 opacity:** the browser's `trailAngularWidth` and `trailOpacity`.
- **White BBs keep no streak and no least size,** as before (acceptance 2).
- **The glow takes the fog,** as white BBs do.
- **The firing slot rides on the BB** rather than being looked up from the owner's replica in hand when drawn: exact
  through a switch, and the simulation never reads it.
- **Acceptance 3 is tested on `MatchRunner`, drawing every tick:** two `PlaySession` runs of one seed already differ by
  centimetres (`test_mn2_qa.gd`), so an exact comparison there would be flaky.

## Measurements

`BBView.update` headless (dummy renderer), 2,000 frames each, two runs:

| BBs in flight | White, µs a frame | All glowing, µs a frame |
|---|---|---|
| 40 | 59.0, 47.4 | 94.8, 98.6 |
| 256 (the pool) | 194.7, 195.8 | 551.4, 496.5 |

Attempt 2: a match where nothing glows skips the per-BB glow test (`_any`, set by `set_glowing`), and `streak_of`
takes each length once. Three runs (another job loading the container): 256 white 104.9, 99.3, 99.6 µs (main 78 µs
on the performance review's run, attempt 1 186 µs there); 40 white 39.3, 39.4 µs; 256 glowing 511.5, 537.6, 538.2 µs.

Draws: one for white BBs as before, plus two (balls, streaks) only while a glowing BB flies.

On screen (Compatibility, Xvfb, High), a glowing ball's brightest pixel: (147, 201, 113) on Depot by day, (184, 214,
158) in Woodland at night, for a drawn (157, 255, 122): AgX tone mapping.

## A match plays the same

`test_glow_bbs.gd` plays Depot, seed 11, 60 s (3,600 ticks, 7 hits) three times, every character loading Off, Always
and At Night (drawn as on a night field), a `BBView` drawing every tick: the ticks, hits, rounds, who hit whom and how
far each got are the same; Off drew no glowing BB, Always and At Night drew them (5,045 glowing BB frames).

## Gate

`tools/check.sh` on the 4-core container: every gate passed, 3,149 tests of 3,149. Unit part 1 510.6 s (WL7: 517 s),
part 2 529.3 s (WL7: 506 s), both under the 600 s limit; `test_glow_bbs.gd` (part 1) takes about 15 s. A first run
failed one test: `test_play_session.gd` counts the materials ShaderPrewarm draws, now two more (the glowing ball and
its streak); its count is updated. That run's parts read 489.7 and 528.5 s.

Attempt 2 (on the WL7 merge, with QA's `test_glow_bbs_qa.gd`): every gate passed, 3,166 tests of 3,166. Part 1
516.8 s, part 2 574.2 s: part 2 is past 570 s with another job loading the container (load average 4.5 on 4 cores
during the benchmarks); attempt 1's 529 s was on a quieter container. Within the 600 s limit, but close.

## Verified

- `tests/unit/test_glow_bbs.gd`, 14 tests: the choice per replica and At Night by default; `glows` and `glow_bits`;
  saved through SaveFile and read back at version 1; an old save At Night without a word; a bad value or replica At
  Night and listed; the Kit's choices per slot and every bot's At Night; the colours, least size and streak time in
  the shipped `PlayTuning`, both greens more than 20° of hue off every team's; white, ball and streak draws (no third,
  no halo), white as before, unshaded green; the ball's least size from 1 to 80 m and a BB's size point-blank; the
  streak's 0.05 s, its place behind the BB, its width and facing, shorter while young, none end-on or standing; no
  node or object made while drawing and the glow hidden with none; Customise's row beside BB weight, per replica,
  saved on leaving; a match seeded the same with every choice; your BBs glowing by your kit and the bots' white by day.
- Pictures (Compatibility under Xvfb, 1920x1080, High), in `/mnt/project-files/screenshots/step26/`:
  `wl8-depot-day-always.png` (Depot by day with Always: your stream green with its streaks against the yard; a bot's
  BBs white, a few pixels), `wl8-woodland-night.png` (Woodland at night, At Night: your stream and a bot's, all green),
  `wl8-customise-glow.png` (Customise › BBs with Always picked under BB weight). BBs were placed by hand in flight with
  the simulation stopped, so the streams are tidy.

## Advisories left

- **The green is paled by AgX** on screen (Measurements, KNOWN_ISSUES): for the owner's playtest.
- **The seeded-match test can't prove no simulation code reads the choice:** it shows the drawing doesn't feed back.
  A grep finds no reader of `glow`, `glow_bbs` or `BB.slot` under `game/sim/`, `game/ai/` or `game/nav/`.
- **Streaks in one MultiMesh blend unsorted:** two crossing streaks may draw in either order; at 0.75 opacity and 1 to
  2 px wide it doesn't show.
- **The smoke run shows 10 more transient orphan nodes** while the menus build; the steady state is 0.

## For the owner to test

- PLAYTEST › Loadout and Customise: Glowing BBs; › Woodland: Glowing BBs and the frame time in a night firefight.
- Whether the green reads as glowing at night after tone mapping (KNOWN_ISSUES).
