class_name SquadOrder
## Squad orders (the browser game's config/squad.ts, M22): what a character tells its bot teammates in play, given as
## its PlayerCommand's one-shot squad_order. The simulation turns it into a SQUAD_ORDER event (or a refused one); the
## bots' controller hands it out (BotController, SquadOrders). An order holds until it is given again, its giver is out,
## or the round ends; Team plan ends it at once.

## NONE: no order this tick. TEAM_PLAN: back to the team plan (the order wheel's Team Plan).
enum Kind { NONE, FOLLOW, HOLD, REGROUP, TEAM_PLAN }
