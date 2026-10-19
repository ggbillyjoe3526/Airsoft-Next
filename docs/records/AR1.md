# AR1 · The Armory screen and the XP at the end of a match

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Sonnet (worker) | pass (1026) | Accept 7/8 | – |

## Decisions

- **Split by what each part shows:** `ArmoryFacts` works out the rows, states and counts with no nodes (so the screen's
  numbers are unit-tested without a scene); `ArmorySummary` is the left column, `ArmoryTrack` the levels, `ArmoryPage`
  composes them and says the load problems. `XpCard` is the end-of-match card and `XpBar` the bar both share.
- **Built when the tab opens, freed when it is left,** as the Loadout page is, with the viewports it drew. `stale()` (level,
  XP or Disable levelling changed) rebuilds an open page from `MenuScreen.show_level`, so Settings › Dev's buttons show.
- **Pictures are the items' own models:** replicas through `ReplicaPictures.texture` in the paint they start in (a Cobalt
  rifle, a Ghost pistol, as the concept has them), parts through `part_texture` on the first replica whose part models
  have them, power sources from `assets/models/powerSources` (`PowerModels`, the browser game's `POWER_SOURCE_FILE`).
  Nothing drew the power models in Godot yet, so `ReplicaPictures.power_texture` is new: it gives each picture its own
  copy of the material it changes (the gas label's colour, metal held to 0.35), as the shared glb material would paint
  every bottle alike. Batteries are tipped 0.6 rad up their lead end to fill the picture, as the concept shows them.
- **Small pictures:** the Armory and the level-up card draw replicas at 384 px long (`ReplicaPictures.replica_side`), not
  the Loadout's 1024: they show at about 90 px.
- **Levelling off:** the left panel says ALL UNLOCKED and that your own level comes back, the bar is gone, every row reads
  unlocked; at the cap the bar is full and it says XP counts again when the cap goes up (the wording `docs/PLAYTEST.md`
  already had). Items waiting for their feature (the Weapon Torch) are never listed; dev items only with Dev content on.
- **Load messages stay up** for the page's whole life (the Loadout clears its own after one showing); the damaged file is
  already set aside, so the message is true until the next start.
- **The XP card stays up until the next match starts** (8 s, `PlayTuning.rematch_delay`), and the win banner with it (the
  banner's 2.5 s timer pauses while a card is up): the concept shows both together, and the card would otherwise outlive
  the banner it hangs under. A match that isn't counted shows neither card nor change.
- **Lines are the MatchXp lines:** "Rounds won · 5 × 20" when the XP shares evenly over the count, else just the count (a
  levels.md that gives a round 7 XP never shows a wrong sum); the difficulty row reads "Normal bots × 1" from the
  settled match's multiplier. A level-up names every item the jump unlocked and shows up to three pictures.
- **"About 250 XP"** in the earning note is levels.md's own pace sentence, fixed in the translation text (a computed figure
  would need an invented typical match).
- **Smoke test** opens and closes the Armory (frames 83 and 87) after the Loadout.
- **Outside the block's touches:** none that the criteria don't need besides `docs/` (`KNOWN_ISSUES.md`, `ARCHITECTURE.md`,
  the progress and play READMEs); `game/ui/text/en.po` is under `game/ui/`.
- **Left:** `PART_BLURB_HICAP` reads "bots close by hear you walk." (it is the rattles note's second half, so the Armory
  capitalises a blurb's first letter); the Hi-Cap Magazine's own line is missing from en.po (LO3's).
- **QA's one bug, fixed:** turning Dev content on with the Armory open didn't refresh it; the page's staleness now
  includes Dev content (`ArmoryPage._now`, pinned by `test_ar1_qa.gd`).
- **The match score on the win banner** ("5 – 3 ·" in concept `over.png`) waits for step 14 (match info: WON, LOST or
  DRAW and the scoreboard), which reworks that banner.
