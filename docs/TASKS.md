# Tasks

Open tasks only, one block each (format in `pipeline/README.md`). The planning thread writes blocks; a build thread
takes one, and its block leaves this file in the pull request that lands it. Its record (`docs/records/<id>.md`) and
its changelog note remain. The order is `docs/ROADMAP.md` › Build order.

## CI1 · Unit suite headroom (Dev)
when: before step 26's first code task
tier: core
perf: none
touches: tools/unit_tests.sh, tools/check.sh, .github/workflows/ci.yml, tests/unit/, docs/PROCESS.md
contract: none
acceptance:
  1. The record lists the twenty slowest unit test files with their time, measured on the cloud container.
  2. The unit suite runs in well under `tools/unit_tests.sh`'s 1080 s limit with room for steps 26 to 31: the slowest
     files made faster where a test does more work than its check needs, or the GUT run split across two CI jobs
     (and two local runs in `tools/check.sh`) if that is the cleaner fix. No test is skipped, weakened or deleted.
  3. `tools/check.sh` and CI still report failures and totals only, and a failure names its test file.
status: open
attempts: 0

## AD1 · Adaptive difficulty (Dev)
when: build order step 31, after the late features (owner, 2026-10-22)
tier: core
perf: optional
touches: game/ai/, game/config/, game/save/dev_settings.gd, game/ui/settings_screen.gd, game/play/play_session.gd,
  game/ui/xp_card.gd, game/progress/, tests/
contract: Data, not literals (6); Saves (8)
acceptance:
  1. A Dev switch makes the other team's skill a rating that blends the levels' numbers (the browser game's
     adaptiveDifficulty.ts): up a little after a round or match you win, down after one you lose, within its limits;
     the on/off habits come from the nearest level and stay fixed through a match. It never changes a level's own
     numbers (DECISIONS 2026-10-06).
  2. Your teammates never adapt; an adaptive match gives no XP and stays out of the records.
  3. The rating is saved and the end-of-match card says where the next match starts.
status: open
attempts: 0
