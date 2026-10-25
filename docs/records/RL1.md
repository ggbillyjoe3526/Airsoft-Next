# RL1 · The release plays the Windows build it ships

**Review:** pending

William asked (2026-10-25) whether a release tag makes a Windows installer for players. It already did: the Release
workflow exports Windows and Linux on the tag, builds `Airsoft-<tag>-Windows-Setup.exe` with Inno Setup, installs and
uninstalls it on a Windows runner and publishes it with a portable Windows zip and a Linux zip. Every pull request
touching the pipeline dry-runs all of it; the last one before this task (WL7, run 40181605867) passed, installer about
39 MB. Only the publish step has never run, as no tag exists yet. The gap: CI played the Linux build but never started
the Windows one, so a Windows-only start failure would have shipped.

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-25 | 1 | Opus 5.5 (thread) | Release dry run on the PR | – | – |

## What was built

- **The installed game is played on Windows** (`.github/workflows/release.yml`, job "Windows installer"): the old
  install-and-uninstall step is split in three. After the silent install, the installed `Airsoft.exe` runs
  `--headless --log-file <runner temp> -- --smoke`, the same headless match and range run the Linux build plays, with
  a 5 minute limit. It fails on a non-zero exit code, any `SCRIPT ERROR` or `Parse Error` in the log, a missing
  `[smoke] ok` line, or a `[boot]` line that doesn't name the version being released. Then the uninstall check runs as
  before. The log goes through `--log-file` (a release-template option in Godot 4.7.2) because the exported exe is a
  GUI program whose console output isn't reliable to capture.
- **Docs:** `docs/PROCESS.md` › Releases says what a tag runs and how to dry-run it; `docs/KNOWN_ISSUES.md` gains a
  Release row (unsigned installer and exe, so SmartScreen warns on first run; the exe keeps Godot's icon).

## Defaults taken

- No code signing: it needs a certificate the owner buys, so it is a KNOWN_ISSUES row, not built.
- No changelog note: players never see a CI check (CI1 did the same).
