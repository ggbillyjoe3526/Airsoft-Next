# AT2 · Parts on the Customise screen

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Sonnet (worker) | pass (872, on AT1 as merged) | Accept 7/8 | QA advisory: part pictures held after leaving a part tab (fixed by the build thread) |

## Decisions

- **Tabs** run COLOUR, BBs, POWER, OPTIC, GRIP, BARREL, MUZZLE, MAGAZINE, LASER, LIGHT (the concept's order). A slot with
  no part that fits the replica is greyed with the mounts its parts need, read from pool.md's Fits (the pistol's OPTIC says
  TOP RAIL, the rifle's LASER PISTOL RAIL), never hard-coded per replica. If the tab shown is greyed for the next replica
  the page falls back to COLOUR.
- **Card numbers** are the replica as carried with that part in that slot and everything else as it is
  (`LoadoutRules.carried` on a copy of the loadout), each against the same slot as it comes (the first card), so a card
  says what the part itself changes. Figures per slot: optic zoom and aim in; grip aim in and shake; laser spread; magazine
  BBs by changes and reload; barrel energy and spread; muzzle energy and heard from. A part that changes handling, a
  magazine's draw, or a barrel's or muzzle's aim in adds that figure when it differs. Energy and spread keep two decimals;
  the rest drop trailing zeros (the concept's "2×", "1.8 s").
- **The words line** under the cards is built from the figures that are better and worse ("Better: more zoom. Worse:
  slower aim in."), one wording for every tab; the two concepts word it differently ("Better than it comes: Zoom aimed."
  and "Better: fewer changes."). The slot as it comes says nothing. A rattling magazine adds "rattles while you move".
- **Short names:** a magazine's own word is dropped on the cards and the tab list ("Hi-Cap"); other parts keep their pool
  name. The slot as it comes is "None" for the optic, grip and laser, "Standard" for the rest, with the picture words
  ("Iron sights", "Flash hider" on the AEG, from `PART_*_<REPLICA KEY>` keys with the slot's as the fallback).
- **Sheet rows:** Zoom aimed and Aim in are tab-only (OPTIC; Aim in also on GRIP, BARREL, MUZZLE), as the concepts show them
  on the optic tab and not on the magazine tab; Moving (Rattles, red) appears on every page with a rattling magazine.
  Zoom's bar is full at 3.5x, Aim in's at 0.4 s (inverted like Reload). A part tab leaves the sheet's own better and worse
  lines off (the cards say it). The sheet's line lists the parts carried from two parts on, else says what parts do.
- **Pictures:** each part is drawn alone from `replicaParts/<key>.glb` (node `<slot>_<key>`, figure copies dropped) at one
  scale per tab (at most 1000 px a metre, inside 220 x 84 px), kept only for the tab on show. The replica picture adds the
  fitted part nodes to its model, hides its Magazine node(s) and FlashHider where a part replaces them, and frees what it
  replaces. On the gear page every replica shares one scale again once the parts are on, so a long rifle shrinks a little
  rather than overflow its card; Customise keeps the rifle's bare scale up to a room limit.
- **No add-ons**, no changes outside `game/ui/`, `tests/unit/` and the docs.
- Part pictures (a viewport each) are let go when a non-part tab or the gear page shows (QA attempt 1).
- Critic (7/8, judgment): `customise_view.gd` is 748 lines; split its tab list and tab state out (as `part_page.gd`
  was) when it next grows. Can wait.
