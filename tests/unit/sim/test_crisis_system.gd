extends GutTest
## Tests for crises, omens and cooldown (rechenmodell.md section 11).


func test_no_omen_during_cooldown() -> void:
	var defs := SimFixture.defs_with({"crisis_probability": 1.0})
	var state := StateFactory.create(defs, SimFixture.SCENARIO, 1)
	for turn in range(1, CrisisSystem.COOLDOWN_TURNS):
		state.turn = turn
		CrisisSystem.step(state, defs)
		assert_eq(state.pending_crisis_id, "", "No omen in turn %d" % turn)


func test_no_omen_without_probability() -> void:
	var defs := SimFixture.defs_with({"crisis_probability": 0.0})
	var state := StateFactory.create(defs, SimFixture.SCENARIO, 1)
	for turn in range(1, 100):
		state.turn = turn
		CrisisSystem.step(state, defs)
	assert_eq(state.pending_crisis_id, "")
	assert_eq(state.crises.size(), 0)


func test_certain_crisis_is_announced_then_starts_then_ends() -> void:
	var defs := SimFixture.defs_with({"crisis_probability": 1.0})
	var state := StateFactory.create(defs, SimFixture.SCENARIO, 3)
	state.turn = CrisisSystem.COOLDOWN_TURNS
	CrisisSystem.step(state, defs)
	assert_ne(state.pending_crisis_id, "", "Omen announced")
	assert_true(state.pending_crisis_real)
	var started_turn := -1
	var ended_turn := -1
	for turn in range(state.turn + 1, state.turn + 20):
		state.turn = turn
		CrisisSystem.step(state, defs)
		if started_turn < 0 and state.crises.size() == 1:
			started_turn = turn
		if started_turn > 0 and ended_turn < 0 and state.crises.is_empty():
			ended_turn = turn
	assert_between(started_turn - CrisisSystem.COOLDOWN_TURNS, CrisisSystem.OMEN_MIN_TURNS, CrisisSystem.OMEN_MAX_TURNS)
	assert_between(ended_turn - started_turn, 4, 8, "Duration of the crisis")
	assert_eq(state.last_crisis_end_turn, ended_turn)


func test_running_crisis_counts_elapsed_turns() -> void:
	var defs := SimFixture.defs()
	var state := SimFixture.new_state()
	CrisisSystem.start(state, defs, "crisis.financial")
	assert_eq(state.crises[0].elapsed_turns, 0)
	CrisisSystem.step(state, defs)
	assert_eq(state.crises[0].elapsed_turns, 1)


func test_crisis_factors() -> void:
	var defs := SimFixture.defs()
	var state := SimFixture.new_state()
	assert_eq(CrisisSystem.donor_payment_factor(state, defs), 1.0)
	CrisisSystem.start(state, defs, "crisis.financial")
	assert_almost_eq(CrisisSystem.donor_payment_factor(state, defs), 0.7, 0.00001)
	assert_almost_eq(CrisisSystem.member_growth_factor(state, defs), 0.5, 0.00001)
