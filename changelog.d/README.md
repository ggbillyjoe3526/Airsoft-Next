# Changelog notes for the next release

Every pull request with a change players or the owner will notice adds **one
new file here** instead of editing `CHANGELOG.md`. Several pull requests can
then be open at once without their changelog lines colliding.

- **Name:** what the change is about, in lowercase words joined by dashes,
  ending in `.md` (`hop-up-dial.md`, `settings-menu.md`). Pick a name no
  other open pull request is likely to use.
- **Inside:** a `### Title` line in plain player words, then `- ` bullets,
  written for players and the owner like the rest of `CHANGELOG.md`. More
  `###` blocks are fine; never `#` or `##` headings.
- **Later changes** to the same feature edit that pull request's file, or add
  bullets to an existing note once it has merged.

```markdown
### Hit calling
- A hit player raises a hand, calls "HIT!" and walks off to the dead zone.
```

CI checks the notes (`tools/changelog.sh check`) and prints how the next
release notes will read.

**At release time** (after the owner tags), the release checklist's pull request runs `tools/changelog.sh release`.
That writes these notes into `CHANGELOG.md` under `## 0.1 Dev 2 (date)`, newest first, and deletes the files here.
`docs/PROCESS.md` › Releases has the full steps.
