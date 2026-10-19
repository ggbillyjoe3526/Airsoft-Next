# Tests

Nothing under `tests/` ships; every export preset leaves it out.

| Folder | What | Run by |
|---|---|---|
| `unit/` | GUT tests, `test_*.gd`, one file per system | `tools/unit_tests.sh`, in `tools/check.sh` and CI |
| `guards/` | Whole bot matches over 16 seeds a field, checked against the browser game's limits (`docs/records/MG1.md`) | `tools/match_guards.sh`, `tools/check.sh --guards` and CI's own "Match guards" job |
| `support/` | Helpers the tests share: `MatchRunner` plays a whole Elimination match headless, bots on both teams, and tallies it (the guards and the balance report read it) | – |
