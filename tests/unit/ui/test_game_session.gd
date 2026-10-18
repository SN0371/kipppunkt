extends GutTest
## Tests the session that connects the user interface with the simulation.

const SLOT := "test_session_slot"

var _session: GameSession


func before_each() -> void:
	_session = GameSession.new(SimFixture.defs())
	_session.new_game(5)


func after_all() -> void:
	var path := GameSession.SAVE_DIR.path_join(SLOT + ".json")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func test_new_game_waits_for_orders() -> void:
	assert_true(_session.has_game())
	assert_true(_session.state.awaiting_orders)
	assert_eq(_session.year(), 2041)
	assert_eq(_session.quarter(), 1)


func test_planning_uses_up_the_budget() -> void:
	var points: int = _session.remaining()["action_points"]
	assert_eq(_session.plan(ActionOrder.create("action.found_local_branch", "region.south")), "")
	assert_eq(_session.remaining()["action_points"], points - 2)
	assert_eq(_session.plan(ActionOrder.create("action.found_local_branch", "region.north")), "")
	assert_eq(_session.plan(ActionOrder.create("action.social_media_campaign")), "not enough action points")


func test_same_role_cannot_be_planned_twice() -> void:
	var candidates := _session.state.persons.filter(func(p: PersonState) -> bool: return p.role.is_empty())
	assert_eq(_session.plan(ActionOrder.create("action.appoint", candidates[0].id, {"role": "treasurer"})), "")
	assert_eq(_session.plan(ActionOrder.create("action.appoint", candidates[1].id, {"role": "treasurer"})), "already planned")


func test_unplan_returns_the_budget() -> void:
	_session.plan(ActionOrder.create("action.social_media_campaign"))
	_session.unplan(0)
	assert_eq(_session.planned.size(), 0)
	assert_eq(_session.remaining()["action_points"], _session.state.party.action_points)


func test_end_turn_resolves_and_starts_the_next_turn() -> void:
	_session.plan(ActionOrder.create("action.set_position", "topic.taxes", {"value": 1}))
	var report := _session.end_turn()
	assert_eq(_session.state.turn, 2)
	assert_true(_session.state.awaiting_orders)
	assert_eq(_session.planned.size(), 0)
	assert_true(report.any(func(e: Dictionary) -> bool: return e["kind"] == "position_set"))
	assert_eq(_session.year(), 2041)
	assert_eq(_session.quarter(), 2)


func test_save_and_load() -> void:
	_session.end_turn()
	assert_eq(_session.save(SLOT), OK)
	assert_true(GameSession.save_slots().has(SLOT))
	var other := GameSession.new(SimFixture.defs())
	assert_eq(other.load_game(SLOT), "")
	assert_eq(other.state.turn, 2)
	assert_true(other.state.awaiting_orders)


func test_loading_a_missing_slot_reports_an_error() -> void:
	assert_ne(_session.load_game("does_not_exist"), "")
	assert_true(_session.has_game(), "The running game stays")


func test_planning_a_position_replaces_the_earlier_plan() -> void:
	assert_eq(_session.plan_position("topic.taxes", 1), "")
	assert_eq(_session.plan_position("topic.taxes", 2), "")
	assert_eq(_session.planned.size(), 1)
	assert_eq(_session.intended_position("topic.taxes"), 2)
	assert_eq(_session.plan_position("topic.taxes", 0), "", "Back to no position removes the plan")
	assert_eq(_session.planned.size(), 0)
	assert_false(_session.is_position_planned("topic.taxes"))
