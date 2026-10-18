# Salvage · Godot bootstrap

**Review:** 2 attempts · critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-18 | 1 | Opus 5.5 (salvage thread) | ✓ | 6/8 Retry | untyped lines; unit tests didn't re-import; zip vs tarball; macOS template. QA failed on 4 bugs |
| 2026-10-18 | 2 | Opus 5.5 (salvage thread) | ✓ | 8/8 Accept | – |

## Decisions

- **Stack and versions as the owner's "go with defaults" (2026-10-18):** `docs/DECISIONS.md` › Engine and stack.
- **The owner's tag drives the release.** `release.yml` runs on a pushed tag such as `0.1-dev.1`, turns it into the
  name with `tools/version.sh` and writes it into `project.godot` before exporting; a manual run or a pipeline pull
  request is a dry run that publishes nothing. katanashotgun's opposite flow (bump the file, the workflow tags) would
  have had sessions create tags.
- **The Review line has its own workflow** (`review.yml`, `tools/review_line.sh`), so editing a description re-runs
  only that check, not Godot.
- **Windows and Linux only.** macOS is later (owner, 2026-10-18), so its export preset and release step are left out.
- **New installer `AppId`**, not katanashotgun's: the two games must install side by side.
- **katanashotgun's systems that aren't needed yet** (settings, the settings menu, the profile, sound cues and voice
  pools, quality presets, shader warm-up, the offline sound renderer) are copied to `legacy/katanashotgun/` to port
  when each system is built, so that repository can leave the project.

## Known issues left

- `pipeline/perf-budget.json` doesn't exist yet: the performance agent judges against targets and `origin/main` until
  the owner records a measured Godot baseline.
