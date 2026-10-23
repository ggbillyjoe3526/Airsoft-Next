# RG4 · Practice on the Match screen, its HUD and pause menu

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus (QA's lost-mode fix and performance's banner fix by the build thread) | pass | 8/8 accept | |

## Decisions

- **Approved pictures** (`/mnt/project-files/concepts/step16-range/`, owner "Approve all" 2026-10-22): the Range is a
  map card on the Match page with a Practice mode card (RANGE ONLY on a field, FIELDS ONLY on the Range); team, bots and
  rules read NOT USED while Practice is picked and keep their picks; the play button reads START PRACTICE.
- **The field's mode comes back** after the Range (QA): the page remembers the last mode picked on a field and gives
  it back when a field that hosts it is picked. The memory lives in the page, so a mode picked before START PRACTICE
  falls back to the field's first mode after Leave (the picks persist, the memory does not).
- **Readout:** the last BB's target and distance, where it landed, or that it flew out; no hit marker (targets show
  hits by moving and ringing). Hidden while the timed challenge runs.
- **Timed challenge:** the pause menu's switch is saved only when the session counts; the HUD shows ready, 3-2-1, GO!,
  a bar with time and hits, then TIME! with the run's figures and NEW BEST or NOT KEPT (DEV SETTINGS). The banner does
  no string work on a frame it is unchanged (performance).
- **Outside touches** (all for criterion 1's NOT USED and banner look): match_bots_box, match_rules_box, menu_parts,
  menu_tag, hud_banner, data/maps.md.

## Known issues left

- The challenge HUD (about 70 nodes) is built in every practice session, also with the challenge off; build it on the
  first switch-on if node counts matter (performance advisory).
- Match page `_refresh` measures four mode cards' wrapped heights per call (about 3 ms a pick).
- The HUD shows behind the pause scrim in practice, as in a match.
- `MenuParts._lock` resets every Team/Bots/Rules button's mouse filter and focus mode on each refresh (harmless today).
- RG5 adds the pause menu's Loadout row and the readout's Loadout line.
- Owner tests in the game: Range, Depot, Attack/Defend and back on the Match page; START PRACTICE by keyboard and
  mouse; the readout on steel at 30 m, a floor miss and a high shot with hop-up up; 3-2-1, GO!, the bar and TIME! at a
  glance; NEW BEST, a weaker run, a Dev-helped NOT KEPT; the switch off mid-run, quit and relaunch; Leave practice
  lands on the Match page with the mouse free.
