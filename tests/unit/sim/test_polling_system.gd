extends GutTest
## Tests for the polling model (rechenmodell.md section 3).

var _defs: GameDefs
var _state: GameState


func before_each() -> void:
	_defs = SimFixture.defs()
	_state = SimFixture.new_state()


func test_salience_is_one_without_crisis() -> void:
	var salience := PollingSystem.salience(_state, _defs)
	for topic_id: String in _defs.topics:
		assert_eq(salience[topic_id], 1.0, topic_id)


func test_crisis_and_modifier_raise_salience() -> void:
	var crisis := CrisisState.new()
	crisis.crisis_id = "crisis.energy"
	_state.crises.append(crisis)
	ModifierSystem.add(_state, "test", "salience.topic.housing_costs", 0.3, 1)
	var salience := PollingSystem.salience(_state, _defs)
	assert_almost_eq(salience["topic.housing_costs"], 2.3, 0.00001)
	assert_almost_eq(salience["topic.wind_power"], 1.5, 0.00001)


func test_salience_is_capped() -> void:
	ModifierSystem.add(_state, "test", "salience.topic.taxes", 10.0)
	assert_eq(PollingSystem.salience(_state, _defs)["topic.taxes"], PollingSystem.SALIENCE_MAX)


func test_topic_fit_uses_all_topics_in_denominator() -> void:
	_state.party.positions["topic.taxes"] = 1
	var salience := PollingSystem.salience(_state, _defs)
	# Bavaria weights sum to 16; taxes weight 2, full agreement.
	assert_almost_eq(PollingSystem.topic_fit(_defs, _defs.lands["land.by"], _state.party, salience), 2.0 / 16.0, 0.00001)


func test_regional_message_replaces_federal_position() -> void:
	_state.party.positions["topic.taxes"] = 1
	_state.party.regional_messages["region.south"] = {"topic.taxes": -1}
	var salience := PollingSystem.salience(_state, _defs)
	# Agreement 1 - |-1 - 1| / 2 = 0
	assert_eq(PollingSystem.topic_fit(_defs, _defs.lands["land.by"], _state.party, salience), 0.0)
	# Other regions keep the federal position.
	assert_gt(PollingSystem.topic_fit(_defs, _defs.lands["land.he"], _state.party, salience), 0.0)


func test_topic_fit_can_be_negative() -> void:
	_state.party.positions["topic.combustion_ban"] = 2
	var salience := PollingSystem.salience(_state, _defs)
	# Baden-Württemberg: weight 3, preference -2, agreement -1; total weight 13.
	assert_almost_eq(PollingSystem.topic_fit(_defs, _defs.lands["land.bw"], _state.party, salience), -3.0 / 13.0, 0.00001)


func test_reach_factor_mixes_platforms_and_classic_media_by_age() -> void:
	_state.party.reach_platform = 5.0
	# Bavaria, age index 35: 0.65 * 5 + 0.35 * 10 = 6.75 -> 0.3 + 0.7 * 0.0675
	assert_almost_eq(PollingSystem.reach_factor(_defs.lands["land.by"], _state.party, 10.0), 0.34725, 0.00001)


func test_first_crisis_turn_rallies_round_the_government() -> void:
	var crisis := CrisisState.new()
	crisis.crisis_id = "crisis.financial"
	_state.crises.append(crisis)
	var salience := PollingSystem.salience(_state, _defs)
	assert_eq(PollingSystem.crisis_bonus(_state, _defs, _defs.lands["land.by"], salience), -1.0)
	crisis.elapsed_turns = 1
	_state.party.positions["topic.welfare"] = 2
	# Saxony-Anhalt: crisis topics taxes (1 x 2), welfare (3 x 2), debt brake (1 x 1.5);
	# only welfare has a position, full agreement: 6 / 9.5.
	assert_almost_eq(PollingSystem.crisis_bonus(_state, _defs, _defs.lands["land.st"], salience), 4.0 * 6.0 / 9.5, 0.00001)


func test_surveillance_level_costs_stigma() -> void:
	var ctx := PollingSystem.make_context(_state, _defs)
	var before := PollingSystem.target(_state, _defs, "land.by", ctx)
	_state.party.vs_level = 1
	# 1.5 * 1 * 75 / 100
	assert_almost_eq(PollingSystem.target(_state, _defs, "land.by", ctx), before - 1.125, 0.00001)


func test_modifiers_shift_target() -> void:
	var ctx := PollingSystem.make_context(_state, _defs)
	var before := PollingSystem.target(_state, _defs, "land.by", ctx)
	ModifierSystem.add(_state, "test", "polling_target.land.by", 2.0, 1)
	ModifierSystem.add(_state, "test", "polling_target", 0.5, 1)
	assert_almost_eq(PollingSystem.target(_state, _defs, "land.by", ctx), before + 2.5, 0.00001)


func test_fitting_position_raises_target() -> void:
	var ctx := PollingSystem.make_context(_state, _defs)
	var before := PollingSystem.target(_state, _defs, "land.sh", ctx)
	_state.party.positions["topic.wind_power"] = 2
	ctx = PollingSystem.make_context(_state, _defs)
	assert_gt(PollingSystem.target(_state, _defs, "land.sh", ctx), before)


func test_national_polling_is_population_weighted() -> void:
	assert_almost_eq(PollingSystem.national(_state, _defs), 0.5, 0.00001)
	_state.lands["land.nw"].polling = 10.5
	assert_almost_eq(PollingSystem.national(_state, _defs), 0.5 + 0.213 * 10.0, 0.00001)


func test_step_keeps_polling_in_range_and_records_history() -> void:
	for i in 10:
		PollingSystem.step(_state, _defs)
	for land: LandState in _state.lands.values():
		assert_between(land.polling, 0.0, _defs.params.value("polling_max"))
	assert_eq(_state.national_polling_history.size(), GameState.POLLING_HISTORY_LENGTH)
