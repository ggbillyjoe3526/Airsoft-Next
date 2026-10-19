class_name LaunchSeed
extends RefCounted
## The `--seed <n>` launch option (also `--seed=<n>`), given after `--` as in `godot --path . -- --seed 1234`: the match
## starts on that seed, so a seed noted from the F3 overlay replays that match. A bad value is ignored with a warning.
## Without it each Play gets a fresh seed (docs/DECISIONS.md › each launch a fresh seed).

## `parse` found no usable seed.
const NONE := -1
const OPTION := "--seed"


## The seed `args` (OS.get_cmdline_user_args()) ask for, or NONE if there is none or it is bad (a number from 0 to
## Seeds.MAX_SEED). The first `--seed` counts.
static func parse(args: PackedStringArray) -> int:
	for i in args.size():
		var value := ""
		if args[i] == OPTION:
			if i + 1 >= args.size():
				push_warning("LaunchSeed: %s needs a number; ignored" % OPTION)
				return NONE
			value = args[i + 1]
		elif args[i].begins_with(OPTION + "="):
			value = args[i].substr(OPTION.length() + 1)
		else:
			continue
		if not value.is_valid_int():
			push_warning("LaunchSeed: %s '%s' isn't a whole number; ignored" % [OPTION, value])
			return NONE
		var n := value.to_int()
		if n < 0 or n > Seeds.MAX_SEED:
			push_warning("LaunchSeed: %s %s is outside 0 to %d; ignored" % [OPTION, value, Seeds.MAX_SEED])
			return NONE
		return n
	return NONE


## A fresh seed from the engine's own randomness (not the simulation's: it only picks the seed).
static func fresh() -> int:
	return randi() & Seeds.MASK_32
