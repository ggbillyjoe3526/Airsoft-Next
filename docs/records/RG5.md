# RG5 · The Loadout from practice

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus (QA's mid-vault crouch fixed by the build thread) | pass | 7/8 retry | the spot read the stance from the body with a magic 0.5 |
| 2026-10-23 | 2 | Opus (the build thread) | pass | 8/8 accept | |

## Decisions

- **L is a rebindable action** (`loadout`, last in `KeyBindings.ACTIONS`, "LOADOUT (PRACTICE)" in Settings ›
  Controls). It is read only in practice (PlaySession, the practice pause menu, MenuScreen opened from practice); in a
  match nothing listens.
- **No world behind a menu:** the Loadout from practice frees the range and shows the menus, as a match does; the way
  back rebuilds the range from a `PracticeSpot` (place, view, crouch, slot, holster, challenge switch, seed), kept in
  main.gd while the Loadout is open. The same seed keeps the breeze and pop-up draw. A run under way is dropped (the
  challenge comes back READY with its switch as it was).
- **Stance is the one you chose** (critic): `PlayerInput.crouch_chosen()` (the toggle's crouch, or the crouch key
  held), which also feeds the command; a vault's tuck or a body still rising is no crouch. A held crouch can't be kept
  (the key is up in the menu).
- **The practice top bar** shows only LOADOUT, BACK TO PRACTICE with its key, and the level chip; the other tabs are
  hidden. Esc goes back to practice after backing out of a rename, replace or Customise. The FROM THE RANGE note is part
  of the gear page's replicas column.
- **The readout's first panel** gains "L Loadout · swap or tune your replica" (the concept's readout-first.png); its key
  follows rebinding. `MenuParts.key_chip` is the one key cap for the pause row, the top bar and the readout.
- **Shared pause padding** 16 → 17: the practice rows match the concept's 62 px; the match pause rows grow 2 px (1 px
  over their concept, accepted by the critic).
- **Criterion 3** needed no new rule: the page uses the same SavedLoadouts and Disable-levelling rules as the Loadout tab.

## Known issues left

- play_session.gd is about 1000 lines; move the Loadout request and resume next to PracticeSpot at the next touch.
- `PracticeSpot.restore` writes Character fields from game/play; a `Character.place_at` beside `respawn()` would keep
  placing inside the sim.
- Opening the Loadout from practice refreshes the page twice (about 100 ms on L, with no loading cover).
- Esc in a rename takes two presses (as on the Loadout tab); a digit bound to the Loadout key is taken by the page's
  slot keys in the menus; L in Customise goes straight back to practice (saving first).
- The rebuilt range's map comes from the Match page's pick, not the spot (fine while the Range is the only practice map).
- Owner tests in the game: L on the range opens the Loadout on the replica in hand; back puts you where you stood,
  looking the same way, mouse captured; crouch toggle on: crouch, L, back crouched, and L mid-rise comes back standing;
  holster and swap; a timed run dropped on L; L does nothing in a match; rebind Loadout and read the pause row, readout
  line and BACK TO PRACTICE.
