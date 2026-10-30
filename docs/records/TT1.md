# TT1 · Tooltips wrap and stay on screen

**Review:** 1 attempt · critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-30 | 1 | Opus 5.5 (thread) | ✓ | 7/8 Accept | – (its docs must-fixes, the archive move and one version ruling, are in the same push) |

## Decisions

- **Every tooltip wraps at 640 px (1080p units), `GameTheme.TOOLTIP_WIDTH`.** About sixty characters of body text;
  Godot's own tooltip label is caught on `SceneTree.node_added` (`TooltipWrap`), the only place it can be reached,
  and sized before the popup is placed, so Godot's edge clamp keeps all of it on screen.
- **`config/version` reads "0.1 Dev 2"** (owner, 2026-10-30): `docs/DECISIONS.md` › Versions, releases and branches.
- **The 0.1 Dev 1 release checklist ran here:** changelog folded, README, ROADMAP, HANDOFF and PLAYTEST moved to the
  new tag; the superseded 2026-10-22 Blender ruling went to `docs/archive/0.1-dev/DECISIONS.md`. `docs/PLAYTEST.md`
  (78 KB) has no finished parts to move.

## Known issues left

- None.
