Task: none (RN1, PR #130) · head 1f45cf2 · Verdict: Pass
Run: none (no --perf run: no runtime logic changed) · budget: no baseline yet, judged against targets and origin/main (c058ef4) by diff reading
Metrics: not measured; nothing in the diff can move frame time, node count, orphans or static memory
Regressions (> 10 % worse): none
Blocking findings: none
Advisory: none
 - game/config/report_config.gd:issue_url and report_config.tres:issue_url are the only runtime-visible lines in game/: one string literal
   changed (same length class), read once when the report panel opens. No allocation, node, resource, signal, material or preset change.
 - installer/Airsoft.iss, tools/wiki.py, tests/unit/*.gd (2 string asserts), README and docs: not shipped in the game's frame loop.
Unexplained: none
