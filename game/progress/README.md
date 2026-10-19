# game/progress

Levels, XP and records (the browser game's `src/progress/` and `src/stats/`): what each level unlocks, what a match
gives, what the player has unlocked and their records. Plain classes; the stores save through `SaveFile`, each in its
own file apart from the settings and the loadouts.

| File | What |
|---|---|
| `level_table.gd` | `LevelTable`: `data/levels.md` read against the pool (each level's XP, running total and unlocks, the cap, each item's level, the XP per event and each difficulty's multiplier); what it can't read is listed by line, never thrown; `standing` says where an XP total stands |
| `progress.gd` | `Progress`: the XP earned and every item unlocked, at `user://progress.save`; `add_xp` stops at the cap and returns a `LevelUp`; unlocks are only ever added (`grant_reached` brings in what levels.md moved down); `reset` is Settings › Dev › Reset level |
| `match_xp.gd` | `MatchXp`: a finished match's XP line by line from an `Outcome`, by levels.md's rules (a shorter match gives less, the lower team difficulty multiplies) |
| `records.gd` | `Records`: wins and losses per difficulty and mode, best accuracy, longest win streak, at `user://records.save` |
| `player_tally.gd` | `PlayerTally`: your hits, BBs fired and rounds won that you took part in, from each tick's events; `settle` gives a finished match's XP and records it once, none off the record |

Who uses it: `PlaySession` settles each finished match it `counts` (the game's own, never a test or the smoke test);
`LoadoutRules.follow_progress` locks what isn't unlocked (Settings › Dev › Disable levelling unlocks it all and makes a
match give no XP); the top bar's chip shows the level; the Armory (`ArmoryPage`) lists every level and item against it and says when a file couldn't be read, and `Hud.show_xp` puts a settled match's XP under the win banner (`XpCard`).
