# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## WL10 · Woodland's match guards, balance and performance (Dev)
when: build order step 26, last
tier: core
perf: required
touches: tests/guards/test_match_guards.gd, tests/guards/test_flag_guards.gd, tests/balance/balance_run.gd,
  tests/support/match_runner.gd, tools/match_guards.sh, .github/workflows/ci.yml, docs/KNOWN_ISSUES.md,
  docs/PLAYTEST.md, docs/DECISIONS.md
contract: none
acceptance:
  1. The match guards play Woodland Elimination and Attack / Defend at 5v5 at night, on 16 seeds at Normal and the
     levels' seeds at Easy, Hard and Pro: rounds settle; nobody is stuck, falls or is hit by a teammate. Should the
     guards' CI job pass its time limit, Woodland gets a job of its own.
  2. The balance report covers Woodland's modes and levels. A figure outside its band (Normal 45 to 55 %, Pro 40 to
     60 %) goes to the owner beside the browser's figures (M88, FO1, its WL2), never into a looser band.
  3. The record gives Woodland's frame time, draw calls and triangles at 5v5 and 6v6 on every preset, against Low's
     60 FPS target; each gap is a KNOWN_ISSUES row.
  4. PLAYTEST › Woodland lists what to try (both camps, the fort, the ravine, bushes, the torch on and off, glowing
     BBs, 6v6). The owner makes Woodland public when he is happy.
status: open
attempts: 0
