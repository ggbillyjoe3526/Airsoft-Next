# SV4 · The bug report and its GitHub issue address

**Review:** critic pending · qa pending · performance pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | QA Fail; performance Pass | |
| 2026-10-23 | 2 | Opus | pass | | QA attempt 1 Fail: an IPv4 address ending a sentence and compressed IPv6 reached a report |

## Decisions

- **The plan's defaults, approved with the step 22 pictures, 2026-10-23** (`plan/step22-save-and-crash.md` › 5;
  question 8: what a report holds, with folder paths and the account name taken out; the player sees all of it).
- **ReportInfo** is `BugReport.ReportInfo`, an inner class, so the report needs no file outside `touches`: plain
  strings a field ("" reads "-"), the lists oldest first, and the `ReportScrub` every written line goes through. A cut
  is `BugReport.Cut` (each list's newest `keep`, fields `drop` left out: "Settings changed: (left out to fit)"). An
  empty list reads "none"; a list cut to nothing "Recent events: 30 (left out to fit)".
- **The pictures' layout, with three small differences:** a repeated error ends " ×3", as `ErrorLog` (SV3) already
  words it, not "SCRIPT ERROR ×3 …"; negative numbers use "-", not the typographic minus, so a position copies into a
  flag; the Note line is left out with no note (as the pictures' builder does). A crash report has Closed for Time and
  no Player, Frames or Recent events, as crash-screen.png.
- **A crash report's Recent errors** come from the crashed run's log (`ReportFacts.errors_in_log`: Godot's "ERROR:",
  "SCRIPT ERROR:", "SHADER ERROR:" and "WARNING:" lines, their place the first script frame, else the "at:" line,
  worded as ErrorLog's), since this run's ErrorLog knows nothing of the last. The log is read once more for it, only
  when a crash report is made.
- **RecentEvents keeps** everyone's SHOT, CHARACTER_HIT (the hit is the call: one BB, out) and RICOCHET_TICK, the round's
  ROUND_START, ROUND_OVER and MATCH_OVER, and only the player's RELOAD_START, RELOAD_END, RELOAD_REFUSED, DRAW,
  DRY_FIRE, TARGET_HIT and SQUAD_ORDER (the browser kept only the player's reloads and draws too: six bots' would
  bury the rest). "Calls" are the hits and the player's squad orders. A burst looks back up to `look_back` (8) entries
  past other shots only, as the browser's. Entries name "You", "Beta 2" (team and character number) or "#7"; the
  replica by its slot in the shooter's loadout as the report is made.
- **FrameWindow** keeps frame times in a ring `frame_seconds × frame_rate_held` long (10 × 500 = 5,000 floats, 20 kB);
  faster than 500 fps it covers fewer seconds and its line says how many. Fed in PlaySession's `_process`, which a
  paused tree doesn't run, so a report from the pause menu sums up the play before it.
- **ReportScrub** also takes out any user folder's name (`C:\Users\<x>`, `/home/<x>`, `/Users/<x>`, so a profile folder
  named unlike USERNAME still goes), the machine's name (COMPUTERNAME, HOSTNAME or /etc/hostname: "<machine>") and
  IPv4, IPv6, MAC and e-mail addresses ("<address>"). The longer of the account and machine names goes first, so
  "zandra-laptop" goes whole. Names match case-free with Unicode letters (`(*UCP)(?i)`, checked: "JÖE" is "Jöe").
  Its patterns are raw strings (`r"…"`, Godot 4.3 and gdtoolkit 4.5.0 both read them).
- **IssueLink** scrubs the note before it titles the issue and heads the body; spaces go as "+" (GitHub's form, the
  browser's URLSearchParams); the fence is "```text" or longer. A limit below the bare address still answers (the
  report empty, `cut` true).
- **The match line** words ids for the developer: the map and mode ids capitalised ("Neon Heights", "Attack Defend"),
  "Standard rules" or "Custom rules" as the picture, ", teammates Easy" only when they differ. English throughout.
- **Settings changed** compares `Settings.to_dict()` with a new player's, walking nested ones ("hud.size",
  "volumes.Master"), enums by name, switches on or off, whole numbers without ".0"; Dev settings, bindings (counted),
  `first_start_seen` and `last_fullscreen` (the game's own notes) aside. Renderer gives the preset in force, or Custom.
- **Screen** is the caller's word (SV5 passes where the panel opened; a crash report words the record's place).

- **QA attempt 1 Fail, the fixes (attempt 2).** Blockers: IPv4 now refuses only a full stop followed by a digit, so
  "My IP is 192.168.1.5." goes; IPv6 matches every form (full, compressed, with an IPv4 tail: "::ffff:1.2.3.4" goes
  whole), holding a digit and not run into by a word, so clocks ("12:40:05", "00:01:02.5") and C++ names
  ("Face::bad", "Node3D::_ready") stay. QA's tests are folded into `test_report_scrub.gd`. Advisories: IssueLink and
  ReportFacts fail closed (no scrub given: `for_this_machine`); the note is scrubbed, then cut to 500, in the issue and
  in the report's Note line (`ReportInfo.note_chars`); "OneDrive - Contoso Ltd" reads "OneDrive - <organisation>"; a
  full machine name's first part goes too; e-mail addresses go before names, so no "<you>@domain"; list entries lose a
  trailing "\r"; a hitch is over 50 ms by more than 0.001 ms, so exactly 50 ms is none in single or double precision;
  a path neither starts inside a longer one ("/var/home/bob/x" reads "/var/home/<you>/x") nor eats a closing "]" or a
  sentence's full stop; a null in the run record reads "-"; the warm-tick test also feeds ticks of shots only whose
  replica changes each tick, so every shot takes a new entry. Performance's advisories: PlaySession clears both rings
  when a rematch starts (tested), and RecentEvents reads look_back and burst_ticks once. Left as KNOWN_ISSUES rows (can
  wait): a common-word account or machine name over-scrubs, and FrameWindow counts the shader warm-up frames.
- **Rebased** onto `origin/main` after SV1 (#83) and SV3 (#84) merged; ARCHITECTURE's `game/save/` row is main's.

## Performance (perf: required)

Cloud box, headless, no GPU:

- A warm tick: `RecentEvents.record` with a busy tick's 15 events (four shots, four steps, four impacts, a hit, a
  reload, a round start) costs 24.6 µs (25.6 µs at attempt 2; 10,000 timed); a frame's `FrameWindow.add` 0.2 µs (100,000 timed). Neither
  adds an object or a byte of static memory after warm-up (DebugPerf's counts, `OBJECT_COUNT` and `MEMORY_STATIC`,
  read before any assert; `assert_lte`).
- Summing a full window (1,000 frames) for a report: 0.15 ms.
- A whole report from a real match (ReportFacts, BugReport and IssueLink with 30 events, 20 errors, scrubbed): 3.7 ms
  (70 lines, a 3,117-character address), made only when the player asks (4.7 ms at attempt 2, after the rebase; the scrub's patterns are longer).

Performance attempt 1: Pass.

## Checks

`tools/check.sh`: gdlint, changelog notes, unit tests (2395 of 2395, no script error), smoke test (`[smoke] ok
frames=4499 … rounds=9 plates=5 orders=3`) and licence notices all pass.
Attempt 2 (rebased on main): all five gates pass, unit tests 2446 of 2446, no script error, `[smoke] ok frames=3048 …
rounds=6 plates=5 orders=3`.

## Owner's checks

- On Windows, Report a Bug (SV5) with a long report: the browser opens GitHub's new issue filled in (8,000 characters
  through `OS.shell_open`); a KNOWN_ISSUES row until then.
- A report from a Windows export names no folder path, account or machine name anywhere.

## Known issues left

- The address length through ShellExecute is untested (a KNOWN_ISSUES row, playtest).
- ReportScrub's address shapes can take a four-part version number for an address, and a spaced user folder name runs
  to the next slash (a KNOWN_ISSUES row, can wait).
- A common-word account or machine name over-scrubs; FrameWindow counts the shader warm-up frames (KNOWN_ISSUES rows,
  can wait).

## Outside `touches`

`docs/KNOWN_ISSUES.md` (four rows), `docs/ARCHITECTURE.md` (the `game/report/` row), `game/config/README.md` (a row),
`docs/TASKS.md` (the block out), `docs/records/SV4.md`, `tests/unit/test_report_facts.gd` (ReportFacts' tests).
