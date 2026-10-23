# SV5 · Report a Bug from the title and the pause menu

**Review:** critic Accept 8/8 · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-23 | 1 | Opus | pass | | |
| 2026-10-23 | 2 | Opus | pass | QA attempt 1: Pass (advisories fixed); performance Pass | QA's focus escape and three advisories |
| 2026-10-23 | 3 | Opus | pass | QA re-check Pass; critic Accept 8/8 (Opus) | the critic's and QA's last advisories; rebased onto SV4's final head |

## Decisions

- **The plan's defaults, approved with the step 22 pictures, 2026-10-23** (`plan/step22-save-and-crash.md` › 5;
  question 1: a new issue on the public GitHub through the player's browser, nothing sent until Submit, and Copy
  report for anywhere else; question 3: the match carries on after a script error and the pause menu says so).
- **The facts are gathered once, as the panel opens** (ReportFacts.live), and only the text is written again as the
  note changes: the match is paused under it, and the title has no match, so nothing else moves.
- **The note is cut to 500 in script** (TextEdit has no length of its own), a paste included; the count is the box's
  length. Report copies the whole report (BugReport's text, the note's line in it) before it opens the address, cut
  or not, as the acceptance asks.
- **Four lines after a press:** opened ("Opened GitHub in your browser. The whole report is copied too."), opened but
  cut ("… Part of the report didn't fit the link: paste the copied report into the issue."), not opened (the opener
  answered an error: "Your browser didn't open. The whole report is copied: paste it into a new issue on the game's
  GitHub page.", in the bad colour, no tick) and Copy report's ("The whole report is copied.").
- **Screen words:** "title" from the title; "in play" or "practice" from the pause menu (ReportFacts.PLACES, as the
  picture's "Screen: in play").
- **The pause menu gets its facts through PlaySession:** `PlaySession.error_log` (main hands its ErrorLog over at Play)
  and `PlaySession.report_info()`, handed to the menu as `PauseMenu.errors` and `PauseMenu.report_info`, as
  `end_round` is. The error line is read each time the menu opens; warnings don't count (ErrorLog.errors_this_run).
- **The match pause panel is 560 px wide** (was 520), as `pause-report.png`; practice was already 560. In practice
  the foot is Report a Bug alone, so practice's own bottom gap went: both forms end on the foot.
- **Esc closes the panel only** (`_input` on ui_cancel, as the settings), and keys it leaves stop at the panel, so
  practice's Loadout key can't reach the menu under it; Back and Esc give the focus back to the button or link that
  opened it. The panel is built when asked for and freed once closed, from the title and from the pause menu.
- **The smoke test** opens the panel from the title's link on frame 3 and closes it with Back on frame 6, failing if
  no report showed; it never presses Report.
- **Same text for practice's error line** ("in this match"), as the acceptance words it.

- **QA attempt 1: Pass (advisories fixed); performance Pass.** Keyboard focus could leave the panel over the pause
  menu (Tab, Shift+Tab and the arrows reached REPORT A BUG, Resume and Settings under the shade): the panel now rings
  its five parts (note, Report on GitHub, Copy report, Back, the report) for Tab and Shift+Tab (the note's own Tab
  only from attempt 3, which stopped it typing a tab) and points every arrow at one of them; QA's proof test is
  folded into `test_report_panel.gd`. `PauseMenu.open_report` does nothing while a report is open. Typing or pasting into a full note loses only what went past 500, just before the caret, and the
  caret stays (it dropped the last character and jumped to the end); the report box keeps its scroll as the note
  changes. The error line counts errors since the match (or practice) started: the menu notes
  `errors_this_run()` when PlaySession hands it the ErrorLog and shows the difference (the report still lists the
  run's). The pause fallback's report names its place ("in play" or "practice"), not "".
- **Last advisories (attempt 3), after the critic's Accept 8/8:** the note box sets `tab_input_mode` off, so Tab moves
  round the panel instead of typing a tab (a test pushes a real Tab key); a rematch in the same PlaySession hands the
  ErrorLog to the pause menu again, so its line counts that match's errors from zero (tested); the error dot reuses
  `GraphicsNotice.WARN`; PLAYTEST's Log a test error checks say "after SV6". Rebased onto SV4's final head (66893a9):
  KNOWN_ISSUES kept both sides; the panel's calls to BugReport, IssueLink and ReportScrub hold as they were, and
  one test passes SV4's new `ReportScrub.new(..., config)` in place of the old minimum length.

## Checks

`tools/check.sh`: gdlint, changelog notes, unit tests (2471 of 2471, no script error), smoke test and licence notices
all pass.
Attempt 2 (QA's fixes): all five gates pass, unit tests 2476 of 2476, no script error.
Attempt 3 (rebased on SV4's final head): all five gates pass, unit tests 2524 of 2524, no script error.

## Screenshots

`pipeline/out/sv5-report-title.png` (the panel over the title after Report), `sv5-pause-foot.png` (the pause foot with
the error line), `sv5-report-pause.png` (the panel over a paused Depot match), `sv5-title.png`; Compatibility renderer
under Xvfb at 1920x1080. They match `report-bug.png` and `pause-report.png`; the report's lines sit a little further
apart than the picture's.

## Owner's checks

- PLAYTEST › Bug reports: the issue opens filled in on Windows, a long report cut and pasted, no folder path or
  account name anywhere.

## Known issues left

- Report a Bug is checked in Xvfb screenshots at 1080p and headless only (a KNOWN_ISSUES row, playtest).

## Advisories left

- The pause menu's fallback (no `report_info` handed over) repeats what `PlaySession.report_info` does with no match;
  only tests use it.
- Acceptance 2's "errors" is read as errors since the match started (the line says "in this match"); the report
  itself lists the run's.

## Outside `touches`

`game/play/play_session.gd` (`error_log`, `report_info()` and two lines handing them to the pause menu),
`game/report/README.md` (the panel's line), `docs/TASKS.md` (the block out), `tests/unit/test_title_and_menus.gd` and `tests/unit/test_settings_screen.gd` (the title's foot and the pause menu's
buttons gained Report a Bug), `docs/KNOWN_ISSUES.md` (a row), `docs/records/SV5.md`.
