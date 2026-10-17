extends GutTest
## Every strategy bot plays whole games without errors, and its metrics are complete.

var _defs: GameDefs


func before_all() -> void:
	_defs = SimFixture.defs()


func test_every_bot_finishes_a_game() -> void:
	for bot in [PatientBot.new(), RadicalBot.new(), TwoFacedBot.new(), PassiveBot.new(), RandomBot.new()]:
		var row := _play(bot, 5)
		assert_ne(row["outcome"], "", "%s ends the game" % bot.id())
		for column in GameMetrics.COLUMNS:
			assert_true(row.has(column), "%s metric %s" % [bot.id(), column])


func test_bots_are_deterministic() -> void:
	assert_eq_deep(_play(RandomBot.new(), 3), _play(RandomBot.new(), 3))
	assert_eq_deep(_play(TwoFacedBot.new(), 3), _play(TwoFacedBot.new(), 3))


func test_two_faced_bot_sends_contradicting_messages() -> void:
	var bot := TwoFacedBot.new()
	bot.reset(1)
	var state := StateFactory.create(_defs, SimFixture.SCENARIO, 1)
	TurnRunner.start_turn(state, _defs)
	TurnRunner.finish_turn(state, _defs, bot.orders(state, _defs))
	assert_false(state.party.regional_messages.is_empty())


func test_patient_bot_stays_moderate() -> void:
	var bot := PatientBot.new()
	bot.reset(2)
	var state := StateFactory.create(_defs, SimFixture.SCENARIO, 2)
	for turn in 10:
		TurnRunner.play_turn(state, _defs, bot.orders(state, _defs))
	for value: int in state.party.positions.values():
		assert_between(value, -1, 1)
	assert_true(state.party.regional_messages.is_empty())


func _play(bot: Bot, game_seed: int) -> Dictionary:
	bot.reset(game_seed)
	var state := StateFactory.create(_defs, SimFixture.SCENARIO, game_seed)
	var peak := 0.0
	while not state.is_over():
		TurnRunner.start_turn(state, _defs)
		TurnRunner.finish_turn(state, _defs, bot.orders(state, _defs))
		peak = maxf(peak, state.latest_national_polling())
	return GameMetrics.collect(state, bot.id(), peak)
