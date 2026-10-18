extends GutTest
## Tests for checking and carrying out action orders (rechenmodell.md section 4).

var _defs: GameDefs
var _state: GameState


func before_each() -> void:
	_defs = SimFixture.defs()
	_state = SimFixture.new_state()
	_state.party.action_points = 4
	_state.party.activists = 100
	_state.party.money = 100.0


func test_shipped_actions_are_loaded() -> void:
	assert_true(_defs.actions.size() >= 18)


func test_rejects_invalid_orders() -> void:
	assert_eq(_check("action.unknown"), "unknown action")
	assert_eq(_check("action.found_local_branch", "region.east"), "region is not playable")
	assert_eq(_check("action.social_media_campaign", "region.south"), "action has no target")
	assert_eq(_check("action.campaign", "land.by"), "no election in this land")
	assert_eq(_check("action.set_position", "topic.taxes", {"value": 3}), "value out of range")
	assert_eq(_check("action.accept_large_donation", "donor.auto_supplier"), "donor is not satisfied enough")
	_state.party.action_points = 1
	assert_eq(_check("action.found_local_branch", "region.south"), "not enough action points")
	_state.party.action_points = 4
	_state.party.money = 4.0
	assert_eq(_check("action.found_local_branch", "region.south"), "not enough money")


func test_rejected_orders_are_logged_and_cost_nothing() -> void:
	ActionResolver.resolve(_state, _defs, [ActionOrder.create("action.found_local_branch", "region.east")])
	assert_eq(_state.party.action_points, 4)
	assert_eq(SimLog.find(_state, "order_rejected").size(), 1)


func test_responsible_function_carries_out_its_tasks() -> void:
	var south := _staff("state_chair_south", "none")
	var treasurer := _staff("treasurer", "none")
	var secretary := _staff("general_secretary", "none")
	assert_eq(ActionResolver.performer(_state, _defs, ActionOrder.create("action.found_local_branch", "region.south")), south)
	assert_eq(ActionResolver.performer(_state, _defs, ActionOrder.create("action.campaign", "land.by")), south, "Lands belong to their region")
	assert_eq(ActionResolver.performer(_state, _defs, ActionOrder.create("action.court_donor", "donor.real_estate")), treasurer)
	assert_eq(ActionResolver.performer(_state, _defs, ActionOrder.create("action.press_conference")), secretary)
	var chair := PersonSystem.by_role(_state, "chair")
	assert_eq(ActionResolver.performer(_state, _defs, ActionOrder.create("action.found_local_branch", "region.north")), chair, "Vacant function")
	assert_eq(ActionResolver.performer(_state, _defs, ActionOrder.create("action.set_position", "topic.taxes", {"value": 1})), chair, "Chair's own task")


func test_delegation_costs_nothing_extra_but_taking_over_does() -> void:
	_staff("state_chair_south", "none")
	var chair := PersonSystem.by_role(_state, "chair")
	var delegated := ActionOrder.create("action.found_local_branch", "region.south")
	assert_eq(ActionResolver.action_point_cost(_state, _defs, delegated), 2)
	var personal := ActionOrder.create("action.found_local_branch", "region.south", {"performer": chair.id})
	assert_eq(ActionResolver.action_point_cost(_state, _defs, personal), 2 + ActionResolver.PERSONAL_SURCHARGE)
	var vacant := ActionOrder.create("action.found_local_branch", "region.north", {"performer": chair.id})
	assert_eq(ActionResolver.action_point_cost(_state, _defs, vacant), 2, "No surcharge if nobody else is responsible")


func test_chair_actions_cannot_be_delegated_where_forbidden() -> void:
	var secretary := _staff("general_secretary", "none")
	assert_eq(
		_check("action.set_position", "topic.taxes", {"value": 1, "performer": secretary.id}),
		"action cannot be delegated"
	)


func test_success_chance_uses_competence() -> void:
	var order := ActionOrder.create("action.found_local_branch", "region.south")
	PersonSystem.by_role(_state, "chair").competence = 70.0
	assert_almost_eq(ActionResolver.success_chance(_state, _defs, order), 0.9, 0.00001)
	PersonSystem.by_role(_state, "chair").competence = 100.0
	assert_eq(ActionResolver.success_chance(_state, _defs, order), ActionResolver.CHANCE_MAX)


func test_set_position_is_certain() -> void:
	_resolve("action.set_position", "topic.taxes", {"value": 2})
	assert_eq(_state.party.positions["topic.taxes"], 2)
	assert_eq(_state.party.action_points, 3)


func test_regional_message() -> void:
	_resolve("action.regional_message", "region.north", {"topic": "topic.wind_power", "value": 2})
	assert_eq(_state.party.regional_messages["region.north"]["topic.wind_power"], 2)


func test_outrage_wave_raises_salience_and_radicalism() -> void:
	PersonSystem.by_role(_state, "chair").competence = 100.0
	var seed_found := false
	for game_seed in range(1, 20):
		_state.rng.seed = game_seed
		_state.modifiers.clear()
		_state.party.action_points = 4
		_resolve("action.outrage_wave", "topic.wind_power")
		if ModifierSystem.total_add(_state, "salience.topic.wind_power") > 0.0:
			seed_found = true
			break
	assert_true(seed_found, "The action succeeds at least once")
	assert_true(_state.party.radical_action_this_turn)


func test_appoint_and_dismiss() -> void:
	var candidate := PersonSystem.generate(_state)
	_state.persons.append(candidate)
	_resolve("action.appoint", candidate.id, {"role": "treasurer"})
	assert_eq(candidate.role, "treasurer")
	assert_eq(_check("action.appoint", candidate.id, {"role": "general_secretary"}), "person is not a candidate")
	_resolve("action.dismiss", candidate.id)
	assert_null(PersonSystem.by_id(_state, candidate.id))
	assert_almost_eq(_state.party.unity, 68.0, 0.0001)


func test_role_cannot_be_filled_twice() -> void:
	_staff("treasurer", "none")
	var candidate := PersonSystem.generate(_state)
	_state.persons.append(candidate)
	assert_eq(_check("action.appoint", candidate.id, {"role": "treasurer"}), "role already filled")


func test_large_donation() -> void:
	_state.donors["donor.auto_supplier"].satisfaction = 70.0
	_resolve("action.accept_large_donation", "donor.auto_supplier")
	assert_almost_eq(_state.party.money, 130.0, 0.0001)
	assert_almost_eq(_state.donors["donor.auto_supplier"].satisfaction, 55.0, 0.0001)


func test_purge_removes_disloyal_staff() -> void:
	var disloyal := _staff("treasurer", "none")
	disloyal.loyalty = 20.0
	var loyal := _staff("general_secretary", "none")
	loyal.loyalty = 80.0
	loyal.competence = 50.0
	_resolve("action.purge")
	assert_null(PersonSystem.by_id(_state, disloyal.id))
	assert_eq(loyal.competence, 45.0)
	assert_not_null(PersonSystem.by_role(_state, "chair"), "The chair is never purged")


func test_disloyal_informant_reports_hidden_funding() -> void:
	var informant := _staff("treasurer", "informant")
	informant.loyalty = 0.0
	_state.donors["donor.real_estate"].satisfaction = 80.0
	# The treasurer is responsible for funding: no explicit assignment needed.
	_resolve("action.third_party_funding", "donor.real_estate")
	# Report +5 and side effect +3
	assert_almost_eq(_state.party.scrutiny, 8.0, 0.0001)


func test_disloyal_journalist_documents() -> void:
	var journalist := _staff("treasurer", "journalist")
	journalist.loyalty = 0.0
	_resolve("action.win_influencer", "", {"performer": journalist.id})
	assert_eq(journalist.material, ActionResolver.JOURNALIST_DOCUMENTATION)


func _check(action_id: String, target: String = "", fields: Dictionary = {}) -> String:
	return ActionResolver.check(_state, _defs, ActionOrder.create(action_id, target, fields))


func _resolve(action_id: String, target: String = "", fields: Dictionary = {}) -> void:
	var order := ActionOrder.create(action_id, target, fields)
	assert_eq(ActionResolver.check(_state, _defs, order), "", "Order must be valid")
	ActionResolver.resolve(_state, _defs, [order])


func _staff(role: String, agenda: String) -> PersonState:
	var person := PersonSystem.generate(_state)
	person.role = role
	person.agenda = agenda
	_state.persons.append(person)
	return person
