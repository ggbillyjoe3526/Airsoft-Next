# Art references · The owner's target look and arm study

**Review:** 1 attempt · critic Accept 7/8 · qa Pass · performance Pass (the pictures and `docs/art/.gdignore` are
not Markdown, so the change is not docs-only)

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-18 | 1 | Opus 5.5 (thread) | ✓ | 7/8 Accept | – |

## Decisions

- **The pictures are owner-supplied references, not game assets.** They sit in `docs/art/references/`, outside
  `docs/ASSETS.md`'s register, never ship (`docs/*` is excluded from every export preset) and are the owner's own.
- **Committed as JPEG at quality 85, full size 1672 × 941** (about 1.4 MB for all six, against 12 MB as PNG); the
  arm and hand study at quality 88, 1312 × 1199 (0.4 MB), so its small labels stay legible. The original PNGs stay in
  the project's shared files under `art/references/`, outside the repository.
- **`docs/art/.gdignore` keeps Godot from importing them.** Without it the editor would import six textures nothing
  uses.
- **Container red joins the site colours** as an oxide red darker and duller than Beta orange, so it never reads as a
  team.
- **Zone letters are charcoal stencils that name a field's zones** and match the minimap and callouts. One picture
  paints them red; red sits too near Beta orange.
- **Puddles in every lighting preset, a fully wet slab only in rain.** Every picture but one is wet; a wet slab on
  every match costs reflections and hides BBs.
- **Grips map to replica handling by type:** power grip on pistol grips, support grip on handguards and foregrips,
  pinch grip on magazines, charging handles and the hop-up dial, precision grip on selectors and releases.
- **Realistic arms default to full detail in first person and on near figures,** with LODs carrying less, until the
  owner answers the realism-against-stylisation question in `docs/ART.md`.
- **No changelog note.** Players and the owner notice nothing in the game; the critic's check 8 asked for one, and
  `docs/PROCESS.md` › Pull requests and branches only asks for a note when a change is noticed.

## Known issues left

- None. The open questions are in `docs/ART.md` › Open questions for the owner.
