class_name Seeds
## Match seeds: unsigned 32-bit integers (the browser game's core/seed.ts). A match's separate random streams (bots, their
## plans) are derived from its seed with exact 32-bit arithmetic, so the same seed replays the same match
## (docs/ARCHITECTURE.md › Contracts 5).

const MAX_SEED := 0xFFFFFFFF
const MASK_32 := 0xFFFFFFFF
## seed × multiplier + offset, mod 2^32: arbitrary primes that keep the streams apart. Changing them changes every
## seeded bot decision.
const PLAN_MULTIPLIER := 15485863
const PLAN_OFFSET := 12345
const BOT_MULTIPLIER := 7919
const BOT_PER_CHARACTER := 104729
const WIND_PER_MATCH := 7368787
const KIT_MULTIPLIER := 2654435761
const KIT_PER_CHARACTER := 40503
## The bots' names' stream (BotRoster) is the seed with these bits flipped ("name"), as the browser game's rosterSeed.
const ROSTER_XOR := 0x6e616d65


## `seed × multiplier + add`, wrapped to 32 bits (GDScript's 64-bit integers wrap on overflow, keeping the low 32 bits
## exact).
static func derive(seed_value: int, multiplier: int, add: int) -> int:
	return ((seed_value & MASK_32) * multiplier + add) & MASK_32


## The bots' team-plan stream's seed for a match seeded with `seed_value`.
static func plan_seed(seed_value: int) -> int:
	return derive(seed_value, PLAN_MULTIPLIER, PLAN_OFFSET)


## Bot `character_id`'s own stream's seed for a match seeded with `seed_value`.
static func bot_seed(seed_value: int, character_id: int) -> int:
	return derive(seed_value, BOT_MULTIPLIER, (character_id * BOT_PER_CHARACTER) & MASK_32)


## The wind's seed for match `match_number` (1 for the first) played on a state seeded with `seed_value`: each rematch
## gets a new breeze.
static func wind_seed(seed_value: int, match_number: int) -> int:
	return derive(seed_value, 1, ((match_number - 1) * WIND_PER_MATCH) & MASK_32)


## Bot `character_id`'s kit pick's seed (BotKits.pick) for a match seeded with `seed_value`: each bot's pick is its
## own.
static func kit_seed(seed_value: int, character_id: int) -> int:
	return derive(seed_value, KIT_MULTIPLIER, ((character_id + 1) * KIT_PER_CHARACTER) & MASK_32)


## The bots' names' stream's seed (BotRoster.draw) for a match seeded with `seed_value`: apart from every other, so a
## seed replays the same names and no other roll moves.
static func roster_seed(seed_value: int) -> int:
	return (seed_value & MASK_32) ^ ROSTER_XOR


## A generator seeded with `seed_value`: every random draw in the simulation comes from one of these.
static func stream(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value & MASK_32
	return rng
