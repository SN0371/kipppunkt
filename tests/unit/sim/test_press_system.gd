extends GutTest
## Tests for press investigations (rechenmodell.md section 9).


func test_probabilities() -> void:
	var defs := SimFixture.defs()
	var state := SimFixture.new_state()
	# 0.75 * 0.8
	assert_almost_eq(PressSystem.strength(state, defs), 0.6, 0.00001)
	state.party.contradiction_risk = 50.0
	state.party.reach_platform = 0.0
	assert_almost_eq(PressSystem.contradiction_probability(state, defs), 0.15, 0.00001)
	state.party.intransparency = 50.0
	assert_almost_eq(PressSystem.finance_probability(state, defs), 0.3, 0.00001)


func test_exposed_contradiction() -> void:
	var defs := SimFixture.defs_with({"press_strength": 100.0})
	var state := StateFactory.create(defs, SimFixture.SCENARIO, 1)
	state.party.contradiction_risk = 30.0
	state.party.credibility = 50.0
	state.party.regional_messages["region.south"] = {"topic.taxes": 2}
	PressSystem.step(state, defs)
	assert_almost_eq(state.party.credibility, 40.0, 0.0001)
	assert_almost_eq(state.party.contradiction_risk, 15.0, 0.0001)
	assert_true(state.party.regional_messages.is_empty())


func test_exposed_funding() -> void:
	var defs := SimFixture.defs_with({"press_strength": 100.0})
	var state := StateFactory.create(defs, SimFixture.SCENARIO, 1)
	state.party.intransparency = 40.0
	state.party.credibility = 50.0
	PressSystem.step(state, defs)
	assert_almost_eq(state.party.credibility, 40.0, 0.0001)
	assert_almost_eq(state.party.scrutiny, 10.0, 0.0001)
	assert_eq(state.party.intransparency, 0.0)


func test_undercover_journalist_publishes() -> void:
	var defs := SimFixture.defs()
	var state := SimFixture.new_state()
	var journalist := PersonSystem.generate(state)
	journalist.role = "treasurer"
	journalist.agenda = "journalist"
	journalist.material = 100.0
	state.persons.append(journalist)
	state.party.credibility = 50.0
	state.party.unity = 50.0
	PressSystem.step(state, defs)
	assert_almost_eq(state.party.credibility, 35.0, 0.0001)
	assert_almost_eq(state.party.unity, 40.0, 0.0001)
	assert_null(PersonSystem.by_id(state, journalist.id))
