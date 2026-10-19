# BR1 · The bot balance report

**Review:** 1 attempt · critic Accept 8/8 (Opus) · qa Pass · performance Pass

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-19 | 1 | Opus 5.5 (build thread) | ✓ | 8/8 Accept | – (QA added 4 tests; its two advisories taken in) |

## Decisions

- **The browser's report, ported** (`legacy/browser/pipeline/balanceReport.mjs`): `BalanceReport`
  (`tests/balance/balance_report.gd`) holds the figures and verdicts as pure functions, so `test_balance_report.gd`
  tests them; `tests/balance/balance_run.gd` plays the matches through MG1's `MatchRunner` and writes the Markdown.
  The verdicts and the 2-standard-error noise line are the browser's. A figure with no band reads **measured** (the
  browser called it in band, which reads as a judgment it isn't).
- **Figures per map, Elimination at Normal:** Alpha's and Beta's share of the decided rounds, and each end's (ends swap
  at half time, so a team's share and an end's differ), all against Normal's 45 to 55 %; rounds that run out the
  clock against the browser's ≤ 10 % (`ON_TIME_BAND`); and the median time and range of each round's first hit, with
  no band (the browser's first-hit figures were bands only for duels and for the east end at night, neither built
  here). Drawn rounds count as rounds, not decided.
- **Ends are named by compass** from their spawns (+X east, −Z north): Depot's and Neon Heights' end 0 is the west
  end, as in the browser's labels.
- **32 seeds a map by default** (`SEEDS=n` to change): about 250 rounds a map, a standard error of about 3 points on a
  share, so a 45 to 55 % band can tell a 5-point lean from noise. About 15 minutes for both maps here (Depot 374 s,
  Neon Heights 504 s). The report goes to `pipeline/out/` (ignored by git); its first run is below.
- **The unit test sits in `tests/unit/`,** outside the block's touches: it tests `BalanceReport`'s pure functions with
  the other unit tests, so the checks and CI run it, while the report itself never runs there.
- **Docs outside the touches:** `tests/README.md`, the ARCHITECTURE layout row and `pipeline/README.md` › Balance
  figures name the report and how to run it; `docs/records/MG1.md` gains the guards job's CI time (4 min 47 s on its
  first run) and a rewrapped line.
- **QA's advisories taken in:** a seed count that isn't a whole number from 1 is refused (it read as 1 seed); the
  on-time figure's counts say how many rounds were decided and how many were drawn with both teams out.

## First report (2026-10-19, `4e74aea`, seeds 1 to 32)

14 figures: 0 outside their band, 0 outside but within noise, 2 near an edge, 8 in band, 4 measured.

| Figure | Measured | Target | Verdict | Counts |
|---|---|---|---|---|
| Depot: Alpha's share of the decided rounds | 52.2 % ±3.2 | 45–55 % | near an edge | 130 of 249 decided |
| Depot: Beta's share of the decided rounds | 47.8 % ±3.2 | 45–55 % | near an edge | 119 of 249 decided |
| Depot: the west end's share of the decided rounds | 49.0 % ±3.2 | 45–55 % | in band | 122 of 249 decided |
| Depot: the east end's share of the decided rounds | 51.0 % ±3.2 | 45–55 % | in band | 127 of 249 decided |
| Depot: rounds that run out the clock | 0.0 % | ≤ 10 % | in band | 0 of 251 rounds |
| Depot: median time to a round's first hit | 11.0 s | – | measured | 251 rounds with a hit |
| Depot: median range of a round's first hit | 9.3 m | – | measured | 251 rounds with a hit |
| Neon Heights: Alpha's share of the decided rounds | 49.4 % ±3.2 | 45–55 % | in band | 117 of 237 decided |
| Neon Heights: Beta's share of the decided rounds | 50.6 % ±3.2 | 45–55 % | in band | 120 of 237 decided |
| Neon Heights: the west end's share of the decided rounds | 50.2 % ±3.2 | 45–55 % | in band | 119 of 237 decided |
| Neon Heights: the east end's share of the decided rounds | 49.8 % ±3.2 | 45–55 % | in band | 118 of 237 decided |
| Neon Heights: rounds that run out the clock | 0.0 % | ≤ 10 % | in band | 0 of 239 rounds |
| Neon Heights: median time to a round's first hit | 14.9 s | – | measured | 239 rounds with a hit |
| Neon Heights: median range of a round's first hit | 8.0 m | – | measured | 239 rounds with a hit |

**What it says:** both fields are fair at Normal. Every share is within 2.5 points of even, and the ends are closer
still. Depot's two team figures are "near an edge" only because 52.2 % is within one standard error of 55 %, not
because they lean. The teams are identical bots, so a team lean can only be noise or seed order; the end figures are
the ones that say something about the maps. No round ran out the clock. First hits come at 11 to 15 s and 8 to 9 m,
which is close quarters as the fields intend.

## Known issues left

None new.
