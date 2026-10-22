# MN3 · Opponents and Teammates on the Match screen

**Review:** pending

## Attempts

| Date | Attempt | Worker model | checks | Critic | Retry reason |
|---|---|---|---|---|---|
| 2026-10-22 | 1 | Sonnet | pass | | |

## Decisions

- **The BOTS section is its own part, `MatchBotsBox`** (`game/ui/match_bots_box.gd`), as RULES is `MatchRulesBox`: the
  page was over 500 lines. It holds the two rows and their blurbs and edits the `MatchPicks`; the page lights nothing
  of it, only tells it the team size and whether Custom is picked, on every refresh.
- **RULES stays under the mode cards (CR2)**, not in the right column as the concepts (drawn before step 15) have it.
  The right column is YOUR TEAM and BOTS and fits with room to spare.
- **All four levels on both rows, no DEV tag.** The concepts show three buttons (`bots-follow.png`) or four with PRO
  tagged DEV (`bots-picked-dev.png`) because Pro was dev content then; DF2b made it public (docs/records/DF2b.md), so
  Pro is always there and never tagged. Picking teammates is public too: nothing in the records or DECISIONS makes it
  dev content (the picture's "dev" is the Pro tag and the dev map), and the acceptance reads public.
- **Teammates are `MatchPicks.teammates`, "" while they follow** (`MatchOptions.teammates_level`, which asks
  `BotConfig.teammates_following`). Following lights the level they play, Normal against Easy, and the label says
  FOLLOWS OPPONENTS. Kept for the session like the other picks; main hands it to `PlaySession.teammate_difficulty`
  as it is, so "" follows and `counts_for_records()` already reads the pair.
- **A small "· FOLLOW OPPONENTS" button replaces the note once a level is picked** (the concept draws no way back).
  Without it a pick could never be undone, since picking the level they follow is a pick like any other.
- **The words are the browser game's** `DIFFICULTIES` and `TEAMMATE_DIFFICULTIES` blurbs, as translation keys
  (`BOT_<LEVEL>_BLURB`, `BOT_<LEVEL>_MATES`). Level buttons are the MN2 `MenuCard`s at the concept's 44 px, the
  unpicked in the dim colour as `.diff` has them. Both blurbs hold two lines of room, so the Teammates row doesn't move
  as the opponents' blurb changes.
- **The XP note is the match's own multiplier, not the opponents' alone.** The concept's "XP ×1.5" under Hard
  opponents with Normal teammates would be untrue: the match gives ×1. `MatchXp.multiplier` (the lower of the two
  levels, held to Custom's cap; the opponents alone when there are no teammates) is now the one function `earned` and
  the page both call, and a test checks they agree.
- **A 1v1 Custom match greys the Teammates row** with "No teammates in a 1v1." and lights none: the row keeps its
  place, so the page doesn't jump when the team size changes. A pick made before is kept and comes back at 2v2.
- **The summary names the teammates only when they play another level than the opponents** ("Hard bots · Normal
  teammates", also Easy bots with the default Normal teammates), and never in a 1v1; Custom stays last.
- **Following again keeps the keyboard's place** (QA advisory): the FOLLOW OPPONENTS button hides once pressed, so
  the focus moves to the Teammates button for the level they now play.
