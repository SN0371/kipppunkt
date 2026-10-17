extends GutTest
## Tests for income, members, activists, action points and decay (rechenmodell.md section 6).

var _defs: GameDefs
var _state: GameState


func before_each() -> void:
	_defs = SimFixture.defs()
	_state = SimFixture.new_state()


func test_first_income() -> void:
	EconomySystem.income(_state, _defs)
	# 50 + 300 * 0.03 - 8 * (1 + 4 / 50); no donor is satisfied enough to pay yet.
	assert_almost_eq(_state.party.money, 50.36, 0.0001)
	# 300 * (1 + 0.02 * 0.7) + 0.05 * (1000 * 0.5 - 300) = 304.2 + 10
	assert_eq(_state.party.members, 314)
	# 314 * (0.05 + 0.10 * 0.7 + 0.10 * 0.1)
	assert_eq(_state.party.activists, 40)
	assert_eq(_state.party.action_points, 4)


func test_filled_functions_and_campaign_add_action_points() -> void:
	var secretary := PersonSystem.generate(_state)
	secretary.role = "general_secretary"
	_state.persons.append(secretary)
	assert_eq(EconomySystem.action_points(_state, _defs), 5)
	_state.turn = 3
	assert_eq(EconomySystem.action_points(_state, _defs), 7, "int(5 * 1.5) in a campaign quarter")


func test_action_points_are_capped() -> void:
	for land: LandState in _state.lands.values():
		land.in_landtag = true
	assert_eq(EconomySystem.action_points(_state, _defs), EconomySystem.MAX_ACTION_POINTS)


func test_state_funding_for_votes() -> void:
	_state.lands["land.by"].last_state_result = 6.0
	_state.lands["land.by"].turnout = 70.0
	_state.lands["land.sh"].last_state_result = 0.9
	# Only Bavaria qualifies: 0.158 * 61 000 000 * 0.70 * 0.06
	assert_almost_eq(EconomySystem.funded_votes(_state, _defs), 404796.0, 0.5)


func test_state_funding_is_capped_by_own_income() -> void:
	_state.party.money = 0.0
	_state.party.last_federal_result = 5.0
	for land: LandState in _state.lands.values():
		land.turnout = 75.0
	EconomySystem.income(_state, _defs)
	# Entitlement 0.0002 * 61 000 000 * 0.75 * 0.05 = 457.5, capped at the fees 300 * 0.03 = 9.
	var entry: Dictionary = SimLog.find(_state, "income")[0]["data"]
	assert_almost_eq(entry["state_funding"], 9.0, 0.0001)
	assert_almost_eq(entry["state_funding_capped"], 448.5, 0.0001)
	assert_almost_eq(_state.party.money, 9.0 + 9.0 - 8.64, 0.0001)


func test_start_boost_fades_with_party_size() -> void:
	_set_national_polling(1.0)
	_state.party.members = 1000
	# No start boost at 1000 members, and the target 1000 * 1 is reached: no change.
	assert_eq(EconomySystem.next_members(_state, _defs), 1000)


func test_support_attracts_members_towards_target() -> void:
	_set_national_polling(5.0)
	_state.party.members = 2000
	# 2000 + 0.05 * (5000 - 2000)
	assert_eq(EconomySystem.next_members(_state, _defs), 2150)


func test_members_drift_away_when_support_falls() -> void:
	_set_national_polling(1.0)
	_state.party.members = 3000
	# 3000 + 0.02 * (1000 - 3000)
	assert_eq(EconomySystem.next_members(_state, _defs), 2960)


func test_low_unity_makes_members_leave() -> void:
	_set_national_polling(1.0)
	_state.party.members = 1000
	_state.party.unity = 0.0
	# Exit rate 0.03 at unity 0.
	assert_eq(EconomySystem.next_members(_state, _defs), 970)


func test_decay_of_reach_and_radicalism() -> void:
	_state.party.reach_platform = 50.0
	_state.party.radicalism = 20.0
	var salience := PollingSystem.salience(_state, _defs)
	EconomySystem.decay(_state, _defs, salience)
	assert_almost_eq(_state.party.reach_platform, 46.0, 0.0001)
	assert_almost_eq(_state.party.radicalism, 19.5, 0.0001)


func test_radical_action_stops_radicalism_decay() -> void:
	_state.party.radicalism = 20.0
	_state.party.radical_action_this_turn = true
	EconomySystem.decay(_state, _defs, PollingSystem.salience(_state, _defs))
	assert_eq(_state.party.radicalism, 20.0)
	assert_false(_state.party.radical_action_this_turn, "Flag is reset for the next turn")


func test_resilience_recovers_towards_start_value() -> void:
	_state.resilience = 55.0
	EconomySystem.decay(_state, _defs, PollingSystem.salience(_state, _defs))
	assert_almost_eq(_state.resilience, 55.4, 0.0001)


func test_positions_age() -> void:
	_state.party.positions["topic.taxes"] = 1
	_state.party.position_age["topic.taxes"] = 2
	EconomySystem.decay(_state, _defs, PollingSystem.salience(_state, _defs))
	assert_eq(_state.party.position_age["topic.taxes"], 3)


func _set_national_polling(value: float) -> void:
	for land: LandState in _state.lands.values():
		land.polling = value
