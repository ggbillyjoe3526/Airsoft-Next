# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.


## BR1 · The bot balance report
tier: core
perf: skip
touches: tools/balance.sh, tests/balance/, pipeline/out/
contract: none
acceptance:
  1. `tools/balance.sh [filter]` plays seeded headless matches with MG1's runner and writes
     `pipeline/out/balance-report.md`: each team's share of decided rounds and each end's (ends swap at half time),
     rounds on time and the first hit's time and range, per map (Depot; Neon Heights while dev); each figure with its
     count, standard error and band (Normal 45 to 55 %), judged inside, near an edge, outside within noise, or outside
     (`docs/DECISIONS.md` › Bots and balance).
  2. Measured, never asserted: the checks and CI don't run it. The first report goes in the record with what it says.
status: open
attempts: 0
