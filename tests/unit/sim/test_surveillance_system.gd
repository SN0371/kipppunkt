extends GutTest
## Tests for scrutiny and surveillance levels (rechenmodell.md section 8).

var _defs: GameDefs
var _state: GameState


func before_each() -> void:
	_defs = SimFixture.defs()
	_state = SimFixture.new_state()


func test_target_scrutiny_grows_with_radicalism_and_size() -> void:
	_state.party.radicalism = 50.0
	# 50 * (0.6 + 0.5 / 20) * 0.75
	assert_almost_eq(SurveillanceSystem.target_scrutiny(_state, _defs), 23.4375, 0.0001)


func test_informants_lower_thresholds() -> void:
	assert_eq(SurveillanceSystem.threshold(_state, 1), 35.0)
	var informant := PersonSystem.generate(_state)
	informant.role = "treasurer"
	informant.agenda = "informant"
	_state.persons.append(informant)
	assert_eq(SurveillanceSystem.threshold(_state, 1), 30.0)


func test_sustained_scrutiny_raises_the_level() -> void:
	_state.party.radicalism = 100.0
	_state.party.scrutiny = 50.0
	for i in 12:
		SurveillanceSystem.step(_state, _defs)
	assert_eq(_state.party.vs_level, 1)
	assert_eq(SimLog.find(_state, "surveillance_level").size(), 1)


func test_level_two_costs_members() -> void:
	_state.party.vs_level = 1
	_state.party.radicalism = 100.0
	_state.party.scrutiny = 70.0
	_state.resilience = 100.0
	for land: LandState in _state.lands.values():
		land.polling = 5.0
	var members := _state.party.members
	for i in 20:
		SurveillanceSystem.step(_state, _defs)
		if _state.party.vs_level == 2:
			break
	assert_eq(_state.party.vs_level, 2)
	assert_eq(_state.party.members, roundi(members * 0.97))


func test_level_falls_after_long_calm() -> void:
	_state.party.vs_level = 1
	_state.party.radicalism = 0.0
	_state.party.scrutiny = 0.0
	for i in SurveillanceSystem.DOWNGRADE_TURNS:
		SurveillanceSystem.step(_state, _defs)
	assert_eq(_state.party.vs_level, 0)
