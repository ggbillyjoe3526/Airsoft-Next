# WK1 · The game's GitHub wiki

**Review:** critic Accept 7/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | Opus 5.5 (wiki thread) | 3,166 of 3,166, wiki ✓ | Accept 7/8 | – (check 7: typed rule numbers; fixed after with `wiki:config` markers) |

## Goal

William (2026-10-25): a GitHub wiki on this repository showing everything important about the game (content,
roadmap, patches, replica stats, maps, modes), kept up to date as the game is developed, like katanashotgun's wiki.

## Approach

- katanashotgun's pattern: pages in `docs/wiki/`, `.github/workflows/wiki.yml` pushing them to the `.wiki.git` repo on
  every push to `main` with `GITHUB_TOKEN`, Patch Notes generated from `changelog.d/` and `CHANGELOG.md`.
- Further than katanashotgun: `tools/wiki.py` replaces marker lines with tables read from the game's own files
  (`data/*.md`, the map JSON, the key bindings, `en.po`, the tuning scripts), so stats, unlocks, XP, maps, keys,
  graphics presets, bot kits and match rules follow the data with no page edit, and `wiki:config` puts a tuning number
  in a sentence.
- `check` builds into a temp folder and fails on an unreadable source, an unknown marker, a broken link, anchor or
  picture, a page missing from the sidebar, dev content outside Roadmap / Development / In development, robots
  anywhere, or a public item or map named nowhere. CI's lint job and `tools/check.sh` run it.
- PROCESS, CLAUDE.md, DECISIONS, `pipeline/README.md`, the pipeline skill and `critic.md` count the wiki page as part of
  done for a player-visible change.

## Decisions

- **Python, as katanashotgun's `tools/wiki.py`.** It runs in CI's lint job, which already sets up Python; no Godot
  needed to build the wiki.
- **Publish on every push to `main`, no path filter.** Any data, tuning or note change can change a page; a build
  with nothing new pushes nothing (~1.5 s).
- **Patch Notes for players:** `### Internal` blocks are left out, robot bullets dropped, and bullets naming dev
  content move under "In development" (dev terms: dev-tagged maps and pool items, plus "dev content", "night",
  "Glowing BBs", since no public map is played at night yet).
- **Dev content is named only on Roadmap and Development, or under an "In development" heading;** robots never
  (the robots ruling, 2026-10-24).
- **Pages describe what is on `main`,** as katanashotgun's do; the footer and Home say so.
- **Pictures:** three greybox Depot captures from step 25 (no figures, so nothing hidden shows), about 40 KB each.

## Known issues left

- Some prose numbers and keys are typed, not generated (`docs/KNOWN_ISSUES.md`, Wiki row).
