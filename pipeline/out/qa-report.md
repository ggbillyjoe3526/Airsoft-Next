Task: none (RN1, PR #130) · QA commit none (no test added) · Verdict: Pass

Scope: `git diff c058ef4..1f45cf2` (18 files, links renamed Airsoft-Next -> airsoft).

Blocking findings: none.
Advisory findings: none.

Checks
- Leftover old name: grep for `Airsoft-Next` (any case, also airsoft_next/airsoftnext) outside legacy/, docs/archive, docs/records finds only CLAUDE.md:101 and docs/DECISIONS.md:23, both deliberate "renamed from ... to airsoft" history. No code, config, test, workflow, script or wiki page still holds it, and nothing compares against it.
- Old frozen repo name `ggbillyjoe3526/Airsoft` (no suffix): only mentioned in CLAUDE.md:100 and DECISIONS.md:24 as "no longer on GitHub"; no live link points to it.
- Every remaining github.com/ggbillyjoe3526/ link is `/airsoft`: report_config.gd:11, report_config.tres:7, tools/wiki.py:695, README.md:22, docs/wiki/{Development,Getting-Started,Roadmap,_Footer}.md, installer/Airsoft.iss:32-34. The wiki workflow builds its address from ${GITHUB_REPOSITORY}, so it follows the rename on its own.
- Installer: AppId line 23 unchanged (`git diff` shows no AppId hunk); the three URLs are consistent (base, /issues, /releases); AppPublisher "ggbillyjoe3526" is the account name, correctly untouched.
- Bug report link: both sources of the address are pinned by existing tests: the script default by test_issue_link.gd (ReportConfig.new(), BASE line 5) and the shipped .tres by test_report_panel.gd:186 (ReportConfig.load_default(), asserts the opened URL starts with the new address). Changing either one alone would fail a test, so no gap and no new test.
- `python3 tools/wiki.py check`: "Wiki OK: 24 pages", links and headings resolve.
- GUT: test_issue_link.gd + test_report_panel.gd: 2 scripts, 27 tests, 27 passing, 149 asserts, 1.3 s. Raw output in pipeline/out/qa/rn1-gut.txt.

Tests added or changed: none. They would only restate the URL.

Not run / not testable here
- tools/check.sh and the smoke test: running in the main session.
- Inno Setup compile of Airsoft.iss (no ISCC on this box; CI release builds it). Edit is three plain URL lines, low risk.
- That the browser really opens github.com/ggbillyjoe3526/airsoft/issues/new on the owner's PC (needs a real window and network); GitHub redirects the old name anyway.
- The "Unicode parsing error ... NUL" lines at GUT start appear at GUT start; unrelated to the URL edits (no test failed).
- Docs-only lines (HANDOFF "paused", ROADMAP reminder wording) read, not tested.

Verdict: Pass
