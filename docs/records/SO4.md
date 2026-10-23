# SO4 · The order wheel and hold marker on screen

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus (QA Fail fixed by the worker: no notice after a pick, wheel under the pause menu) | pass | 7/8 retry | the notice after a pick covered the crosshair with the whole wheel |
| 2026-10-23 | 2 | Opus (the build thread) | pass | 8/8 accept | |

## Decisions

- **Approved defaults** (concepts `/mnt/project-files/concepts/step17-orders/`, owner 2026-10-22): hold Z for the
  wheel, four slices (Follow Me, Hold Here, Regroup, Team Plan) each with its key, the slice pointed at lit yellow,
  the order in force banded in the team colour with an ACTIVE tag; Hover or Click picking in Settings › Controls ›
  Squad orders; Hold Here's marker "HOLD · 18 M" over the held spots' middle with a dashed floor ring.
- **No order text outside the wheel** (G4). A notice shows in the wheel's hub while it is open. An order picked on the
  wheel shuts it, so the wheel waits `HudConfig.order_notice_wait` (0.5 s) for that order's answer and, if it carries
  a notice, shows it for `order_notice_time` (2 s) in the hub alone: no dark, no slices, the hub see-through, so the
  crosshair stays readable while you have control (critic). A wheel shut on nothing waits for no notice, so a key
  pressed just after never brings it back. A notice given by a key with the wheel shut shows nothing.
- **Pausing** puts the wheel away (`Hud.close_order_wheel()` in `_open_pause`, and the wheel hides itself whenever the
  tree is paused while it is up).
- **Edge stack:** pinned past the screen's edge, the hold marker sits below the flag marker on the same side.
- **Outside touches:** `KeyBindings.ACTIONS` lists the squad keys Follow, Hold, Regroup, Wheel;
  `key_binding_list.gd` rows are 344 px wide for the longer names; the KNOWN_ISSUES row for the missing wheel is gone.

## Known issues left

- The hold marker stays over the match results (no round start comes after the last round): KNOWN_ISSUES row.
- Releasing Z on a slice while a notice shows in the open wheel still gives that order (QA advisory 4).
- The marker's text is rebuilt only when the metre count changes; the floor ring redraws every frame it shows
  (performance advisory).
- The post-pick wait is armed from the HUD's last open frame: a release in Click mode over a slice with no click arms
  the 0.5 s wait with nothing given (harmless now the notice is a see-through hub). The exact fix is PlayerInput
  reporting that a close gave an order (critic advisory).
- Owner tests in the game: pick Team Plan with an order in force and peek at once (crosshair clear, hub readable);
  Hover and Click reach and dead zone at your sensitivity; the ring at 15-25 m; hold and flag markers at the right
  edge while turning in Attack/Defend; whether "Orders wait for the next round" and "Squad already on the team plan"
  fit the hub; keep the marker over the match results or hide it.
