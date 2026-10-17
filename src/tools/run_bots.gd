extends SceneTree
## Plays games with strategy bots without graphics and checks the balancing corridors
## (prototyp-plan.md section 7).
##
## Usage:
##   godot --headless --path . -s src/tools/run_bots.gd -- [options]
## Options:
##   --bot=<id>|all        Bot to run (patient, radical, two_faced, passive, random); default all
##   --runs=<n>            Games per bot; default 100
##   --seed=<n>            Seed of the first game; game i uses seed + i; default 1
##   --out=<dir>           Directory for the CSV files; default res://reports/bots
##   --param=<name>=<v>    Overrides a balancing parameter for this run; may be repeated
##   --warn-only           Exit with 0 even if a corridor is missed
## Exit code: 0 if all corridors pass (or --warn-only), 1 otherwise, 2 on invalid input.

const BOT_IDS: PackedStringArray = ["patient", "radical", "two_faced", "passive", "random"]
const SCENARIO := "scenario.new_party"


func _init() -> void:
	quit(_run(OS.get_cmdline_user_args()))


func _run(args: PackedStringArray) -> int:
	var options := _parse(args)
	if options.has("error"):
		printerr(options["error"])
		return 2
	var defs := GameDefs.load_from_dir("res://data")
	if not defs.is_valid():
		printerr("Invalid data:\n  " + "\n  ".join(defs.errors))
		return 2
	for name: String in options["params"]:
		if not ParamSet.REQUIRED.has(name):
			printerr("Unknown parameter: " + name)
			return 2
		defs.params.override(name, options["params"][name])
	var out_dir: String = options["out"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var all_passed := true
	for bot_id: String in options["bots"]:
		var start_ms := Time.get_ticks_msec()
		var rows := _play_games(defs, bot_id, options["runs"], options["seed"])
		_write_csv(out_dir.path_join(bot_id + ".csv"), rows)
		var result := Corridors.check(bot_id, rows)
		all_passed = all_passed and result["passed"]
		print("%-9s %s  %s  (%d games, %.1f s)" % [
			bot_id, "PASS" if result["passed"] else "FAIL", result["summary"], rows.size(),
			(Time.get_ticks_msec() - start_ms) / 1000.0,
		])
	return 0 if all_passed or options["warn_only"] else 1


func _play_games(defs: GameDefs, bot_id: String, runs: int, first_seed: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for i in runs:
		var game_seed := first_seed + i
		var bot := _create_bot(bot_id)
		bot.reset(game_seed)
		var state := StateFactory.create(defs, SCENARIO, game_seed)
		var peak := 0.0
		while not state.is_over():
			TurnRunner.start_turn(state, defs)
			TurnRunner.finish_turn(state, defs, bot.orders(state, defs))
			peak = maxf(peak, state.latest_national_polling())
		rows.append(GameMetrics.collect(state, bot_id, peak))
	return rows


func _create_bot(bot_id: String) -> Bot:
	match bot_id:
		"patient":
			return PatientBot.new()
		"radical":
			return RadicalBot.new()
		"two_faced":
			return TwoFacedBot.new()
		"passive":
			return PassiveBot.new()
		"random":
			return RandomBot.new()
	assert(false, "Unknown bot: " + bot_id)
	return null


func _write_csv(path: String, rows: Array[Dictionary]) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("Cannot write %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_line(",".join(GameMetrics.COLUMNS))
	for row in rows:
		file.store_line(GameMetrics.to_csv_line(row))


func _parse(args: PackedStringArray) -> Dictionary:
	var options := {
		"bots": BOT_IDS, "runs": 100, "seed": 1, "out": "res://reports/bots",
		"params": {}, "warn_only": false,
	}
	for arg in args:
		if arg == "--warn-only":
			options["warn_only"] = true
			continue
		var parts := arg.trim_prefix("--").split("=", true, 1)
		if parts.size() != 2:
			return {"error": "Invalid argument: " + arg}
		match parts[0]:
			"bot":
				if parts[1] != "all" and not BOT_IDS.has(parts[1]):
					return {"error": "Unknown bot: " + parts[1]}
				options["bots"] = BOT_IDS if parts[1] == "all" else PackedStringArray([parts[1]])
			"runs", "seed":
				if not parts[1].is_valid_int():
					return {"error": "Not a number: " + arg}
				options[parts[0]] = parts[1].to_int()
			"out":
				options["out"] = parts[1]
			"param":
				var param := parts[1].split("=", true, 1)
				if param.size() != 2 or not param[1].is_valid_float():
					return {"error": "Invalid parameter override: " + arg}
				options["params"][param[0]] = param[1].to_float()
			_:
				return {"error": "Unknown option: " + arg}
	return options
