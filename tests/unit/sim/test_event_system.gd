extends GutTest
## Tests events, taking a stand and founding (rechenmodell.md section 5.8).

var _defs: GameDefs
var _state: GameState


func before_each() -> void:
	_defs = SimFixture.defs()
	_state = SimFixture.new_state()


func test_founding_sets_names_and_two_free_positions() -> void:
	var programme := {"topic.taxes": 2, "topic.wind_power": -1}
	assert_eq(FoundingSystem.check(_defs, "Neue Mitte", "NM", "Alex Muster", programme), "")
	var credibility := _state.party.credibility
	FoundingSystem.found(_state, _defs, "Neue Mitte", "NM", "Alex Muster", programme)
	assert_eq(_state.party.name, "Neue Mitte")
	assert_eq(_state.party.abbreviation, "NM")
	assert_eq(PersonSystem.by_role(_state, "chair").name, "Alex Muster")
	assert_eq(_state.party.positions, {"topic.taxes": 2, "topic.wind_power": -1})
	assert_eq(_state.party.credibility, credibility, "Founding is free")


func test_founding_needs_exactly_two_real_positions() -> void:
	assert_ne(FoundingSystem.check(_defs, "A", "A", "B", {"topic.taxes": 1}), "")
	assert_ne(FoundingSystem.check(_defs, "A", "A", "B", {"topic.taxes": 1, "topic.welfare": 0}), "", "Neutral is no reason to found a party")
	assert_ne(FoundingSystem.check(_defs, "", "A", "B", {"topic.taxes": 1, "topic.welfare": 1}), "")


func test_waiting_topics_come_up_for_sure_after_the_maximum_wait() -> void:
	_state.topic_waiting["topic.taxes"] = int(_defs.params.value("event_max_wait"))
	assert_eq(EventSystem.first_event_probability(_state, _defs, "topic.taxes"), 1.0)
	_state.topic_waiting["topic.taxes"] = 0
	assert_almost_eq(EventSystem.first_event_probability(_state, _defs, "topic.taxes"), 0.08, 0.00001)


func test_every_topic_is_addressed_eventually() -> void:
	for turn in range(1, 60):
		_state.turn = turn
		EventSystem.step(_state, _defs)
		if not _state.pending_event_id.is_empty():
			EventSystem.resolve(_state, _defs, 1)
	assert_eq(_state.party.positions.size(), _defs.topics.size())


func test_no_event_in_the_first_turn() -> void:
	_state.turn = 1
	for topic_id: String in _defs.topics:
		_state.topic_waiting[topic_id] = 100
	EventSystem.step(_state, _defs)
	assert_eq(_state.pending_event_id, "")


func test_first_stand_is_free_and_raises_salience() -> void:
	_state.turn = 2
	_state.topic_waiting["topic.welfare"] = 100
	EventSystem.step(_state, _defs)
	var event := EventSystem.pending(_state, _defs)
	assert_not_null(event)
	var credibility := _state.party.credibility
	EventSystem.resolve(_state, _defs, -1)
	assert_eq(_state.party.positions[event.topic], -1)
	assert_eq(_state.party.credibility, credibility)
	assert_gt(PollingSystem.salience(_state, _defs)[event.topic], 1.0)
	assert_eq(_state.pending_event_id, "")


func test_silence_costs_credibility_and_keeps_the_topic_closed() -> void:
	_state.pending_event_id = "event.wolf_attack"
	var credibility := _state.party.credibility
	EventSystem.resolve(_state, _defs, null)
	assert_false(_state.party.positions.has("topic.nature_conservation"))
	assert_almost_eq(_state.party.credibility, credibility - 3.0, 0.0001)
	assert_eq(_state.topic_waiting["topic.nature_conservation"], 0, "Waiting starts again")


func test_rethinking_a_position_costs_credibility_but_no_action_points() -> void:
	_state.party.positions["topic.nature_conservation"] = 2
	_state.party.position_age["topic.nature_conservation"] = 8
	_state.party.action_points = 4
	_state.pending_event_id = "event.wolf_attack"
	var credibility := _state.party.credibility
	EventSystem.resolve(_state, _defs, -2)
	assert_eq(_state.party.positions["topic.nature_conservation"], -2)
	assert_lt(_state.party.credibility, credibility)
	assert_eq(_state.party.action_points, 4)


func test_crisis_events_need_their_crisis() -> void:
	for event: EventDef in _defs.events.values():
		if not event.crisis.is_empty():
			assert_false(EventSystem._available(_state, _defs, event.topic).has(event), event.id)
	CrisisSystem.start(_state, _defs, "crisis.energy")
	assert_true(EventSystem._available(_state, _defs, "topic.housing_costs").has(_defs.events["event.heating_bills"]))


func test_unanswered_event_counts_as_silence_at_turn_end() -> void:
	TurnRunner.start_turn(_state, _defs)
	_state.pending_event_id = "event.wolf_attack"
	TurnRunner.finish_turn(_state, _defs, [] as Array[ActionOrder])
	assert_eq(_state.pending_event_id, "")
	assert_eq(SimLog.find(_state, "event_silence").size(), 1)
