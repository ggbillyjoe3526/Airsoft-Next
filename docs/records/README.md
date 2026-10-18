# Task records

One file per task, `docs/records/<id>.md`: how its review went, a row per attempt, the small decisions it made and
the known issues it left. Each task writes only its own file, so parallel branches never conflict on shared tables.
The thread writes it in the pipeline's records step (`.claude/skills/pipeline/SKILL.md`), in the same push as the
work.

The browser game's records, with the reasons behind every tuned value, are in `legacy/browser/docs/records/`.

## What goes where

| What | Where |
|---|---|
| The task's review, its attempts, its own tuning values and defaults | Its record (this folder) |
| An owner ruling, or a rule every later task must follow | `docs/DECISIONS.md`, and a line in the record's Decisions that points to it |
| A bug, limit or gap still open after the task | A row in `docs/KNOWN_ISSUES.md`, and a line in the record's Known issues left |
| What the player notices | `changelog.d/<short-name>.md` and `docs/FEATURES.md` (the changelog agent) |

## The format

```markdown
# M80 · Bots stop at the flag

**Review:** 2 attempts · critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-08 | 1 | Opus 5.5 (build thread) | ✓ | 6/8 Retry | AC2 bots overran the flag |
| 2026-10-08 | 2 | Opus 5.5 (build thread) | ✓ | 8/8 Accept | – |

## Decisions

- **Bots wait 2 s at the flag.** Long enough to read the capture, short enough to keep the round moving.

## Known issues left

- None.
```
