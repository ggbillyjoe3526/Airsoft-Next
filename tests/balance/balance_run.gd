extends SceneTree
## Plays the balance report's matches and writes it (BR1): tools/balance.sh runs this headless. Every map in MAPS whose
## id contains the filter plays seeds 1 to the seed count, bots on both teams at Normal, through MatchRunner; the
## figures and verdicts are BalanceReport's. Arguments after `--`: the report's path, the commit, the seed count, then
## an optional filter.

## Depot, and Neon Heights while it is dev (Woodland waits for its own step; the range is not a match map).
const MAPS: Array[String] = ["depot", "neonHeights"]
## Match time a match may take (s), as the guards allow.
const MAX_MATCH_SECONDS := 30.0 * 60.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("balance_run.gd needs: <report path> <commit> <seeds> [filter]")
		quit(2)
		return
	var path := args[0]
	var commit := args[1]
	if not args[2].is_valid_int() or args[2].to_int() < 1:
		push_error("the seed count must be a whole number from 1, not '%s'" % args[2])
		quit(2)
		return
	var seeds := args[2].to_int()
	var filter := args[3] if args.size() > 3 else ""
	var rows: Array[BalanceReport.Figure] = []
	for map_id in MAPS:
		if filter != "" and not map_id.containsn(filter):
			continue
		var runner := MatchRunner.new(root, map_id)
		await physics_frame
		await physics_frame
		if not runner.map.problems.is_empty():
			push_error("%s: %s" % [map_id, ", ".join(runner.map.problems)])
			runner.free_level()
			continue
		var matches: Array[MatchRunner.MatchTally] = []
		var started := Time.get_ticks_msec()
		for seed_value in range(1, seeds + 1):
			matches.append(runner.play(seed_value, MAX_MATCH_SECONDS))
		var name := runner.map.display_name if runner.map.display_name != "" else map_id
		rows.append_array(BalanceReport.figures(name, BalanceReport.end_names(runner.map), matches))
		print("%s: %d matches in %.0f s" % [name, matches.size(), (Time.get_ticks_msec() - started) / 1000.0])
		runner.free_level()
	if rows.is_empty():
		push_error("no map matches the filter '%s'" % filter)
		quit(1)
		return
	var when := Time.get_datetime_string_from_system(true, true).substr(0, 16) + " UTC"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("can't write %s" % path)
		quit(1)
		return
	file.store_string(BalanceReport.markdown(rows, commit, when, seeds, filter))
	file.close()
	quit()
