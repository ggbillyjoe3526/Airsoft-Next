Task: RN1 · Links use the renamed repository (PR #130, no task block; judged against the brief)
Attempt: 1 of 4
Head: f581e35 (CI green on 1f45cf2; 1f45cf2..f581e35 is only changelog.d/repo-rename-links.md and pipeline/out/ reports, changelog check OK on f581e35; merge still waits for CI green on f581e35)
Checks: 1 ✓ | 2 ✓ | 3 ✓ | 4 ✓ | 5 ✓ | 6 ✓ | 7 ✓ | 8 ✓
Score: 8/8 → Accept
Evidence:
1. Every live link moves to /airsoft: report_config.gd:11, report_config.tres:7, Airsoft.iss:32-34, tools/wiki.py:695,
   README.md:10,22, docs/wiki/{Development,Getting-Started,Roadmap,_Footer,README}.md, PLAYTEST.md:15. A case-insensitive
   grep for Airsoft-Next outside legacy/, archive, records and pipeline/out finds only the history lines CLAUDE.md:101
   and DECISIONS.md:23. CLAUDE.md:100, DECISIONS.md:24, PROCESS.md:18, ROADMAP.md:12, HANDOFF.md:9 no longer send anyone
   to the old repository. HANDOFF.md:36-37 records OV3 #128, PN1 #129 and the 2026-10-29 pause; ROADMAP.md:127-128 drops
   the Blender reminder, matching the owner's 2026-10-26 deferral (ROADMAP.md:121, HANDOFF.md:38).
2. No contract touched: one exported default string and its .tres value; no signature, signal or file format change.
3. No runtime path changed: issue_url is read once when the report panel opens (performance report agrees).
4. No new tests, rightly: test_issue_link.gd:5 (ReportConfig.new(), the script default) and test_report_panel.gd:186
   (ReportConfig.load_default() at :18, the shipped .tres) each fail if their source of the URL is left on the old name.
5. Static types kept (`@export var issue_url: String`); no logic moved.
6. Fits the fixed decisions: installer AppId (Airsoft.iss:23) untouched; no tag, no workflow, no version pin changed.
7. One-line edits; .tres keeps its ext_resource id 1_rpcfg and layout.
8. In scope for a cleanup PR; changelog note added, CHANGELOG.md untouched, wiki pages updated with the links.
Failed checks: none.
Must-fix: none. Advisory (optional, next docs touch): HANDOFF.md:34's lead "Step 27 is under way (owner resumed it
   2026-10-26)" now contradicts the paused line at :37; lead with the pause so a skimming session doesn't start PN2.
Owner should test in the game (at most 6, one line each):
- Pause menu › report a bug › Report: the browser opens github.com/ggbillyjoe3526/airsoft/issues/new prefilled.
- After the next tagged installer: Windows Settings › Apps › Airsoft shows the support and updates links on /airsoft.
- The wiki footer's Download link and the README's Releases link open this repository's Releases page.
