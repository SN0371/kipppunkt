extends GutTest
## Tests for person generation, leadership and loyalty checks (rechenmodell.md section 10).

var _state: GameState


func before_each() -> void:
	_state = SimFixture.new_state()


func test_start_state_has_a_loyal_chair_without_agenda() -> void:
	var chair := PersonSystem.by_role(_state, "chair")
	assert_not_null(chair)
	assert_eq(chair.loyalty, 100.0)
	assert_eq(chair.agenda, "none")


func test_attributes_stay_in_range() -> void:
	for i in 500:
		var person := PersonSystem.generate(_state)
		for attribute in ["loyalty", "persuasion", "network", "competence"]:
			assert_between(person.get(attribute), PersonSystem.ATTRIBUTE_MIN, 100.0)


func test_loyalty_never_gets_a_bonus() -> void:
	for i in 500:
		var person := PersonSystem.generate(_state)
		assert_true(person.loyalty <= PersonSystem.ATTRIBUTE_MAX, "Loyalty is never boosted")


func test_agenda_frequencies_match_the_model() -> void:
	var counts := {"none": 0, "careerist": 0, "ideologue": 0, "journalist": 0, "informant": 0}
	var total := 4000
	for i in total:
		counts[PersonSystem.generate(_state).agenda] += 1
	assert_almost_eq(counts["careerist"] / float(total), 0.10, 0.02)
	assert_almost_eq(counts["ideologue"] / float(total), 0.08, 0.02)
	assert_almost_eq(counts["informant"] / float(total), 0.02, 0.01)


func test_informants_become_more_frequent_with_surveillance() -> void:
	_state.party.vs_level = 3
	var informants := 0
	var total := 4000
	for i in total:
		if PersonSystem.generate(_state).agenda == "informant":
			informants += 1
	assert_almost_eq(informants / float(total), 0.11, 0.02)


func test_ids_are_unique() -> void:
	var first := PersonSystem.generate(_state)
	var second := PersonSystem.generate(_state)
	assert_ne(first.id, second.id)


func test_leadership_averages_chair_and_state_chair() -> void:
	var chair := PersonSystem.by_role(_state, "chair")
	chair.persuasion = 60.0
	var state_chair := PersonSystem.generate(_state)
	state_chair.role = "state_chair_south"
	state_chair.persuasion = 80.0
	state_chair.agenda = "ideologue"
	_state.persons.append(state_chair)
	assert_eq(PersonSystem.leadership(_state, "region.south"), {"persuasion": 70.0, "ideologue": true})
	assert_eq(PersonSystem.leadership(_state, "region.north"), {"persuasion": 60.0, "ideologue": false})


func test_pool_refresh_keeps_staff_and_replaces_candidates() -> void:
	var old_candidate := PersonSystem.generate(_state)
	_state.persons.append(old_candidate)
	PersonSystem.refresh_pool(_state)
	assert_null(PersonSystem.by_id(_state, old_candidate.id), "Old candidates leave")
	assert_not_null(PersonSystem.by_role(_state, "chair"), "Staff stays")
	# 2 + floor((2 + 2) / 25) = 2 new candidates
	assert_eq(_state.persons.size(), 3)


func test_fully_loyal_person_always_passes() -> void:
	var person := PersonSystem.generate(_state)
	person.loyalty = 100.0
	_state.party.unity = 100.0
	for i in 100:
		assert_true(PersonSystem.loyalty_check(_state, person))
