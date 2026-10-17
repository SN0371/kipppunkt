extends GutTest
## Tests for representation gap, turnout and mobilization (rechenmodell.md section 3.8).

var _defs: GameDefs
var _state: GameState


func before_each() -> void:
	_defs = SimFixture.defs()
	_state = SimFixture.new_state()


func test_gap_is_the_weighted_share_of_strong_preferences() -> void:
	var salience := PollingSystem.salience(_state, _defs)
	# Baden-Württemberg: only the combustion ban (weight 3 of 10) is held strongly.
	assert_almost_eq(RepresentationSystem.gap(_defs, _defs.lands["land.bw"], salience), 0.3, 0.00001)


func test_crisis_widens_the_gap() -> void:
	var salience := PollingSystem.salience(_state, _defs)
	var land := _defs.lands["land.be"]
	# Berlin: housing (weight 3 of 8) is held strongly.
	assert_almost_eq(RepresentationSystem.gap(_defs, land, salience), 0.375, 0.00001)
	CrisisSystem.start(_state, _defs, "crisis.energy")
	salience = PollingSystem.salience(_state, _defs)
	# Housing x2, wind and combustion ban x1.5: 6 of 12.
	assert_almost_eq(RepresentationSystem.gap(_defs, land, salience), 0.5, 0.00001)


func test_no_mobilization_without_matching_positions() -> void:
	var salience := PollingSystem.salience(_state, _defs)
	var land := _defs.lands["land.bw"]
	assert_eq(RepresentationSystem.mobilization(_defs, land, _state.party, salience), 0.0)
	_state.party.positions["topic.combustion_ban"] = 2
	assert_eq(RepresentationSystem.mobilization(_defs, land, _state.party, salience), 0.0, "Wrong direction")


func test_mobilization_rewards_strong_answers_amplified_by_radicalism() -> void:
	var salience := PollingSystem.salience(_state, _defs)
	var land := _defs.lands["land.bw"]
	_state.party.positions["topic.combustion_ban"] = -2
	_state.party.radicalism = 50.0
	# 6 * 0.3 * 1 * (0.5 + 0.5)
	assert_almost_eq(RepresentationSystem.mobilization(_defs, land, _state.party, salience), 1.8, 0.00001)
	_state.party.radicalism = 0.0
	assert_almost_eq(RepresentationSystem.mobilization(_defs, land, _state.party, salience), 0.9, 0.00001)
	_state.party.positions["topic.combustion_ban"] = -1
	assert_almost_eq(RepresentationSystem.mobilization(_defs, land, _state.party, salience), 0.45, 0.00001, "Moderate answer counts half")


func test_regional_message_counts_for_mobilization() -> void:
	var salience := PollingSystem.salience(_state, _defs)
	_state.party.regional_messages["region.south"] = {"topic.combustion_ban": -2}
	assert_gt(RepresentationSystem.mobilization(_defs, _defs.lands["land.bw"], _state.party, salience), 0.0)
	assert_eq(RepresentationSystem.mobilization(_defs, _defs.lands["land.ni"], _state.party, salience), 0.0)


func test_turnout_falls_with_gap_and_rises_with_mobilization() -> void:
	# 78 - 30 * 0.3
	assert_almost_eq(RepresentationSystem.turnout(_defs, 0.3, 0.0), 69.0, 0.00001)
	assert_almost_eq(RepresentationSystem.turnout(_defs, 0.3, 2.0), 71.0, 0.00001)


func test_start_state_has_turnout() -> void:
	assert_almost_eq(_state.lands["land.bw"].turnout, 69.0, 0.00001)
	assert_almost_eq(_state.lands["land.bw"].representation_gap, 0.3, 0.00001)


func test_mobilization_raises_polling_target_outside_competition() -> void:
	var ctx := PollingSystem.make_context(_state, _defs)
	var before := PollingSystem.target(_state, _defs, "land.bw", ctx)
	_state.party.regional_messages["region.south"] = {"topic.combustion_ban": -2}
	var with_message := PollingSystem.target(_state, _defs, "land.bw", ctx)
	var topic_part := with_message - before - RepresentationSystem.mobilization(
		_defs, _defs.lands["land.bw"], _state.party, ctx.salience
	)
	assert_gt(topic_part, 0.0, "The topic fit adds its own part on top of the mobilization")
