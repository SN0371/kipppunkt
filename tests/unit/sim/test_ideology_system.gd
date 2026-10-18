extends GutTest
## Tests for ideology profile, position changes and contradiction risk (rechenmodell.md 5.1–5.3).

var _defs: GameDefs
var _state: GameState


func before_each() -> void:
	_defs = SimFixture.defs()
	_state = SimFixture.new_state()


func test_profile_without_positions_is_centre() -> void:
	assert_eq(IdeologySystem.profile(_state.party, _defs), Vector2.ZERO)


func test_single_position_reaches_axis_end() -> void:
	_state.party.positions["topic.taxes"] = 2
	assert_eq(IdeologySystem.profile(_state.party, _defs), Vector2(100, 0))


func test_opposing_topics_cancel_out() -> void:
	_state.party.positions["topic.taxes"] = 2
	_state.party.positions["topic.welfare"] = 2
	assert_eq(IdeologySystem.profile(_state.party, _defs), Vector2.ZERO)


func test_profile_is_weighted_by_vector_length() -> void:
	_state.party.positions["topic.wind_power"] = 1
	_state.party.positions["topic.organic_farming"] = 1
	# (0,-1)*1 + (0,-1)*1 = (0,-2); weight 2; scaled by 50.
	assert_eq(IdeologySystem.profile(_state.party, _defs), Vector2(0, -50))


func test_first_position_is_free() -> void:
	assert_eq(IdeologySystem.change_cost(_state, _defs, "topic.taxes", 2), 0.0)


func test_change_cost_grows_with_age_and_strong_donors() -> void:
	_state.party.positions["topic.taxes"] = 2
	_state.party.position_age["topic.taxes"] = 8
	# Two active donors hold a strong preference on taxes: 3 * 4 * (1 + 8/8) * (1 + 2/2) = 48.
	assert_almost_eq(IdeologySystem.change_cost(_state, _defs, "topic.taxes", -2), 48.0, 0.0001)


func test_withdrawn_donors_do_not_lock_in() -> void:
	_state.party.positions["topic.taxes"] = 2
	_state.donors["donor.auto_supplier"].active = false
	_state.donors["donor.real_estate"].active = false
	assert_almost_eq(IdeologySystem.change_cost(_state, _defs, "topic.taxes", 1), 3.0, 0.0001)


func test_set_position_pays_cost_and_resets_age() -> void:
	_state.party.positions["topic.welfare"] = 1
	_state.party.position_age["topic.welfare"] = 4
	_state.party.credibility = 50.0
	_state.party.unity = 70.0
	IdeologySystem.set_position(_state, _defs, "topic.welfare", -1)
	# No strong donors on welfare: 3 * 2 * (1 + 4/8) = 9.
	assert_almost_eq(_state.party.credibility, 41.0, 0.0001)
	assert_almost_eq(_state.party.unity, 66.0, 0.0001)
	assert_eq(_state.party.positions["topic.welfare"], -1)
	assert_eq(_state.party.position_age["topic.welfare"], 0)


func test_set_position_removes_equal_regional_message() -> void:
	IdeologySystem.set_regional_message(_state, "region.south", "topic.taxes", 2)
	IdeologySystem.set_position(_state, _defs, "topic.taxes", 2)
	assert_false(_state.party.regional_messages.has("region.south"))


func test_regional_message_equal_to_federal_position_is_not_stored() -> void:
	_state.party.positions["topic.taxes"] = 1
	IdeologySystem.set_regional_message(_state, "region.north", "topic.taxes", 1)
	assert_false(_state.party.regional_messages.has("region.north"))


func test_contradicting_messages_count_without_federal_position() -> void:
	IdeologySystem.set_regional_message(_state, "region.south", "topic.wind_power", -2)
	IdeologySystem.set_regional_message(_state, "region.north", "topic.wind_power", 2)
	var salience := PollingSystem.salience(_state, _defs)
	assert_almost_eq(IdeologySystem.message_deviation(_state.party, salience), 4.0, 0.0001)


func test_contradiction_risk_grows_and_decays() -> void:
	IdeologySystem.set_regional_message(_state, "region.south", "topic.wind_power", -2)
	IdeologySystem.set_regional_message(_state, "region.north", "topic.wind_power", 2)
	var salience := PollingSystem.salience(_state, _defs)
	IdeologySystem.update_contradiction(_state, _defs, salience)
	# 0 + 2 * 4 - 1 = 7
	assert_almost_eq(_state.party.contradiction_risk, 7.0, 0.0001)
	_state.party.regional_messages.clear()
	IdeologySystem.update_contradiction(_state, _defs, salience)
	assert_almost_eq(_state.party.contradiction_risk, 6.0, 0.0001)


func test_zero_is_a_deliberately_neutral_position() -> void:
	IdeologySystem.set_position(_state, _defs, "topic.taxes", 2)
	IdeologySystem.set_position(_state, _defs, "topic.taxes", 0)
	assert_eq(_state.party.positions["topic.taxes"], 0, "Neutral counts as having taken a stand")


func test_consistent_positions_have_no_contradiction() -> void:
	_state.party.positions["topic.taxes"] = 2
	_state.party.positions["topic.welfare"] = -2
	_state.party.positions["topic.nature_conservation"] = 1
	_state.party.positions["topic.organic_farming"] = 1
	assert_eq(IdeologySystem.inconsistency(_state.party, _defs), 0.0)


func test_contradiction_strength_follows_the_weakest_position() -> void:
	_state.party.positions["topic.taxes"] = 2
	_state.party.positions["topic.welfare"] = 2
	# Tax cuts and welfare: weight 0.5 at full positions.
	assert_almost_eq(IdeologySystem.inconsistency(_state.party, _defs), 0.5, 0.00001)
	_state.party.positions["topic.debt_brake"] = 1
	# Fiscal trilemma on top: weight 1.0, weakest position 1 of 2.
	assert_almost_eq(IdeologySystem.inconsistency(_state.party, _defs), 1.0, 0.00001)
	assert_eq(IdeologySystem.active_contradictions(_state.party, _defs).keys().size(), 2)


func test_nature_conservation_and_conventional_farming_contradict() -> void:
	_state.party.positions["topic.nature_conservation"] = 2
	_state.party.positions["topic.organic_farming"] = -1
	assert_almost_eq(IdeologySystem.inconsistency(_state.party, _defs), 0.5, 0.00001)


func test_contradictions_lower_the_credibility_rest_value() -> void:
	var rest := EconomySystem.credibility_rest(_state, _defs)
	_state.party.positions["topic.taxes"] = 2
	_state.party.positions["topic.welfare"] = 2
	# 15 * 0.5
	assert_almost_eq(EconomySystem.credibility_rest(_state, _defs), rest - 7.5, 0.00001)

